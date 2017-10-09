// This file controls round-start runtime maploading.

#define X_OFFSET "xoffset"
#define Y_OFFSET "yoffset"
#define Z_OFFSET "zoffset"

// First, some globals.
var/datum/map/current_map	// Whatever map is currently loaded. Null until SSmap Initialize() starts.
var/map_override	// If set, SSmap will forcibly load this map. If the map does not exist, mapload will fail and SSmap will panic.

var/datum/controller/subsystem/map/SSmap

/datum/controller/subsystem/map
	name = "Map Management"
	flags = SS_NO_FIRE
	init_order = SS_INIT_MAPLOAD

	var/list/known_maps = list()
	var/dmm_suite/maploader
	var/list/height_markers = list()

	var/list/mapload_callbacks = list()

	var/world_loaded = FALSE
	var/datum/map_job/current_job

/datum/controller/subsystem/map/New()
	NEW_SS_GLOBAL(SSmap)

/datum/controller/subsystem/map/Initialize(timeofday)
	maploader = new

	var/datum/map/M
	for (var/type in subtypesof(/datum/map))
		M = new type
		if (!M.path)
			log_debug("SSmap: Map [M.name] ([M.type]) has no path set, discarding.")
			qdel(M)
			continue

		known_maps[M.path] = M

#ifdef DEFAULT_MAP
	map_override = DEFAULT_MAP
	log_ss("map", "Using compile-selected map.")
#endif
	if (!map_override)
		map_override = get_selected_map()

	admin_notice("<span class='danger'>Loading map [map_override].</span>", R_DEBUG)
	log_ss("map", "Using map '[map_override]'.")


	current_map = known_maps[map_override]
	if (!current_map)
		world.map_panic("Selected map does not exist!")

	load_map_meta()

	world.update_status()

	// Begin loading the maps.
	var/maps_loaded = load_map_directory("maps/[current_map.path]/")

	if (!maps_loaded)
		world.map_panic("No maps loaded!")

	world_loaded = TRUE

	..()

/datum/controller/subsystem/map/proc/load_map_directory(directory)
	. = 0
	if (!directory)
		CRASH("No directory supplied.")

	var/static/regex/mapregex = new(".+\\.dmm$")
	var/list/files = flist(directory)
	var/list/job_files = list()
	sortTim(files, /proc/cmp_text_asc)
	for (var/mfile in files)
		if (!mapregex.Find(mfile))
			continue

		job_files += "[directory][mfile]"

	var/datum/map_job/job = new
	job.maps_assoc = job_files
	job.no_changeturf = TRUE

	return run_job(job, unsafe = TRUE)

/datum/controller/subsystem/map/proc/setup_multiz()
	for (var/thing in height_markers)
		var/obj/effect/landmark/map_data/marker = thing
		marker.setup()

	log_debug("mapmanager: found [height_markers.len] Z-markers.")

/datum/controller/subsystem/map/proc/get_selected_map()
	if (config.override_map)
		if (known_maps[config.override_map])
			. = config.override_map
			log_ss("map", "Using configured map.")
		else
			log_ss("map", "-- WARNING: CONFIGURED MAP DOES NOT EXIST, IGNORING! --")
			. = "aurora"
	else
		. = "aurora"

/datum/controller/subsystem/map/proc/load_map_meta()
	// This needs to be done after current_map is set, but before mapload.
	lobby_image = new /obj/effect/lobby_image

	admin_departments = list(
		"[current_map.boss_name]",
		"[current_map.system_name] Government", 
		"Supply"
	)

	priority_announcement = new(do_log = 0)
	command_announcement = new(do_log = 0, do_newscast = 1)

	for (var/thing in mapload_callbacks)
		var/datum/callback/cb = thing
		cb.InvokeAsync()
		CHECK_TICK

	mapload_callbacks.Cut()
	mapload_callbacks = null

/datum/controller/subsystem/map/proc/OnMapload(datum/callback/callback)
	if (!istype(callback))
		CRASH("Invalid callback.")
	
	mapload_callbacks += callback

