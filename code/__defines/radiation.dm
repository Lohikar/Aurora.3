// The effects various gasses have on radiation
#define RAD_FACTOR_AIR 0.9	// N2 / O2
#define RAD_FACTOR_PHORON 0.5	
#define RAD_FACTOR_OTHER 0.8	// Stuff that's not phoron or air

#define RAD_FACTOR_DEFAULT 1

// Just your normal steel walls
#define RAD_FACTOR_WALL 0.5


// if radiation falls below this, it's considered zero
#define RAD_FALLOFF_THRESHOLD 0.1