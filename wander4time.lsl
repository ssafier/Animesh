#include "include/animesh.h"
#include "include/controlstack.h"

default {
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != STOP &&
	chan != GOTO) return;
    GET_CONTROL;
    switch(chan) {
    case ResetWanderTimers: {
      llSetTimerEvent(0);
      llMessageLinked(LINK_THIS, STOP, "", xyzzy);
      break;
    }
    case WanderForTime: {
      string temp;
      POP(temp);
      float t = (float) temp;
      llSetTimerEvent(t);
      PUSH_NEXT(WANDER)
      break;
    }
    default: break;
    }
    NEXT_STATE;
  }
  timer() {
    llSetTimerEvent(0);
    llMessageLinked(LINK_THIS, STOP, "", llGetKey());
    llMessageLinked(LINK_THIS, WanderDone, "", llGetKey());
  }
}
