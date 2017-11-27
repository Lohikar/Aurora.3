/obj/machinery/bluespace_beacon
	icon = 'icons/obj/objects.dmi'
	icon_state = "floor_beaconf"
	name = "Bluespace Gigabeacon"
	desc = "A device that draws power from bluespace and creates a permanent tracking beacon."
	level = 1		// underfloor
	layer = 2.5
	anchored = 1
	use_power = 1
	idle_power_usage = 0
	var/obj/item/device/radio/beacon/Beacon

/obj/machinery/bluespace_beacon/Initialize()
	. = ..()
	Beacon = new /obj/item/device/radio/beacon(loc)
	Beacon.invisibility = INVISIBILITY_MAXIMUM

	var/turf/T = loc
	hide(!T.is_plating())

/obj/machinery/bluespace_beacon/Destroy()
	if(Beacon)
		QDEL_NULL(Beacon)
	return ..()

// update the invisibility and icon
/obj/machinery/bluespace_beacon/hide(var/intact)
	invisibility = intact ? 101 : 0
	update_icon()

// update the icon_state
/obj/machinery/bluespace_beacon/update_icon()
	if(invisibility)
		icon_state = "floor_beaconf"
	else
		icon_state = "floor_beacon"

/obj/machinery/bluespace_beacon/process()
	if(!Beacon)
		Beacon = new /obj/item/device/radio/beacon(loc)
		Beacon.invisibility = INVISIBILITY_MAXIMUM
	if(Beacon)
		if(Beacon.loc != loc)
			Beacon.loc = loc

	update_icon()
