#include "include/animesh.h"
#include "include/controlstack.h"
#define noAgents  2

#define EyeOfEkron "d7313cec-6f94-8ea0-6359-c2ad0b922f52"

#define GREET 2000
#define REZ_GREETER 2001
#define GREETER_REZZED 2002
#define s_GREETER_REZZED "2002"
#define FREE_GREETER 2003
#define FREE_GREETER_BY_AVATAR 2004

#define HULK NULL_KEY
#define ABOMINATION NULL_KEY
#define InArea 2
// STATES (status)
#define OFF 0
#define ON 1
#define WAITING 2

// NPC [UUID, STATE, DEST LOC, PING,...
#define UUID 0
#define STATE 1
#define DESTINATION 2
#define PING_TIME 3
#define NPC_STRIDE 4
list npc = [];

integer brain = 0x922f52;
integer handle;

list ping_list;
integer ping_count;

integer find_animesh(key a) {
  integer i = 0;
  integer len = llGetListLength(npc);
  while (i < len) {
    if ((key) npc[i] == a) return i;
    i += NPC_STRIDE;
  }
  return -1;
}

do_pings() {
  --ping_count;
  llMessageLinked(LINK_THIS, PING, "STATUS", (key) ping_list[ping_count]);
}

default {
  state_entry() {
    handle = llListen(brain, "", NULL_KEY, "");
    npc = [HULK, 0, ZERO_VECTOR, 0,
	    ABOMINATION, 0, ZERO_VECTOR, 0];
    llSetTimerEvent(15.1);
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    //    llOwnerSay("gym "+(string) chan);
    if (chan == noAgents) {
      integer i;
      integer len = llGetListLength(npc);
      //    llOwnerSay("no agents");
      for (i = NPC_STRIDE * InArea; i < len; i += NPC_STRIDE) {
	key k = (key) npc[i];
	if (k != NULL_KEY) {
	  llSay((integer)("0x"+llGetSubString((string) k, -6, -1)), "FREE");
	  llMessageLinked(LINK_THIS, FREE_GREETER, "|", (key) npc[i]);
	}
	npc = llList2List(npc, 0, NPC_STRIDE * InArea - 1);
      }
    }

    if (chan != PING_BACK &&
	chan != GREET &&
	chan != GREETER_REZZED) return;
    GET_CONTROL;
    switch (chan) {
    case GREETER_REZZED: {
      string id;
      string current;
      string newbies;
      POP(id);
      //      llOwnerSay((string) id + " rezzed." + (string) next);
      if ((key) id != NULL_KEY) {
	list l = llGetObjectDetails(id, [OBJECT_POS]);
	npc = npc + [id, 7, (vector) l[0], llGetUnixTime()];
	POP(current);
	POP(newbies);
	//	llOwnerSay("newbies "+newbies + (string) next);
	if (newbies != "") {
	  llMessageLinked(LINK_THIS, REZ_GREETER,
			  s_GREETER_REZZED + "|"+current+"|"+newbies, xyzzy);
	}
      }
      break;
    }
    case GREET: {
      string current;
      string newbies;
      string departed;
      POP(current);
      POP(newbies);
      POP(departed);

      if (newbies != "") {
	//	llOwnerSay("rezzing");
	llMessageLinked(LINK_THIS, REZ_GREETER,
			s_GREETER_REZZED + "|"+current+"|"+newbies, xyzzy);
      }
      break;
    }
    case PING_BACK: {
      string x;
      POP(x);
      if ((integer) x == 0) {
	integer index = llListFindList(npc, [(string) ping_list[ping_count]]);
	if (index != -1 && index > NPC_STRIDE) { // * 2 - 1 = 1
	  npc = llDeleteSubList(npc, index, index + NPC_STRIDE  - 1);
	}
	llMessageLinked(LINK_THIS, FREE_GREETER, "|", (key) ping_list[ping_count]);
	llSay((integer)("0x"+llGetSubString((string) ping_list[ping_count], -6, -1)), "FREE");
      }
      if (ping_count > 0) do_pings();
      break;
    }
    default: break;
    }
  }
  listen(integer chan, string name, key xyzzy, string msg) {
    list params = llParseString2List(msg, ["|"], []);
    integer index = find_animesh(xyzzy);
    if (index == -1) return;
    switch ((string) params[0]) {
    case "DEPART": {
      npc = llDeleteSubList(npc, index, index + NPC_STRIDE - 1);
      llMessageLinked(LINK_THIS, FREE_GREETER, "|", xyzzy);
      break;
    }
    case "STATUS": { // state location
      npc = llListReplaceList(npc, [xyzzy] + llList2List(params, 1, -1) + [llGetUnixTime()],
			      index, index + NPC_STRIDE - 1);
      llMessageLinked(LINK_THIS, PING_BACK, "|1", xyzzy);
      break;
    }
    case "ON": {
      if ((integer) npc[index + STATE] == 0) {
	npc = llListReplaceList(npc,[1],index + STATE, index + STATE);
	npc = llListReplaceList(npc,[llGetUnixTime()],
				index + PING_TIME, index + PING_TIME);
	llRegionSayTo(xyzzy, (integer) ("0x"+llGetSubString((string) xyzzy, -6, -1)), "WAIT");
      }
      break;
    }
    case "OFF": {
      if ((integer) npc[index + STATE] != 0) {
	npc = llListReplaceList(npc,[0],index + 1, index + 1);
      }
      break;
    }
    default: break;
    }
    if (ping_count > 0 && xyzzy == (key) npc[ping_count])  do_pings();
  }
  timer() {
    integer i;
    integer len = llGetListLength(npc);
    ping_list = [];
    ping_count = 0;
    for(i = 0; i < len; i+= NPC_STRIDE) {
      if ((integer) npc[i + STATE] != 0 &&
	  (integer) npc[i + PING_TIME] > 15) { // active
	ping_list = ping_list + [(key) npc[i + UUID]];
	ping_count++;
      }
    }
    if (ping_count > 0) do_pings();
  }
}

  
