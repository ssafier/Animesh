purple_rain(){
  llParticleSystem([
		    PSYS_PART_FLAGS,(0
				     | PSYS_PART_EMISSIVE_MASK 
				     | PSYS_PART_INTERP_COLOR_MASK 
				     | PSYS_PART_INTERP_SCALE_MASK 
				     | PSYS_PART_WIND_MASK 
				     ),
		    PSYS_PART_START_COLOR,<1.00000, 1.00000, 1.00000>,
		    PSYS_PART_END_COLOR,<1.00000, 1.00000, 1.00000>,
		    PSYS_PART_START_ALPHA,0.600000,
		    PSYS_PART_END_ALPHA,0.400000,
		    PSYS_PART_START_SCALE,<0.05000, 0.80000, 0.00000>,
		    PSYS_PART_END_SCALE,<0.07500, 0.50000, 0.00000>,
		    PSYS_PART_MAX_AGE,1.200000,
		    PSYS_SRC_ACCEL,<0.00000, 0.00000, -10.50000>,
		    PSYS_SRC_PATTERN,8,
		    PSYS_SRC_TEXTURE,"6eea067d-8333-fb71-0c00-89a085ae024d",
		    PSYS_SRC_BURST_RATE,0.050000,
		    PSYS_SRC_BURST_PART_COUNT,60,
		    PSYS_SRC_BURST_RADIUS,0.500000,
		    PSYS_SRC_BURST_SPEED_MIN,0.000000,
		    PSYS_SRC_BURST_SPEED_MAX,0.000000,
		    PSYS_SRC_MAX_AGE,0.000000,
		    PSYS_SRC_OMEGA,<0.00000, 0.00000, 0.00000>,
		    PSYS_SRC_ANGLE_BEGIN,0.400000*PI,
		    PSYS_SRC_ANGLE_END,1.000000*PI]);
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
}

rain(vector color) {
  llParticleSystem([
		    PSYS_PART_FLAGS,(0
				     | PSYS_PART_EMISSIVE_MASK 
				     | PSYS_PART_INTERP_COLOR_MASK 
				     | PSYS_PART_INTERP_SCALE_MASK 
				     | PSYS_PART_WIND_MASK 
				     ),
		    PSYS_PART_START_COLOR,color,
		    PSYS_PART_END_COLOR,color,
		    PSYS_PART_START_ALPHA,0.600000,
		    PSYS_PART_END_ALPHA,0.400000,
		    PSYS_PART_START_SCALE,<0.05000, 0.80000, 0.00000>,
		    PSYS_PART_END_SCALE,<0.07500, 0.50000, 0.00000>,
		    PSYS_PART_MAX_AGE,1.200000,
		    PSYS_SRC_ACCEL,<0.00000, 0.00000, -10.50000>,
		    PSYS_SRC_PATTERN,8,
		    PSYS_SRC_TEXTURE,"861d60f5-aa8c-327e-c315-9ddff8063a26",
		    PSYS_SRC_BURST_RATE,0.050000,
		    PSYS_SRC_BURST_PART_COUNT,60,
		    PSYS_SRC_BURST_RADIUS,0.500000,
		    PSYS_SRC_BURST_SPEED_MIN,0.000000,
		    PSYS_SRC_BURST_SPEED_MAX,0.000000,
		    PSYS_SRC_MAX_AGE,0.000000,
		    PSYS_SRC_OMEGA,<0.00000, 0.00000, 0.00000>,
		    PSYS_SRC_ANGLE_BEGIN,0.400000*PI,
		    PSYS_SRC_ANGLE_END,1.000000*PI]);
}

default {
  link_message(integer from, integer chan, string color, key ignore) {
    switch(chan) {
    case 0: {
      llSetTimerEvent(5);
      purple_rain();
    }
    case 1: {
      llSetTimerEvent(5);
      rain((vector) color);
    }
    default: break;
    }
  }
  timer() {
    llSetTimerEvent(0);
    llParticleSystem([]);
  }
}
