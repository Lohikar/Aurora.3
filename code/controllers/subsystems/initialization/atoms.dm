var/datum/controller/subsystem/atoms/SSatoms


#define INITIALIZATION_INSSATOMS 0	//New should not call Initialize
#define INITIALIZATION_INNEW_MAPLOAD 1	//New should call Initialize(TRUE)
#define INITIALIZATION_INNEW_REGULAR 2	//New should call Initialize(FALSE)

var/global/atoms_initialized = INITIALIZATION_INSSATOMS

/datum/controller/subsystem/atoms
	name = "Atoms"
	init_order = SS_INIT_ATOMS
	flags = SS_NO_FIRE

	var/old_initialized

/datum/controller/subsystem/atoms/New()
	NEW_SS_GLOBAL(SSatoms)

/datum/controller/subsystem/atoms/Initialize(timeofday)
	global.atoms_initialized = INITIALIZATION_INNEW_MAPLOAD
	InitializeAtoms()
	return ..()

/datum/controller/subsystem/atoms/proc/InitializeAtoms(list/atoms = null)
	if(global.atoms_initialized == INITIALIZATION_INSSATOMS)
		return

	var/list/late_loaders

	global.atoms_initialized = INITIALIZATION_INNEW_MAPLOAD

	var/static/list/NewQdelList = list()

	if(atoms)
		for(var/I in atoms)
			var/atom/A = I
			if(!A.initialized)	//this check is to make sure we don't call it twice on an object that was created in a previous Initialize call
				if(QDELETED(A))
					if(!(NewQdelList[A.type]))
						WARNING("Found new qdeletion in type [A.type]!")
						NewQdelList[A.type] = TRUE
					continue
				var/start_tick = world.time
				if(A.Initialize(TRUE))
					LAZYADD(late_loaders, A)
				if(start_tick != world.time)
					WARNING("[A]: [A.type] slept during its Initialize!")
				CHECK_TICK
		testing("Initialized [atoms.len] atoms")
	else
		//#ifdef TESTING
		var/count = 0
		//#endif
		for(var/atom/A in world)
			if(!A.initialized)	//this check is to make sure we don't call it twice on an object that was created in a previous Initialize call
				if(QDELETED(A))
					/*if(!(NewQdelList[A.type]))
						WARNING("Found new qdeletion in type [A.type]!")
						NewQdelList[A.type] = TRUE*/
					continue
				var/start_tick = world.time
				if(A.Initialize(TRUE))
					LAZYADD(late_loaders, A)
				//#ifdef TESTING
				else
					++count
				//#endif TESTING
				if(start_tick != world.time)
					WARNING("[A]: [A.type] slept during its Initialize!")
				CHECK_TICK
		testing("Roundstart initialized [count] atoms")

	global.atoms_initialized = INITIALIZATION_INNEW_REGULAR

	if(late_loaders)
		for(var/I in late_loaders)
			var/atom/A = I
			var/start_tick = world.time
			A.Initialize(FALSE)
			if(start_tick != world.time)
				WARNING("[A]: [A.type] slept during its Initialize!")
			CHECK_TICK
		testing("Late-initialized [late_loaders.len] atoms")

/datum/controller/subsystem/atoms/Recover()
	if(global.atoms_initialized == INITIALIZATION_INNEW_MAPLOAD)
		InitializeAtoms()
	old_initialized = SSatoms.old_initialized