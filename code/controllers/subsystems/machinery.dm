var/global/list/ticking_machines		= list()
var/global/list/power_using_machines	= list()

/datum/subsystem/machinery
	name = "Machinery"
	wait = 2 SECONDS
	priority = SS_PRIORITY_MACHINERY
	flags = SS_NO_INIT
	display_order = SS_DISPLAY_MACHINERY

	var/tmp/list/processing_machinery = list()
	var/tmp/list/processing_power_users = list()
	var/tmp/list/processing_powersinks = list()
	var/tmp/list/processing_powernets = list()

/datum/subsystem/machinery/fire(resumed = 0)
	if (!resumed)
		src.processing_machinery = machines.Copy()
		src.processing_power_users = power_using_machines.Copy()
		src.processing_powersinks = processing_power_items.Copy()
		src.processing_powernets = powernets.Copy()

	var/list/curr_machinery = src.processing_machinery
	var/list/curr_power_users = src.processing_power_users
	var/list/curr_powersinks = src.processing_powersinks
	var/list/curr_powernets = src.processing_powernets

	while (curr_machinery.len)
		var/obj/machinery/M = curr_machinery[curr_machinery.len]
		curr_machinery.len--

		if (QDELETED(M))
			remove_machine(M)
			continue

		switch (M.process())
			if (PROCESS_KILL)
				remove_machine(M)

			if (M_NO_PROCESS)
				ticking_machines -= M

		if (MC_TICK_CHECK)
			return

	while (curr_power_users.len)
		var/obj/machinery/M = curr_power_users[curr_power_users.len]
		curr_power_users.len--

		if (QDELETED(M))
			remove_machine(M)
			continue

		if (M.use_power)
			M.auto_use_power()

		if (MC_TICK_CHECK)
			return

	while (curr_powernets.len)
		var/datum/powernet/PN = curr_powernets[curr_powernets.len]
		curr_powernets.len--

		PN.reset()

	while (curr_powersinks.len)
		var/obj/item/I = curr_powersinks[curr_powersinks.len]
		curr_powersinks.len--

		if (QDELETED(I) || !I.pwr_drain())
			processing_power_items -= I
		
		if (MC_TICK_CHECK)
			return

/datum/subsystem/machinery/stat_entry()
	..()
	stat(null, "[machines.len] total machines")
	stat(null, "[ticking_machines.len] ticking machines, [processing_machinery.len] queued")
