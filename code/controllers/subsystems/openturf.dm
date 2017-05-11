#define OPENTURF_MAX_PLANE -71
#define OPENTURF_CAP_PLANE -70      // The multiplier goes here so it'll be on top of every other overlay.
#define OPENTURF_MAX_DEPTH 10		// The maxiumum number of planes deep we'll go before we just dump everything on the same plane.

/var/datum/controller/subsystem/openturf/SSopenturf

/datum/controller/subsystem/openturf
	name = "Open Space"
	flags = SS_BACKGROUND | SS_FIRE_IN_LOBBY
	wait = 1
	init_order = SS_INIT_OPENTURF
	priority = SS_PRIORITY_OPENTURF

	var/list/queued_turfs = list()
	var/list/queued_overlays = list()

	var/list/openspace_overlays = list()
	var/list/openspace_turfs = list()

/datum/controller/subsystem/openturf/New()
	NEW_SS_GLOBAL(SSopenturf)

/datum/controller/subsystem/openturf/proc/update_all()
	disable()
	for (var/thing in openspace_overlays)
		var/atom/movable/AM = thing

		var/turf/simulated/open/T = get_turf(AM)
		if (istype(T))
			T.update()
		else
			qdel(AM)

		CHECK_TICK

	enable()

/datum/controller/subsystem/openturf/proc/hard_reset()
	disable()
	log_debug("SSopenturf: hard_reset() invoked.")
	var/num_deleted = 0
	for (var/thing in openspace_overlays)
		qdel(thing)
		num_deleted++
		CHECK_TICK
	
	log_debug("SSopenturf: deleted [num_deleted] overlays.")

	var/num_turfs = 0
	for (var/turf/simulated/open/T in turfs)
		T.update_icon()
		num_turfs++

		CHECK_TICK

	log_debug("SSopenturf: queued [num_turfs] openturfs for update. hard_reset() complete.")
	enable()

/datum/controller/subsystem/openturf/stat_entry()
	..("Q:{T:[queued_turfs.len]|O:[queued_overlays.len]} T:{T:[openspace_turfs.len]|O:[openspace_overlays.len]}")

/datum/controller/subsystem/openturf/Initialize(timeofday)
	// Flush the queue.
	fire(FALSE, TRUE)
	..()

/datum/controller/subsystem/openturf/fire(resumed = FALSE, no_mc_tick = FALSE)
	MC_SPLIT_TICK_INIT(2)
	if (!no_mc_tick)
		MC_SPLIT_TICK

	var/list/curr_turfs = queued_turfs
	var/list/curr_ov = queued_overlays

	while (curr_turfs.len)
		var/turf/simulated/open/T = curr_turfs[1]
		curr_turfs.Cut(1,2)

		if (!istype(T) || !T.below)
			if (no_mc_tick)
				CHECK_TICK
			else if (MC_TICK_CHECK)
				break
			continue

		if (!T.shadower)	// If we don't have our shadower yet, create it.
			T.shadower = new(T)

		// Figure out how many z-levels down we are.
		var/depth = calculate_depth(T)
		if (depth > OPENTURF_MAX_DEPTH)
			depth = OPENTURF_MAX_DEPTH

		// Update the openturf itself.
		T.appearance = T.below

		// Handle space parallax & starlight.
		if (T.is_above_space())
			T.plane = PLANE_SPACE_BACKGROUND
			if (config.starlight)
				for (var/thing in RANGE_TURFS(1, T))
					var/turf/RT = thing
					if (!RT.dynamic_lighting || istype(RT, /turf/simulated/open))
						continue

					T.set_light(config.starlight, 0.5)
					break
		else
			T.plane = OPENTURF_MAX_PLANE - depth
			if (config.starlight && T.light_range != 0)
				T.set_light(0)

		// Add everything below us to the update queue.
		for (var/thing in T.below)
			var/atom/movable/object = thing
			if (QDELETED(object) || object.no_z_overlay)
				// Don't queue deleted stuff or stuff that doesn't need an overlay.
				if (no_mc_tick)
					CHECK_TICK
				else if (MC_TICK_CHECK)
					break
				continue

			// Cache our already-calculated depth so we don't need to re-calculate it a bunch of times.

			if (!object.bound_overlay)	// Generate a new overlay if the atom doesn't already have one.
				object.bound_overlay = new(T)
				object.bound_overlay.associated_atom = object

			var/atom/movable/openspace/overlay/OO = object.bound_overlay

			OO.depth = depth

			queued_overlays += OO

		T.updating = FALSE

		if (no_mc_tick)
			CHECK_TICK
		else if (MC_TICK_CHECK)
			break

	if (!no_mc_tick)
		MC_SPLIT_TICK

	while (curr_ov.len)
		var/atom/movable/openspace/overlay/OO = curr_ov[1]
		curr_ov.Cut(1, 2)

		if (QDELETED(OO))
			if (no_mc_tick)
				CHECK_TICK
			else if (MC_TICK_CHECK)
				break
			continue

		if (QDELETED(OO.associated_atom))	// This shouldn't happen, but just in-case.
			qdel(OO)

			if (no_mc_tick)
				CHECK_TICK
			else if (MC_TICK_CHECK)
				break
			continue

		// Actually update the overlay.
		OO.dir = OO.associated_atom.dir
		OO.appearance = OO.associated_atom
		OO.plane = OPENTURF_MAX_PLANE - OO.depth

		// Something's above us, queue it.
		var/turf/oo_loc = OO.loc
		if (istype(oo_loc.above))
			oo_loc.above.update_icon()

		if (no_mc_tick)
			CHECK_TICK
		else if (MC_TICK_CHECK)
			break

/datum/controller/subsystem/openturf/proc/calculate_depth(turf/simulated/open/T)
	. = 0
	while (T && istype(T.below, /turf/simulated/open))
		T = T.below
		.++