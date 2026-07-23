#include "include/animesh.h"
#include "include/controlstack.h"
#define noAgents  2

#ifdef DEBUGGING
#define EyeOfEkron (key) "6456374b-8b39-f398-1233-e4ba1a4a7835"
#else
#define EyeOfEkron (key) "d7313cec-6f94-8ea0-6359-c2ad0b922f52"
#endif

#define TELEPORTER (key) "d3ddc622-7bb6-3a18-8ff6-685fc25d0ee5"

#define GREET 2000
#define REZ_GREETER 2001
#define FREE_GREETER 2003
#define FREE_GREETER_BY_AVATAR 2004

#define STRIDE 3
#define NAME 0
#define AVATAR 1
#define OBJECT 2

list greeters;
GLOBAL_DATA;

integer current_greeter;
integer greeter_len;

integer handle;
key avatar;
integer saved_index;

integer getNextGreeter() {
  integer current = current_greeter;
  integer i;
  for (i = 0; i < greeter_len; i += STRIDE) {
    if ((key) greeters[current_greeter + AVATAR] == NULL_KEY) {
      current = current_greeter;
      current_greeter += STRIDE;
      if (current_greeter >= greeter_len) current_greeter = 0;
      return current;
    }
    current_greeter += STRIDE;
    if (current_greeter > greeter_len) current_greeter = 0;
    if (current_greeter == current) return -1;
  }
  return -1;
}
  

default {
  state_entry() {
    greeters = [
#ifndef DEBUGGING
		"Prime", NULL_KEY, NULL_KEY,
		"Hulk", NULL_KEY, NULL_KEY,
		"Colossus", NULL_KEY, NULL_KEY,
		"Ares", NULL_KEY, NULL_KEY,
		"Gladiator", NULL_KEY, NULL_KEY,
		"Conquest", NULL_KEY, NULL_KEY,
		"Gambit", NULL_KEY, NULL_KEY,
		"Spiderman", NULL_KEY, NULL_KEY,
		"Snow Symbiote", NULL_KEY, NULL_KEY,
		"Azazel", NULL_KEY, NULL_KEY,
		"Firestorm", NULL_KEY, NULL_KEY,
		"Rogue", NULL_KEY, NULL_KEY,
		"Northstar", NULL_KEY, NULL_KEY,
		"Human Torch", NULL_KEY, NULL_KEY,
		"Ben Grimm", NULL_KEY, NULL_KEY,
		"Batman", NULL_KEY, NULL_KEY,
		"Damien Wayne", NULL_KEY, NULL_KEY,
		"Red Robin", NULL_KEY, NULL_KEY,
		"Harley Quinn", NULL_KEY, NULL_KEY,
		"Dark Phoenix", NULL_KEY, NULL_KEY,
		"Flash", NULL_KEY, NULL_KEY,
		"Reverse Flash", NULL_KEY, NULL_KEY,
		"Thor Odinson", NULL_KEY, NULL_KEY,
		"Ironman", NULL_KEY, NULL_KEY,
		"Hal Jordan", NULL_KEY, NULL_KEY,
		"Captain America", NULL_KEY, NULL_KEY,
		"Lobo", NULL_KEY, NULL_KEY,
		"Adam Warlock", NULL_KEY, NULL_KEY,
		"Amazon", NULL_KEY, NULL_KEY,
		"Red Hulk", NULL_KEY, NULL_KEY,
		"Invincible", NULL_KEY, NULL_KEY,
#endif
		"Omni-Man", NULL_KEY, NULL_KEY
		];
    current_greeter = 0;
    greeter_len = llGetListLength(greeters);
    handle = llListen(0x922f52 + 1, "", TELEPORTER, "");
    llListenControl(handle, FALSE);
  }
  
  listen(integer chan, string name, key xyzzy, string msg) {
    llListenControl(handle, FALSE);
    PUSH(msg);
    greeters = llListReplaceList(greeters, [avatar, (key) msg], saved_index + AVATAR, saved_index + OBJECT);
    NEXT_STATE;
  }
  
  link_message(integer from, integer chan, string msg, key xyzzy) {
    switch (chan) {
    case FREE_GREETER: {
      integer index = llListFindList(greeters, [xyzzy]);
       if (index != -1) {
	greeters = llListReplaceList(greeters, [NULL_KEY, NULL_KEY], index - 1, index);
      }
      break;
    }
    case REZ_GREETER: { 
      GET_CONTROL_GLOBAL;
      string current;
      string newbies;
      POP(current);
      POP(newbies);
      list c = llParseString2List(current,["+"],[]);
      list n = llParseString2List(newbies,["+"],[]);
      if (llGetListLength(n) > 1)
	newbies = llDumpList2String(llList2List(n,1,-1),"+");
      else
	newbies = "";
      integer idx = llListFindList(c, [(string)n[0]]);
      PUSH(newbies);
      PUSH(current);
      if (idx != -1) {
	string json = (string) c[idx - 1];
	string object = "";
	integer x = getNextGreeter();

	if (x != -1) {
	  integer brain = 0x922f52 + 1;
	  vector rc1 = RECT_1;
	  vector rc2 = RECT_2;
	  
	  llListenControl(handle, TRUE);
	  avatar = (key)(string)n[0];
	  saved_index = x;
	  llShout(0,"Incoming teleports from " + llGetDisplayName(avatar) + " and " + (string) greeters[x] + ".");
	  llRegionSayTo(TELEPORTER, brain, (string) greeters[x] + "|" + (string) n[0] + "|" + json + "|" + (string) rc1 + "|" + (string) rc2);
	  return;
	}
	PUSH(NULL_KEY);
	NEXT_STATE;
	break;
      }
    }
    default: {
      break;
    }
    }
  }
}
