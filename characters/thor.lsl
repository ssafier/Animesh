#include "include/animesh.h"

#define WP_ONE "<112.71250, 45.62530, 2205.27000>"
#define WP_TWO "<99.38960, 55.83102, 2205.27000>"
#define START WP_ONE + "|" + WP_TWO + "|"

integer g_running;

default {
  state_entry() {
    g_running = FALSE;
  }
  touch_start(integer x) {
    if (llDetectedKey(0) != (key) "c4814bb6-38d1-4e6b-9ccb-51a3b0ef0ded") return;
    if (g_running) 
      llMessageLinked(LINK_THIS, ResetWanderTimers, "", llGetKey());
    else
      llMessageLinked(LINK_THIS, WanderForTime, "|" + ((string)(15+llFrand(45))) + "|"+START+"Slow", llGetKey());
    g_running = !g_running;
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    switch(chan) {
    case WanderDone: {
      integer rand = (integer) (llFrand(3.75) + 0.5);
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
	animation = "Ninja";
	break;
      }
      case 3: {
	animation = "mAttack";
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
      llMessageLinked(LINK_THIS, WanderForTime, "|" + ((string)(15+llFrand(45))) + "|"+START + speed, llGetKey());
      break;
    }
    case BUMP: {
      break;
    }
    default: break;
    }
  }
}
