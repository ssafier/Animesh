#include "include/animesh.h"

#define WP_ONE "<117.21300, 39.81018, 2206.10600>"
#define WP_TWO "<84.98854, 36.38675, 2206.10600>"
#define START WP_ONE + "|" + WP_TWO + "|"

integer g_running;

default {
  state_entry() {
    g_running = FALSE;
    llSetLinkPrimitiveParamsFast(2,[PRIM_SIZE, <0.51248, 2.79497, 2.69776>]);
  }
  touch_start(integer x) {
    if (llDetectedKey(0) != (key) "c4814bb6-38d1-4e6b-9ccb-51a3b0ef0ded") return;
    if (g_running) 
      llMessageLinked(LINK_THIS, ResetWanderTimers, "", llGetKey());
    else
      llMessageLinked(LINK_THIS, WanderForTime, ((string)(15 + llFrand(45)))+"|"+START+"Slow", llGetKey());
    g_running = !g_running;
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    switch(chan) {
    case WanderDone: {
      integer rand = (integer) (llFrand(2.75) + 0.5);
      string animation;
      switch(rand) {
      case 0: {
	animation = "Sweep";
	break;
      }
      case 1: {
	animation = "Hero";
	break;
      }
      case 2: {
	animation = "Throw";
	break;
      }
      default: {
	animation = "Default";
	break;
      }
      }
      llStartObjectAnimation(animation);
      llSleep(15);
      llStopObjectAnimation(animation);
      string speed;
      if (llFrand(1.0) >= 0.5) speed = "Slow"; else speed = "Fast";
      llMessageLinked(LINK_THIS, WanderForTime, ((string)(15 + llFrand(45)))+"|"+START + speed, llGetKey());
      break;
    }
    case BUMP: {
      break;
    }
    default: break;
    }
  }
}
