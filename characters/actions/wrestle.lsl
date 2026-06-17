#include "include/animesh.h"
#ifdef DEBUGGING
#define EyeOfEkron (key) "6456374b-8b39-f398-1233-e4ba1a4a7835"
#else
#define EyeOfEkron (key) "d7313cec-6f94-8ea0-6359-c2ad0b922f52"
#endif

key avatar_prim;
integer prim_channel;

key current_avatar;

default {
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != WRESTLE &&
	chan != avatarSeated &&
	chan != returnLeaf) return;
    switch (chan) {
    case WRESTLE: {
      integer index = llSubStringIndex(msg, "|");
      current_avatar = (key) llGetSubString(msg, 0, index - 1);
      llMessageLinked(LINK_THIS, sitAvatar, msg, xyzzy);
      avatar_prim = xyzzy;
      prim_channel = (integer)("0x"+llGetSubString((string) avatar_prim, -4, -1));
      break;
    }
    case avatarSeated: { // xyzzy == object
      llMessageLinked(LINK_THIS, getLeaf, (string) returnLeaf + "|Ready");
      break;
    }
    case returnLeaf: {
      string temp;
      string animation;
      vector p1;
      vector p2;
      rotation r1;
      rotation r2;
      GET_CONTROL;
      POP(temp);
      animation = temp;
      POP(temp);
      p1 = (vector) temp;
      POP(temp);
      r1 = (rotation) temp;
      POP(temp);
      p2 = (vector) temp;
      POP(temp);
      r2 = (rotation) temp;
      llRegionSayTo(avatar_prim, prim_channel,(string)p2 + "|" + (string)r2);
      llMessageLinked(LINK_THIS, doAnimations,
		      animation + "|" + (string)(afCache | afStopAll), current_avatar);
      break;
    }
    default: break;
    }
  }
}
