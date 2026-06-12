#include "include/animesh.h"

string animation;

default {
  link_message(integer from,integer chan, string msg, key xyzzy) {
    if (chan != LOOP_WALK) return;
    list params = llParseStringKeepNulls(msg, ["|"], []);
    float time = (float)(string)params[1];
    if (animation != "") llStopObjectAnimation(animation);
    if (time < 0.01) {
      llSetTimerEvent(0);
      animation = "";
      return;
    }
    llStartObjectAnimation(animation = (string) params[0]);
    llSetTimerEvent((float)(string)params[1]);
  }
  timer() {
    llStartObjectAnimation(animation);
  }
}
