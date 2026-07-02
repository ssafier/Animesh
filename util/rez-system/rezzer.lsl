#include "src/animesh/include/animesh.h"
#include "src/animesh/include/controlstack.h"
#include "src/animesh/include/npc.h"

#define TIME 7.5

#define noAgents  2

#define GREET 2000
#define REZ_GREETER 2001
#define FREE_GREETER 2003
#define FREE_GREETER_BY_AVATAR 2004
#define PROCESS 2005

list npc;

integer top;
integer bottom;

vector rez_pos;

ring() {
  llParticleSystem([
		    PSYS_PART_FLAGS,(0
				     | PSYS_PART_EMISSIVE_MASK 
				     | PSYS_PART_BOUNCE_MASK 
				     | PSYS_PART_INTERP_COLOR_MASK 
				     | PSYS_PART_INTERP_SCALE_MASK 
				     | PSYS_PART_FOLLOW_SRC_MASK 
				     | PSYS_PART_FOLLOW_VELOCITY_MASK 
				     | PSYS_PART_TARGET_POS_MASK 
				     ),PSYS_SRC_TARGET_KEY,llGetLinkKey(top),
		    PSYS_PART_START_COLOR,<0.50000, 0.80000, 1.00000>,
		    PSYS_PART_END_COLOR,<0.00000, 0.50000, 1.00000>,
		    PSYS_PART_START_ALPHA,0.350000,
		    PSYS_PART_END_ALPHA,0.700000,
		    PSYS_PART_START_SCALE,<4.00000, 4.00000, 0.00000>,
		    PSYS_PART_END_SCALE,<4.00000, 4.00000, 0.00000>,
		    PSYS_PART_MAX_AGE,0.300000,
		    PSYS_SRC_ACCEL,<0.00000, 0.00000, -0.23000>,
		    PSYS_SRC_PATTERN,2,
		    PSYS_SRC_TEXTURE,"447d0bd2-bad6-b7ac-352c-366ef7d02dff",
		    PSYS_SRC_BURST_RATE,0.100000,
		    PSYS_SRC_BURST_PART_COUNT,2,
		    PSYS_SRC_BURST_RADIUS,0.975000,
		    PSYS_SRC_BURST_SPEED_MIN,1.500000,
		    PSYS_SRC_BURST_SPEED_MAX,0.080000,
		    PSYS_SRC_MAX_AGE,0.000000,
		    PSYS_SRC_OMEGA,<10.00000, 10.00000, 10.00000>,
		    PSYS_SRC_ANGLE_BEGIN,0.900000*PI,
		    PSYS_SRC_ANGLE_END,0.950000*PI]);
}

lightning() {
  llParticleSystem([
           PSYS_PART_FLAGS,(0
			    | PSYS_PART_EMISSIVE_MASK	
			    | PSYS_PART_INTERP_COLOR_MASK	
			    | PSYS_PART_INTERP_SCALE_MASK	
			    | PSYS_PART_FOLLOW_SRC_MASK		
			    ),					
           PSYS_PART_START_COLOR,<1.00000, 1.00000, 1.00000>,	
           PSYS_PART_END_COLOR,<0.60000, 0.70000, 0.90000>,	
           PSYS_PART_START_ALPHA,1.000000,
           PSYS_PART_END_ALPHA,0.000000,
           PSYS_PART_START_SCALE,<0.70000, 1.00000, 0.00000>,
           PSYS_PART_END_SCALE,<0.70000, 8.00000, 0.00000>,
           PSYS_PART_MAX_AGE,0.400000,
           PSYS_SRC_ACCEL,<0.00000, 0.00000, 0.00000>,
           PSYS_SRC_PATTERN,2,
           PSYS_SRC_TEXTURE,"a41f533a-b0d3-ce00-1f4c-8f5f2c7ddfe6",
           PSYS_SRC_BURST_RATE,0.100000,
           PSYS_SRC_BURST_PART_COUNT,1,
           PSYS_SRC_BURST_RADIUS,0.000000,
           PSYS_SRC_BURST_SPEED_MIN,0.000000,
           PSYS_SRC_BURST_SPEED_MAX,0.000000,
           PSYS_SRC_MAX_AGE,0.000000,
           PSYS_SRC_OMEGA,<0.00000, 0.00000, 0.00000>,
           PSYS_SRC_ANGLE_BEGIN,0.000000*PI,
           PSYS_SRC_ANGLE_END,0.000000*PI
		    ]);
}

default {
  state_entry() {
    npc = NPCs;
    integer objectPrimCount = llGetObjectPrimCount(llGetKey());
    integer currentLinkNumber = 0;

    while(currentLinkNumber <= objectPrimCount) {
      list params = llGetLinkPrimitiveParams(currentLinkNumber,
					     [PRIM_NAME]);
      switch((string) params[0]) {
      case "teleport top": {
	top = currentLinkNumber;
	break;
      }
      case "Teleporter": {
	bottom = currentLinkNumber;
	break;
      }
      default: break;
      }
      ++currentLinkNumber;
    }

    list o = llGetLinkPrimitiveParams(LINK_ROOT, [PRIM_POSITION]);
    vector middle = (vector) o[0];
    rez_pos = middle;
    rez_pos.z += 1;
    llSetLinkPrimitiveParamsFast(top,
				 [PRIM_PHANTOM, TRUE,
				  PRIM_COLOR, ALL_SIDES, <1,1,1>, 0]); // make 0
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != PROCESS) return;
    integer index = llSubStringIndex(msg, "|");
    string animesh = llGetSubString(msg,0,index-1);
    integer idx = llListFindList(npc, [animesh]);
    switch ((integer) npc[idx + 1]) {
    case RING: {
      llSetTimerEvent(TIME);
      ring();
      break;
    }
    case LIGHTNING: {
      llSetTimerEvent(TIME);
      lightning();
      break;
    }
    case RAIN: {
      llMessageLinked(top,1,"<1,1,1>",NULL_KEY);
      break;
    }
    case GREEN_RAIN: {
      llMessageLinked(top,1,"<0,1,0>",NULL_KEY);
      break;
    }
    case PURPLE_RAIN: {
      llMessageLinked(top,0,"<1,1,1>",NULL_KEY);	    
      break;
    }
    case YELLOW_RAIN: {
      llMessageLinked(top,1,"<1,1,0>",NULL_KEY);
      break;
    }
    case BLACK_RAIN: {
      llMessageLinked(top,1,"<0,0,0>",NULL_KEY);
      break;
    }
    case RED_RAIN: {
      llMessageLinked(top,1,"<1,0,0>",NULL_KEY);
      break;
    }
    case BLUE_RAIN: {
      llMessageLinked(top,1,"<0,0,1>",NULL_KEY);
      break;
    }
    default: break;
    }
    llTriggerSound("transporter", 1.0);
    llSleep(1);
    key obj = llRezObjectWithParams(animesh,
				    [REZ_POS, rez_pos, FALSE, TRUE,
				     REZ_PARAM, 1,
				     REZ_ROT, ZERO_ROTATION, FALSE,
				     REZ_PARAM_STRING,llGetSubString(msg, index + 1, -1)]);
  }
  timer() {
    llSetTimerEvent(0);
    llParticleSystem([]);
  }
}
