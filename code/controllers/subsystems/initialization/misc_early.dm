// This is the first subsystem initialized by the MC.
// Stuff that should be loaded before everything else that isn't significant enough to get its own SS goes here.

/datum/controller/subsystem/misc_early
	name = "Early Miscellaneous Init"
	init_order = SS_INIT_MISC_FIRST
	flags = SS_NO_FIRE | SS_NO_DISPLAY

/datum/controller/subsystem/misc_early/Initialize(timeofday)
	// Create the data core, whatever that is.
	data_core = new /datum/datacore()
	
	// Initialize the pAI software list.
	for(var/type in subtypesof(/datum/pai_software))
		var/datum/pai_software/P = new type()
		if(pai_software_by_key[P.id])
			var/datum/pai_software/O = pai_software_by_key[P.id]
			world << "<span class='warning'>pAI software module [P.name] has the same key as [O.name]!</span>"
			continue
		pai_software_by_key[P.id] = P
		if(P.default)
			default_pai_software[P.id] = P

	// Setup the global HUD.
	global_hud = new
	global_huds = list(
		global_hud.druggy,
		global_hud.blurry,
		global_hud.vimpaired,
		global_hud.darkMask,
		global_hud.nvg,
		global_hud.thermal,
		global_hud.meson,
		global_hud.science
	)
	
	// This is kinda important. Set up details of what the hell things are made of.
	populate_material_list()

	// Create autolathe recipes, as above.
	populate_lathe_recipes()

	// Create robolimbs for chargen.
	populate_robolimb_list()

	if(config.ToRban)
		ToRban_autoupdate()

	// Setup the job controller.
	job_master = new /datum/controller/occupations()
	job_master.SetupOccupations()
	job_master.LoadJobs("config/jobs.txt")

	lobby_image = new/obj/effect/lobby_image()
	
	..()
