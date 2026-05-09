#include "include/animesh.h"

default {
  link_message(integer from, integer chan, string msg, key xyzzy) {
    switch(chan) {
    case ResetWanderTimers: {
      llSetTimerEvent(0);
      llMessageLinked(LINK_THIS, STOP, "", xyzzy);
      break;
    }
    case WanderForTime: {
      integer index = llSubStringIndex(msg,"|");
      float t = (float) llGetSubString(msg, 0, index - 1);
      llSetTimerEvent(t);
      llMessageLinked(LINK_THIS, WANDER, llGetSubString(msg, index + 1, -1), xyzzy);
      break;
    }
    default: break;
    }
  }
  timer() {
    llSetTimerEvent(0);
    llMessageLinked(LINK_THIS, STOP, "", llGetKey());
    llMessageLinked(LINK_THIS, WanderDone, "", llGetKey());
  }
}
