/proc/cmp_numeric_dsc(a,b)
	return b - a

/proc/cmp_numeric_asc(a,b)
	return a - b

/proc/cmp_text_asc(a,b)
	return sorttext(b,a)

/proc/cmp_text_dsc(a,b)
	return sorttext(a,b)

/proc/cmp_name_asc(atom/a, atom/b)
	return sorttext(b.name, a.name)

/proc/cmp_name_dsc(atom/a, atom/b)
	return sorttext(a.name, b.name)

var/cmp_field = "name"
/proc/cmp_records_asc(datum/data/record/a, datum/data/record/b)
	return sorttext(b.fields[cmp_field], a.fields[cmp_field])

/proc/cmp_records_dsc(datum/data/record/a, datum/data/record/b)
	return sorttext(a.fields[cmp_field], b.fields[cmp_field])

/proc/cmp_ckey_asc(client/a, client/b)
	return sorttext(b.ckey, a.ckey)

/proc/cmp_ckey_dsc(client/a, client/b)
	return sorttext(a.ckey, b.ckey)

/proc/cmp_subsystem_init(datum/controller/subsystem/a, datum/controller/subsystem/b)
	return b.init_order - a.init_order

/proc/cmp_subsystem_display(datum/controller/subsystem/a, datum/controller/subsystem/b)
	return sorttext(b.name, a.name)

/proc/cmp_subsystem_priority(datum/controller/subsystem/a, datum/controller/subsystem/b)
	return a.priority - b.priority

/proc/cmp_timer(datum/timedevent/a, datum/timedevent/b)
	return a.timeToRun - b.timeToRun

/proc/cmp_camera(obj/machinery/camera/a, obj/machinery/camera/b)
	if (a.c_tag_order != b.c_tag_order)
		return b.c_tag_order - a.c_tag_order
	return sorttext(b.c_tag, a.c_tag)

/proc/cmp_alarm(datum/alarm/a, datum/alarm/b)
	return sorttext(b.last_name, a.last_name)

/proc/cmp_uplink_item(datum/uplink_item/a, datum/uplink_item/b)
	return b.cost(INFINITY) - a.cost(INFINITY)

/proc/cmp_access(datum/access/a, datum/access/b)
	return sorttext("[b.access_type][b.desc]", "[a.access_type][a.desc]")

/proc/cmp_player_setup_group(datum/category_group/player_setup_category/a, datum/category_group/player_setup_category/b)
	return b.sort_order - a.sort_order

/proc/cmp_cardstate(datum/card_state/a, datum/card_state/b)
	return sorttext(b.name, a.name)

/proc/cmp_uplink_category(datum/uplink_category/a, datum/uplink_category/b)
	return sorttext(b.name, a.name)

/proc/cmp_admin_secret(datum/admin_secret_item/a, datum/admin_secret_item/b)
	return sorttext(b.name, a.name)

/proc/cmp_supply_drop(datum/supply_drop_loot/a, datum/supply_drop_loot/b)
	return sorttext(b.name, a.name)
