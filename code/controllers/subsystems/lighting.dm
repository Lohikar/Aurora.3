var/datum/controller/subsystem/lighting/SSlighting

/var/lighting_profiling = FALSE

/datum/controller/subsystem/lighting
	name = "Lighting"
	wait = LIGHTING_INTERVAL

	priority = SS_PRIORITY_LIGHTING
	init_order = SS_INIT_LIGHTING

	var/list/light_queue   = list() // lighting sources  queued for update.
	var/list/corner_queue  = list() // lighting corners  queued for update.
	var/list/overlay_queue = list() // lighting overlays queued for update.

	var/tmp/processed_lights = 0
	var/tmp/processed_corners = 0
	var/tmp/processed_overlays = 0

	var/force_queued = TRUE
	var/force_override = FALSE	// For admins.
	var/round_started = FALSE

/datum/controller/subsystem/lighting/New()
	NEW_SS_GLOBAL(SSlighting)

/datum/controller/subsystem/lighting/stat_entry()
	..("O:[all_lighting_overlays.len] C:[all_lighting_corners.len]\n\tP:{L:[light_queue.len]|C:[corner_queue.len]|O:[overlay_queue.len]}\n\tL:{L:[processed_lights]|C:[processed_corners]|O:[processed_overlays]}")

/datum/controller/subsystem/lighting/proc/explosion_start()
	force_queued = TRUE

/datum/controller/subsystem/lighting/proc/explosion_end()
	if (!force_override)
		force_queued = FALSE

/datum/controller/subsystem/lighting/Initialize(timeofday)
	var/overlaycount = 0
	// Generate overlays.
	for (var/zlevel = 1 to world.maxz)
		for (var/turf/T in block(locate(1, 1, zlevel), locate(world.maxx, world.maxy, zlevel)))
			if (!T.dynamic_lighting)
				continue

			var/area/A = T.loc
			if (!A.dynamic_lighting)
				continue

			new /atom/movable/lighting_overlay(T, TRUE)
			overlaycount++

			CHECK_TICK

	admin_notice(span("danger", "Created [overlaycount] lighting overlays."), R_DEBUG)

	// Tick once to clear most lights.
	fire(FALSE, TRUE)

	admin_notice(span("danger", "Processed [processed_lights] light sources."), R_DEBUG)
	admin_notice(span("danger", "Processed [processed_corners] light corners."), R_DEBUG)
	admin_notice(span("danger", "Processed [processed_overlays] light overlays."), R_DEBUG)

	log_ss("SSlighting: NOv:[overlaycount] L:[processed_lights] C:[processed_corners] O:[processed_overlays]")

	..()

/datum/controller/subsystem/lighting/fire(resumed = FALSE, no_mc_tick = FALSE)
	if (!resumed && !round_started && Master.round_started)
		force_queued = FALSE
		round_started = TRUE

	if (!resumed)
		processed_lights = 0
		processed_corners = 0
		processed_overlays = 0

	var/list/curr_lights = light_queue
	var/list/curr_corners = corner_queue
	var/list/curr_overlays = overlay_queue

	while (curr_lights.len)
		var/datum/light_source/L = curr_lights[curr_lights.len]
		curr_lights.len--

		if(L.destroyed || L.check() || L.force_update)
			L.remove_lum()
			if(!L.destroyed)
				L.apply_lum()

		else if(L.vis_update)	//We smartly update only tiles that became (in) visible to use.
			L.smart_vis_update()

		L.vis_update   = FALSE
		L.force_update = FALSE
		L.needs_update = FALSE

		processed_lights++

		if (no_mc_tick)
			CHECK_TICK
		else if (MC_TICK_CHECK)
			return

	while (curr_corners.len)
		var/datum/lighting_corner/C = curr_corners[curr_corners.len]
		curr_corners.len--

		C.update_overlays()

		C.needs_update = FALSE

		processed_corners++

		if (no_mc_tick)
			CHECK_TICK
		else if (MC_TICK_CHECK)
			return

	while (curr_overlays.len)
		var/atom/movable/lighting_overlay/O = curr_overlays[curr_overlays.len]
		curr_overlays.len--

		O.update_overlay()
		O.needs_update = FALSE

		processed_overlays++
		
		if (no_mc_tick)
			CHECK_TICK
		else if (MC_TICK_CHECK)
			return

/datum/controller/subsystem/lighting/Recover()
	src.light_queue = SSlighting.light_queue
	src.corner_queue = SSlighting.corner_queue
	src.overlay_queue = SSlighting.overlay_queue
