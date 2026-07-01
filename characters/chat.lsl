#include "include/animesh.h"

#ifndef debug
#define debug(x)
#endif

list chatQ;

default {
  state_entry() {
    chatQ = [];
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != CHAT) return;
    integer timerp = chatQ == [];
    chatQ = chatQ + [msg];
    if (chatQ) llSetTimerEvent(1.5 + llFrand(1.5));
  }
  timer() {
    llSetTimerEvent(0);
    llShout(0, (string) chatQ[0]);
    if (llGetListLength(chatQ) == 1) {
      chatQ = [];
    } else {
      chatQ = llList2List(chatQ,1,-1);
      if (chatQ) llSetTimerEvent(1.5 + llFrand(1.5));
    }
  }
}
