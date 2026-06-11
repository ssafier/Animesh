#include "include/animesh.h"

default {
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != PING && chan != PING_BACK) return;
    switch (chan) {
    case PING: {
      llSetTimerEvent(2);
      llRegionSayTo(xyzzy, (integer) ("0x" + llGetSubString((string) xyzzy, -6, -1)), msg);
      break;
    }
    case PING_BACK: {
      llSetTimerEvent(0);
      break;
    }
    default: break;
    }	  
  }
  timer() {
    llSetTimerEvent(0);
    llMessageLinked(LINK_THIS, PING_BACK, "0", NULL_KEY);
  }
}
