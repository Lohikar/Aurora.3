// the light switch
// can have multiple per area
// can also operate on non-loc area through "otherarea" var
/obj/machinery/light_switch
	name = "light switch"
	desc = "It turns lights on and off. What are you, simple?"
	icon = 'icons/obj/power.dmi'
	icon_state = "light1"
	anchored = 1.0
	var/on = 1
	var/area/area = null
	var/otherarea = null
	//	luminosity = 1

/obj/machinery/light_switch/Initialize()
	. = ..()
	src.area = get_area(src)

	if(otherarea)
		src.area = locate(text2path("/area/[otherarea]"))

	if(!name)
		name = "light switch ([area.name])"

	src.on = src.area.lightswitch
	update_icon()

/obj/machinery/light_switch/update_icon()
	if(stat & NOPOWER)
		icon_state = "light-p"
	else
		icon_state = "light[on]"

/obj/machinery/light_switch/examine(mob/user)
	if(..(user, 1))
		user << "A light switch. It is [on? "on" : "off"]."

/obj/machinery/light_switch/attack_hand(mob/user)

	on = !on

	area.lightswitch = on
	area.update_icon()

	for(var/obj/machinery/light_switch/L in area)
		L.on = on
		L.update_icon()

	area.power_change()

/obj/machinery/light_switch/power_change()

	if(!otherarea)
		if(powered(LIGHT))
			stat &= ~NOPOWER
		else
			stat |= NOPOWER

		update_icon()

/obj/machinery/light_switch/emp_act(severity)
	if(stat & (BROKEN|NOPOWER))
		..(severity)
		return
	power_change()
	..(severity)
