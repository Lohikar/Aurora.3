/datum/light_source/sublight
	var/datum/light_source/parent
	var/list/target_turfs
	var/targets_changed = FALSE
	var/raw_color

/datum/light_source/sublight/New(datum/light_source/parent, list/target_turfs, color_override)
	src.parent = parent
	src.target_turfs = target_turfs
	..(parent.source_atom, parent.top_atom)
	light_color = color_override
	parse_light_color()

/datum/light_source/sublight/proc/set_color(color, defer_update)
	light_color = color
	parse_light_color()
	if (!defer_update)
		update()

/datum/light_source/sublight/proc/update_targets(list/newtargets, defer_update)
	target_turfs = newtargets
	targets_changed = TRUE
	if (!defer_update)
		update()

/datum/light_source/sublight/update_corners(now = FALSE)
	var/update = FALSE

	if (QDELETED(source_atom))
		qdel(src)
		return

	if (source_atom.light_power != light_power)
		light_power = source_atom.light_power
		update = TRUE

	if (source_atom.light_range != light_range)
		light_range = source_atom.light_range
		update = TRUE

	if (!top_atom)
		top_atom = source_atom
		update = TRUE

	if (top_atom.loc != source_turf)
		source_turf = top_atom.loc
		update = TRUE

	if (!light_range || !light_power)
		qdel(src)
		return

	if (isturf(top_atom))
		if (source_turf != top_atom)
			source_turf = top_atom
			update = TRUE
	else if (top_atom.loc != source_turf)
		source_turf = top_atom.loc
		update = TRUE

	if (!source_turf)
		return	// Somehow we've got a light in nullspace, no-op.

	if (light_range && light_power && !applied)
		update = TRUE

	if (source_atom.light_color != light_color)
		light_color = source_atom.light_color
		parse_light_color()
		update = TRUE

	else if (applied_lum_r != lum_r || applied_lum_g != lum_g || applied_lum_b != lum_b)
		update = TRUE

	if (source_atom.light_wedge != light_angle)
		light_angle = source_atom.light_wedge
		update = TRUE

	if (light_angle)
		var/ndir
		if (istype(top_atom, /mob) && top_atom:facing_dir)
			ndir = top_atom:facing_dir
		else
			ndir = top_atom.dir

		if (old_direction != ndir)	// If our direction has changed, we need to regenerate all the angle info.
			regenerate_angle(ndir)
			update = TRUE
		else // Check if it was just a x/y translation, and update our vars without an regenerate_angle() call if it is.
			var/co_updated = FALSE
			if (source_turf.x != cached_origin_x)
				test_x_offset += source_turf.x - cached_origin_x
				cached_origin_x = source_turf.x

				co_updated = TRUE

			if (source_turf.y != cached_origin_y)
				test_y_offset += source_turf.y - cached_origin_y
				cached_origin_y = source_turf.y

				co_updated = TRUE

			if (co_updated)
				// We might be facing a wall now.
				var/turf/front = get_step(source_turf, old_direction)
				facing_opaque = (front && front.has_opaque_atom)

				update = TRUE

		if (targets_changed)
			update = TRUE
			targets_changed = FALSE

	if (update)
		needs_update = LIGHTING_CHECK_UPDATE
	else if (needs_update == LIGHTING_CHECK_UPDATE)
		return	// No change.

	var/list/datum/lighting_corner/corners = list()
	var/list/turf/turfs                    = list()
	var/thing
	var/datum/lighting_corner/C
	var/turf/T
	var/list/Tcorners
	var/Sx = source_turf.x
	var/Sy = source_turf.y
	var/Sz = source_turf.z
	var/corner_height = LIGHTING_HEIGHT
	var/actual_range = (light_angle && facing_opaque) ? light_range * LIGHTING_BLOCKED_FACTOR : light_range
	var/test_x
	var/test_y

	var/zlights_going_up = FALSE
	var/turf/originalT	// This is needed to reset our search point for bidirectional Z-lights.

	for (thing in target_turfs)
		T = originalT = thing
		zlights_going_up = FALSE
		check_t:

		if (T.dynamic_lighting || T.light_sources)
			Tcorners = T.corners
			if (!T.lighting_corners_initialised)
				T.lighting_corners_initialised = TRUE

				if (!Tcorners)
					T.corners = list(null, null, null, null)
					Tcorners = T.corners

				for (var/i = 1 to 4)
					if (Tcorners[i])
						continue

					Tcorners[i] = new /datum/lighting_corner(T, LIGHTING_CORNER_DIAGONAL[i])

			if (!T.has_opaque_atom)
				corners[Tcorners[1]] = 0
				corners[Tcorners[2]] = 0
				corners[Tcorners[3]] = 0
				corners[Tcorners[4]] = 0

		if (T.has_tinted_object)
			var/tdir = get_dir(source_turf, T)
			var/color = T.tinted_objects[tdir]
			if (color)
				// Exclude all turfs in this direction since we don't want to affect them more than once.
				LAZYINITLIST(exclude_turfs)
				subturfs = wedge_filter_turflist(T, turfs, 90)
				exclude_turfs += subturfs
				if (T.lighting_sublights && T.lighting_sublights[src])
					sublight = T.lighting_sublights[src]
					if (sublight.raw_color != light_color)
						sublight.set_color(multiply_color(light_color, color), TRUE)
					sublight.update_targets(subturfs)
				else
					sublights += T.create_sublight(src, subturfs, multiply_color(light_color, color))
			else
				turfs += T
		else
			turfs += T
			if (T.lighting_sublights && T.lighting_sublights[src])
				sublight = T.lighting_sublights[src]
				qdel(sublight)	// Destroy should clean up the turf var.
				sublights -= sublight

		// Note: above is defined on ALL turfs, but below is only defined on OPEN TURFS.

		zlight_check:
		if (zlights_going_up)	// If we're searching upwards, check above.
			if (istype(T.above))	// We escape the goto loop if this condition is false.
				T = T.above
				goto check_t
		else
			if (isopenturf(T) && T:below)	// Not searching upwards and we have a below turf.
				T = T:below	// Consider the turf below us as well. (Z-lights)
				goto check_t
			else // Not searching upwards and we don't have a below turf.
				zlights_going_up = TRUE
				T = originalT
				goto zlight_check

	LAZYINITLIST(affecting_turfs)

	var/list/L = turfs - affecting_turfs // New turfs, add us to the affecting lights of them.
	affecting_turfs += L
	for (thing in L)
		T = thing
		LAZYADD(T.affecting_lights, src)

	L = affecting_turfs - turfs // Now-gone turfs, remove us from the affecting lights.
	affecting_turfs -= L
	for (thing in L)
		T = thing
		LAZYREMOVE(T.affecting_lights, src)

	LAZYINITLIST(effect_str)
	if (needs_update == LIGHTING_VIS_UPDATE)
		for (thing in corners - effect_str)
			C = thing
			LAZYADD(C.affecting, src)
			if (!C.active)
				effect_str[C] = 0
				continue

			APPLY_CORNER_BY_HEIGHT(now)
	else
		L = corners - effect_str
		for (thing in L)
			C = thing
			LAZYADD(C.affecting, src)
			if (!C.active)
				effect_str[C] = 0
				continue

			APPLY_CORNER_BY_HEIGHT(now)

		for (thing in corners - L)
			C = thing
			if (!C.active)
				effect_str[C] = 0
				continue

			APPLY_CORNER_BY_HEIGHT(now)

	L = effect_str - corners
	for (thing in L)
		C = thing
		REMOVE_CORNER(C, now)
		LAZYREMOVE(C.affecting, src)

	effect_str -= L

	applied_lum_r = lum_r
	applied_lum_g = lum_g
	applied_lum_b = lum_b
	applied_lum_u = lum_u

	UNSETEMPTY(effect_str)
	UNSETEMPTY(affecting_turfs)

/datum/light_source/sublight/Destroy(force)
	LAZYREMOVE(source_turf.lighting_sublights, parent)
	return ..()
