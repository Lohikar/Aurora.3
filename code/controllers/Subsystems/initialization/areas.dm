/datum/subsystem/areas
	name = "Areas"
	init_order = SS_INIT_AREA
	flags = SS_NO_FIRE

/datum/subsystem/areas/Initialize(timeofday)
	for (var/A in all_areas)
		var/area/area = A
		area.initialize()
	..()