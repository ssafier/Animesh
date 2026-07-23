#include "include/animesh.h"

string animation;
integer walking = FALSE;

default {
  link_message(integer from,integer chan, string msg, key xyzzy) {
    if (chan == STOP_WALK) {
      llSetTimerEvent(0);
      if (animation != "") llStopObjectAnimation(animation);
      animation = "";
      walking = FALSE;
      return;
    }
    if (chan != LOOP_WALK) return;
    list params = llParseStringKeepNulls(msg, ["|"], []);
    if (walking && animation == (string) params[0]) return;
    walking = TRUE;
    float time = (float)(string)params[1];
    if (animation != "") llStopObjectAnimation(animation);
    if (time < 0.01) {
      llSetTimerEvent(0);
      animation = "";
      walking = FALSE;
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
