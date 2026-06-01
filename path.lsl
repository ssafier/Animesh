#include "include/controlstack.h"
#include "include/animesh.h"

list path;
integer index;

default {
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != PATH &&
	chan != MoveDone) return;
    GET_CONTROL;
    switch(chan) {
    case PATH: {
      string temp;
      POP(temp);
      if (llGetListLength(path = llParseString2List(temp,["+"],[])) == 0) return;
      llMessageLinked(LINK_THIS, GOTO, (string) path[index = 0], xyzzy);
      break;
    }
    case MoveDone: {
      ++index;
      if (index >= llGetListLength(path)) {
	llMessageLinked(LINK_THIS, PathDone, "", xyzzy);
	path = [];
	index = 0;
	return;
      }
      llSleep(0.5);
      llMessageLinked(LINK_THIS, GOTO, (string) path[index], xyzzy);
      break;
    }
    default: break;
    }
    NEXT_STATE;
  }
}
