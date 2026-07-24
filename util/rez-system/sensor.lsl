#include "include/animesh.h"
#include "include/controlstack.h"
#include "src/animesh/include/npc.h"

#define KillOld 502
#define DIST 96

string avatar;

default {
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != 502 || xyzzy == NULL_KEY) return;
    avatar = (string) xyzzy;
    llSensor("", NULL_KEY, SCRIPTED, DIST, PI);
  }

  sensor(integer x) {
    list npc = NPCs;
    while (x > 0) {
      --x;
      key a = llDetectedKey(x);
      if (a != NULL_KEY && llListFindList(npc, [llDetectedName(x)]) != -1) {
	integer ch = (integer) ("0x"+llGetSubString((string) a, -6, -1));
	llRegionSayTo(a, ch, "FREE-IF|"+avatar);
      }
    }
  }
}
