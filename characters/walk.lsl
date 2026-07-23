#include "include/animesh.h"

string animation;
integer walking = FALSE;

default {
  link_message(integer from,integer chan, string msg, key xyzzy) {
    if (chan == STOP_WALK) {
      llSetTimerEvent(0);
      if (animation != "") llStopObjectAnimation(animation);
      animation = "";
      return;
    }
    if (chan != LOOP_WALK) return;
    if (walking) return;
    walking = TRUE;
    list params = llParseStringKeepNulls(msg, ["|"], []);
    float time = (float)(string)params[1];
    if (animation != "") llStopObjectAnimation(animation);
    if (time < 0.01) {
      llSetTimerEvent(0);
      animation = "";
      return;
    }
    llStartObjectAnimation(animation = (string) params[0]);
    llSetTimerEvent(time);
  }
  timer() {
    llStopObjectAnimation(animation);
    llStartObjectAnimation(animation);
  }
}
