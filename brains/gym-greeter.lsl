#include "include/animesh.h"
#include "include/controlstack.h"
#include "src/animesh/include/npc.h"
#include "src/animesh/include/eye-of-ekron.h"
#define noAgents  2

#define TELEPORTER (key) "d3ddc622-7bb6-3a18-8ff6-685fc25d0ee5"

#define KALEL (key) "7d604f6b-bf14-3491-b3ae-1c8f24198ca6"
#define BLACKADAM (key) "d5220666-effd-7009-82f2-5e9d5f83e06a"

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

list static_greeters;

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
    list npcs = NPCs;
    integer i = 0;
    integer len = llGetListLength(npcs);
    greeters = [];
    for (i = 0; i < len; i += 2) {
      greeters = greeters + [(string) npcs[i], NULL_KEY,NULL_KEY];
    }
    current_greeter = 0;
    greeter_len = llGetListLength(greeters);
    handle = llListen(0x922f52 + 1, "", TELEPORTER, "");
    static_greeters = AnimeshGreeters;
    llListenControl(handle, FALSE);
  }
  
  listen(integer chan, string ignore, key xyzzy, string msg) {
    llListenControl(handle, FALSE);
    PUSH(msg);
    string name = (string) greeters[saved_index];
    string chat = llLinksetDataRead(name);
    if (chat != "") {
      integer y = (integer) llFrand(3) + 1;
      list c =llJson2List( llJsonGetValue(chat,[(string) y]));
      integer i = 0;
      integer l = llGetListLength(c);
      key prior = NULL_KEY;
      string hear = "";
      for (i =0; i < l; i += 2) {
	switch((string) c[i]) {
	case "Superman": {
	  key superman = KALEL;
	  llRegionSayTo(superman,
			(integer) ("0x" + llGetSubString((string) superman, -6, -1)),
			"CHAT|"+(string) prior + "|" + hear + "|" + (string) c[i + 1]);
	  hear = (string) c[i + 1];
	  prior = KALEL;
	  break;
	}
	case "Black Adam": {
	  key shazam = BLACKADAM;
	  llRegionSayTo(shazam,
			(integer) ("0x" + llGetSubString((string) shazam, -6, -1)),
			"CHAT|"+(string) prior + "|" + hear + "|" + (string) c[i + 1]);
	  hear = (string) c[i + 1];	  
	  prior = BLACKADAM;
	  break;
	}
	default: {
	  key animesh = (key) msg;
	  llRegionSayTo(animesh,
			(integer) ("0x" + llGetSubString((string) animesh, -6, -1)),
			"CHAT|"+(string) prior + "|" + hear + "|" + (string) c[i + 1]);
	  hear = (string) c[i + 1];	  
	  prior = animesh;
	  break;
	}
	}
	hear = (string) c[i+1];
      }
    }
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
	  string name = (string) greeters[x];

	  llListenControl(handle, TRUE);
	  avatar = (key)(string)n[0];
	  saved_index = x;
	  llShout(0,"Incoming teleports from " + llGetDisplayName(avatar) + " and " + (string) greeters[x] + ".");
	  llShout(BroadcastChannel, "INCOMING|"+(string)avatar+"|"+(string) greeters[x] +
		  "|" + (string) static_greeters[(integer) llFrand(llGetListLength(static_greeters))]);
	  llRegionSayTo(TELEPORTER, brain, name + "|" + (string) n[0] + "|" + json + "|" + (string) rc1 + "|" + (string) rc2);
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
