#include "include/animesh.h"
#include "src/animesh/include/gym.h"
#include "src/animesh/include/eye-of-ekron.h"

#ifndef debug
#define debug(x)
#endif

#define EyeOfEkron (key) "d7313cec-6f94-8ea0-6359-c2ad0b922f52"
#define Filters [EyeOfEkron, Abomination, Hulk, KalEl, BlackAdam]
integer brain = 0x922f52;
integer channel;
integer handle;
integer public;

string animation;

vector pos;
rotation rot;

#define Chat(msg) llSleep(1.5 + llFrand(1.5)); llShout(0, msg);

default {
  state_entry() {
    llSetStatus(STATUS_PHYSICS, TRUE);
    llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y, FALSE);

    channel = (integer) ("0x"+llGetSubString((string) llGetKey(), -6, -1));
    handle = llListen(BroadcastChannel, "", NULL_KEY, "");
    llStartObjectAnimation(animation = LEAN);
    list o = llGetPrimitiveParams([PRIM_POSITION, PRIM_ROTATION]);
    pos = (vector) o[0];
    rot = (rotation) o[1];
    llSetTimerEvent(120);
  }

  listen(integer chan, string name, key xyzzy, string msg) {
    if (chan == BroadcastChannel) {
      list temp = llParseString2List(msg, ["|"], []);
      if (llGetObjectName() != (string) temp[3]) return;
      key avatar = (key) (string) temp[1];
      string called = llGetDisplayName(avatar);
      string animesh = (string) temp[2];
      llSleep(5 + llFrand(3.5));
      llMessageLinked(LINK_THIS, CHATBOT,
		      "*A gym-rat " + called + " and " + animesh +
		      " enter the gym.  You and " + CHATTER +
		      " are gossiping at the welcome desk.|[" + animesh +
		      "] to ["+ called + "]  Wow.  Is that Superman and Black Adam?  And he Hulk and Abomination are wrestlers?  Nifty.|Hi?",
		      avatar);

      return;
    }
  }

  timer() {
    list o = llGetPrimitiveParams([PRIM_POSITION, PRIM_ROTATION]);
    if ((vector) o[0] != pos || (rotation) o[1] != rot) {
      llSetStatus(STATUS_PHYSICS, FALSE);
      llSetLinkPrimitiveParamsFast(LINK_ROOT,
				   [PRIM_POSITION, pos, PRIM_ROTATION, rot]);
      llSetStatus(STATUS_PHYSICS, TRUE);
      llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y, FALSE);
    }
  }
}
