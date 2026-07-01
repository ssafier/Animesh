#include "include/animesh.h"
#include "include/controlstack.h"

#define KillOld 502
#define DIST 96

default {
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != 502 || xyzzy == NULL_KEY) return;
    llSensor("", xyzzy, SCRIPTED, DIST, PI);
  }

  sensor(integer x) {
    key a = llDetectedKey(0);
    integer ch = (integer) ("0x"+llGetSubString((string) a, -6, -1));
    llRegionSayTo(a, ch, "FREE");
  }
}
