#include "include/animesh.h"

#define WP_ONE "<182.06000, 9.59519, 2202.04900>"
#define WP_TWO "<150.20890, 85.36724, 2202.04900>"
#define START WP_ONE + "|" + WP_TWO + "|"

integer g_running;

default {
  state_entry() {
    g_running = FALSE;
    llSetLinkPrimitiveParamsFast(2,[PRIM_SIZE, <0.76975, 3.62342, 3.68901>]);
  }
  touch_start(integer x) {
    if (g_running) 
      llMessageLinked(LINK_THIS, ResetWanderTimers, "", llGetKey());
    else
      llMessageLinked(LINK_THIS, WanderForTime, "|60|"+START+"Slow", llGetKey());
    g_running = !g_running;
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    switch(chan) {
    case WanderDone: {
      llSetLinkPrimitiveParamsFast(2,[PRIM_SIZE, <0.76975, 3.62342, 3.68901>]);
      integer rand = (integer) (llFrand(0.75) + 0.5);
      string animation;
      switch(rand) {
      case 0: {
	animation = "Default";
	break;
      }
      case 1: {
	animation = "No";
	break;
      }
      default: {
	animation = "Default";
	break;
      }
      }
      llStartObjectAnimation(animation);
      llSleep(5);
      llStopObjectAnimation(animation);
      string speed;
      if (llFrand(1.0) >= 0.5) speed = "Slow"; else speed = "Fast";
      llMessageLinked(LINK_THIS, WanderForTime, "|60|"+START + speed, llGetKey());
      break;
    }
    case BUMP: {
      break;
    }
    default: break;
    }
  }
}
