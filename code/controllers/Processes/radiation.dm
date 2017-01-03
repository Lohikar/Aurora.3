var/datum/controller/process/radiation/rad_master

/datum/controller/process/radiation
	var/list/datum/radiation_hotspot/hotspots

/datum/controller/process/radiation/setup()
	name = "radiation"
	schedule_interval = 2 * 10 // every 2 seconds
	hotspots = list()

	rad_master = src

/datum/controller/process/machinery/statProcess()
	..()
	stat(null, "[hotspots.len] hotspots")

/datum/controller/process/radiation/doWork()
	if (!hotspots || !hotspots.len)
		return

	// only process one at a time
	var/target = hotspots[1]
	target.process()

/datum/controller/process/radiation/register_hotspot(var/turf/origin, var/intensity, var/transient = 0, var/simulate_now = 0)
	var/datum/radiation_hotspot/hotspot = new(origin, intensity)
	hotspots += hotspot
	
	if (simulate_now)
		doWork()

// === RADIATION HOTSPOT DATUM ===

// Used to define a radiation emission source, such as the supermatter
/datum/radiation_hotspot
	var/obj/origin
	var/intensity
	var/is_transient

/datum/radiation_hotspot/New(var/obj/rad_origin, var/rads, var/transient = 0)
	intensity = rads
	is_transient = transient
	
	if (!rad_origin)
		return
	
	origin = rad_origin

/datum/radiation_hotspot/proc/process()
	for (var/mob/living/L in range(origin, get_range()))
		var/rads = intensity
		var/target = L.loc
		var/curr = get_step_towards(curr, target)
		while (curr != target)
			curr = get_step_towards(curr, target)
			rads *= get_decay_factor(curr)
		if (Debug2) world.log << "## DEBUG: [L] irradiated with [rads] rads from origin [origin]"
		
/datum/radiation_hotspot/proc/get_decay_factor(var/turf/target)
	var/turf/simulated/T = target
	if (!T)
		return RAD_FACTOR_DEFAULT
	
	if (T.blocks_air)
		return T.radiation_decay

	if (!T.zone)
		return RAD_FACTOR_DEFAULT
	
	var/gas = T.zone.gas

	if (!gas.len)
		return RAD_FACTOR_DEFAULT

	var/gas_aggregate
	var/total_gasses = gas.len
	for (var/the_gas in gas)
		gas_aggregate += calc_decay(gas[the_gas], get_gas_factor(the_gas))
		if (!QUANTIZE(gas[the_gas])	// if the amount of gas present is insignificant
			total_gasses--

	gas_aggregate /= gas.len

	return gas_aggregate


/datum/radiation_hotspot/proc/calc_decay(var/mol, var/factor)
	return CLAMP01(((mol*M_E**factor)/100) - 1)

/datum/radiation_hotspot/proc/get_gas_factor(var/gas)
	switch (gas)
		if ("oxygen")
		if ("nitrogen")
			return RAD_FACTOR_AIR
		if ("phoron")
			return RAD_FACTOR_PHORON
	
	return RAD_FACTOR_OTHER

/datum/radiation_hotspot/proc/get_range()
	// ripped from supermatter.dm
	return round(sqrt(intensity / 2))