/datum/controller/subsystem/map/proc/run_job(datum/map_job/job, unsafe = FALSE)
	if (current_job)
		log_debug("Attempt to start new mapload before previous finished, ignoring.")
		return FALSE

	if (!unsafe && !world_loaded)
		log_debug("Attempt to load map before SSmap run, ignoring.")
		return FALSE

	current_job = job
	maploader = new

	admin_notice("<span class='danger'>[name]: Starting load of map job initiated by [job.owning_ckey || "server"].")

	. = 0

	for (var/entry in current_job.maps_assoc)
		var/list/attr = current_job.maps_assoc[entry]
		if (istext(entry))
			entry = file(entry)

		log_ss("map", "run_job: begin load '[entry]'.")

		var/res
		if (attr)
			res = maploader.load_map(entry, attr[X_OFFSET] || 0, attr[Y_OFFSET] || 0, attr[Z_OFFSET] || 0, !current_job.no_changeturf, FALSE, current_job.no_changeturf)
		else
			res = maploader.load_map(entry, 0, 0, 0, !current_job.no_changeturf, FALSE, current_job.no_changeturf)

		if (!res)
			log_ss("map", "run_job: failure during load of '[]'.")
			admin_notice("<span class='danger'>[name]: Failure during load of map '[entry]'!</span>", R_DEBUG)
		else
			.++

		CHECK_TICK

	setup_multiz()

	log_ss("map", "Loaded [.] maps.")
	admin_notice("<span class='danger'>[name]: Loaded [.] maps.</span>", R_DEBUG)

	current_job = null
	QDEL_NULL(maploader)

	return TRUE

/datum/controller/subsystem/map/stat_entry()
	var/result
	if (!current_job)
		result = "Idle."
	else
		result = "Loading [current_job.maps_assoc.len] maps, started by [current_job.owning_ckey || "server"]."

	..(result + "\nX:[world.maxx] Y:[world.maxx] Z:[world.maxz]")

/datum/controller/subsystem/map/proc/can_load_map()
	return !current_job && world_loaded

// Called when there's a fatal, unrecoverable error in mapload. This reboots the server.
/world/proc/map_panic(reason)
	to_chat(world, "<span class='danger'>Fatal error during map setup, unable to continue! Server will reboot in 60 seconds.</span>")
	log_ss("map", "-- FATAL ERROR DURING MAP SETUP: [uppertext(reason)] --")
	sleep(1 MINUTE)
	world.Reboot()

/*
	maps_assoc:
		key: map path or file
		value: null|list("x_offset" = num, "y_offset" = num, "z_offset" = num)
*/
/datum/map_job
	var/list/maps_assoc
	var/owning_ckey
	var/name
	var/no_changeturf = FALSE

/proc/station_name()
	ASSERT(current_map)
	. = current_map.station_name

	var/sname
	if (config && config.server_name)
		sname = "[config.server_name]: [.]"
	else
		sname = .

	if (world.name != sname)
		world.name = sname
		world.log << "Set world.name to [sname]."

/proc/system_name()
	ASSERT(current_map)
	return current_map.system_name

/proc/commstation_name()
	ASSERT(current_map)
	return current_map.dock_name


/datum/admins/proc/load_map()
	set name = "Load Map (DANGER)"
	set category = "Server"
	set desc = "Loads a DMM file into the game world. Be VERY careful when entering offsets, this command cannot be undone!"

	if (!check_rights(R_SERVER)) return
	if (!SSmap.can_load_map())
		usr << "Another map is already loading, or the world hasn't finished loading yet. Try again in a few minutes."
		return

	var/dmm_file = input("Please select a DMM file.") as null|file
	if (!dmm_file)
		usr << "Aborted."
		return

	var/datum/map_job/job = new
	job.owning_ckey = usr.ckey
	job.maps_assoc = list(dmm_file)

	var/list/offsets = list("X Offset (none)", "Y Offset (none)", "Z Offset (none)", "-- Done --")
	var/list/offset_label = list("X Offset", "Y Offset", "Z Offset")
	var/list/offset_configured = list(X_OFFSET, Y_OFFSET, Z_OFFSET)

	var/answer
	do
		answer = input("Do you want to change any offsets?") as null|anything in offsets

		if (!answer)
			qdel(job)
			usr << "Aborted."
			return

		if (answer == "-- Done --")
			break

		var/lloc = offsets.Find(answer)
		if (!lloc)
			// wat
			usr << "Unknown error, aborting."
			qdel(job)
			return

		var/offset = input("Offset? (0 for none)") as null|num
		if (!offset)
			continue

		if (offset < 0)
			alert("Invalid number, must be positive or 0.")
			continue

		offset_configured[offset_configured[lloc]] = offset
		offsets[lloc] = "[offset_label[lloc]] ([offset])"

	while (answer && answer != "-- Done --")

	log_debug(json_encode(offset_configured))
	var/apply = FALSE
	for (var/item in offset_configured)
		if (offset_configured[item])
			apply = TRUE
			break

	if (apply)
		job.maps_assoc[dmm_file] = offset_configured

	if (!SSmap.can_load_map())
		alert("Looks like someone beat you to it.", "Load Map")
		return

	SSmap.run_job(job)

	log_admin("[key_name(usr)] has started loading map '[dmm_file]'.")
	message_admins("<span class='danger'>[key_name_admin(usr)] has started loading map '[dmm_file]'!</span>")

#undef X_OFFSET
#undef Y_OFFSET
#undef Z_OFFSET
