#include "include/animesh.h"

#define WP_ONE "<84.06374, 157.77440, 25.83009>"
#define WP_TWO "<107.77990, 133.03940, 25.83009>"
#define START WP_ONE + "|" + WP_TWO + "|Walk"

integer g_running;

default {
  state_entry() {
    g_running = FALSE;
    llStopObjectAnimation("Default");
    llStopObjectAnimation("Walk");
    llStopObjectAnimation("Ready");
    llStopObjectAnimation("Punch");
  }
  touch_start(integer x) {
    if (g_running) 
      llMessageLinked(LINK_THIS, ResetWanderTimers, "", llGetKey());
    else
      llMessageLinked(LINK_THIS, WanderForTime, "10|"+START, llGetKey());
    g_running = !g_running;
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    switch(chan) {
    case WanderDone: {
      llStopMoveToTarget();
      integer rand = (integer) (llFrand(1.75) + 0.5);
      string animation;
      switch(rand) {
      case 0: {
	animation = "Default";
	break;
      }
      case 1: {
	animation = "Punch";
	break;
      }
      default: {
	animation = "Ready";
	break;
      }
      }
      llStartObjectAnimation(animation);
      llSleep(5);
      llStopObjectAnimation(animation);
      llMessageLinked(LINK_THIS, WanderForTime, "10|"+START, llGetKey());
      break;
    }
    case BUMP: {
      llMessageLinked(LINK_THIS, ResetWanderTimers, "", llGetKey());
      llStopMoveToTarget();
      string animation;
      list l = llGetObjectDetails(xyzzy, [OBJECT_POS]);
      vector target = (vector) l[0];
      vector dir = llVecNorm(target - llGetPos());
      rotation rot = llRotBetween(<1.0, 0.0, 0.0>, <dir.x, dir.y, 0.0>);
      llRotLookAt(rot, 1.0, 0.75);
      switch(xyzzy) {
      case (key) "b576af0c-b251-402b-b34b-c569980da73b": {
	animation = "Trapped";
	llSay(0, "HEY!  That hurts.  Please don't hure me Hercules!");
	llStartObjectAnimation(animation);
	llSleep(8.5);
	llStopObjectAnimation(animation);
	break;
      }
      case (key) "c4814bb6-38d1-4e6b-9ccb-51a3b0ef0ded": {
	animation = "Kneel";
	llWhisper(0, "Excuse me, master.");
	llStartObjectAnimation(animation);
	llSleep(14);
	llStopObjectAnimation(animation);
	break;
      }
      default: {
	animation = "PutemUp";
	llSay(0, "Watch it "+llGetDisplayName(xyzzy)+"!  Put 'em up!  Put 'em up!");
	llStartObjectAnimation(animation);
	llSleep(6.5);
	llStopObjectAnimation(animation);
	break;
      }
      }
      llMessageLinked(LINK_THIS, WanderForTime, "10|"+START, llGetKey());
      break;
    }
    default: break;
    }
  }
}
