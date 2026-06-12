#include "include/animesh.h"
#define EyeOfEkron (key) "d7313cec-6f94-8ea0-6359-c2ad0b922f52"

integer brain = 0x922f52;
integer channel;
integer handle;

string animation;

default {
  state_entry() {
    llSetStatus(STATUS_PHYSICS, TRUE);
    llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y, FALSE);

    channel = (integer) ("0x"+llGetSubString((string) llGetKey(), -6, -1));
    handle = llListen(channel, "", EyeOfEkron, "");
    llStartObjectAnimation(animation = LEAN);
  }
}
