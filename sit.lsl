#include "include/animesh.h"

integer channel = DEFAULT_SIT_CHANNEL;
integer handle;

default {
  state_entry() {
    handle = llListen(channel, "", NULL_KEY, "");
  }

  listen(integer chan, string name, key xyzzy, string msg) {
    list l = llParseString2List(msg,["|"],[]);
    if (llGetListLength(l) < 2) return;
    switch ((integer) (string) l[0]) {
    case CALL: {
      break;
    }
    case SIT: {
      break;
    }
    default: break;
    }
  }
  
  link_message(integer from, integer chan, string msg, key xyzzy) {
    switch(chan) {
    case SitChannel: {
      llListenRemove(handle);
      handle = llListen(channel = (integer) msg, "", NULL_KEY, "");
      break;
    }
    default: break;
    }
  }
}
