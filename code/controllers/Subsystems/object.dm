var/datum/subsystem/object/SSobj

/datum/subsystem/object
	name = "Objects"
	wait = 2 SECONDS
	priority = SS_PRIORITY_OBJECTS
	init_order = SS_INIT_OBJECTS

	var/tmp/list/queue = list()

/datum/subsystem/object/New()
	if (!processing_objects)
		processing_objects = list()

	NEW_SS_GLOBAL(SSobj)

/datum/subsystem/object/fire(resumed = FALSE)
	if (!resumed)
		queue = processing_objects.Copy()

	while (queue.len)
		var/datum/O = queue[queue.len]
		queue.len--

		if (!O || O.gcDestroyed)
			processing_objects -= O
			continue

		O:process()
		
		if (MC_TICK_CHECK)
			return

/datum/subsystem/object/stat_entry()
	..()
	stat(null, "[processing_objects.len] objects")

/datum/subsystem/object/Initialize(timeofday)
	for (var/A in objects_init_list)
		var/atom/movable/object = A
		if (isnull(object.gcDestroyed))
			object.initialize()

		objects_init_list.Cut()

	..()
