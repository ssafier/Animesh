#include "include/animesh.h"
#include "include/controlstack.h"
#define noAgents  2

#ifdef DEBUGGING
#define EyeOfEkron (key) "6456374b-8b39-f398-1233-e4ba1a4a7835"
#else
#define EyeOfEkron (key) "d7313cec-6f94-8ea0-6359-c2ad0b922f52"
#endif

#define GREET 2000
#define REZ_GREETER 2001
#define FREE_GREETER 2003
#define FREE_GREETER_BY_AVATAR 2004

#define STRIDE 3
#define NAME 0
#define AVATAR 1
#define OBJECT 2

list greeters;
list rez_points;
GLOBAL_DATA;

key yzzyx;

integer current_greeter;
integer greeter_len;

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
    greeters = ["Batman", NULL_KEY, NULL_KEY
#ifndef DEBUGGING
		,
		"Thor Odinson", NULL_KEY, NULL_KEY,
		"Ironman", NULL_KEY, NULL_KEY,
		"Hal Jordan", NULL_KEY, NULL_KEY,
		"Captain America", NULL_KEY, NULL_KEY,
		"Lobo", NULL_KEY, NULL_KEY,
		"Adam Warlock", NULL_KEY, NULL_KEY,
		"Amazon", NULL_KEY, NULL_KEY,
		"Red Hulk", NULL_KEY, NULL_KEY,
		"Omni-Man", NULL_KEY, NULL_KEY
#endif
		];
    current_greeter = 0;
    greeter_len = llGetListLength(greeters);
    rez_points = [
#ifdef DEBUGGING
		  <13.48603, 120.62470, 2985.5000>,
		  <13.48603, 116.19430, 2985.5000>
#else
		  <99.55029, 41.80960, 2206.56500>,
		  <97.85430, 41.80960, 2206.56500>,
		  <95.34937, 44.10002, 2205.88800>,
		  <102.46810, 44.10002, 2205.88800>,
		  <99.15845, 50.03228, 2204.61900>
#endif
		  ];

  }
  
  object_rez(key id) {
    key xyzzy = yzzyx;
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
	yzzyx = xyzzy;
	string object = "";
	integer x = getNextGreeter();

	if (x != -1) {
	  vector pos = (vector) rez_points[(integer) llFrand(llGetListLength(rez_points))];
	  vector rc1 = RECT_1;
	  vector rc2 = RECT_2;
	  key obj = llRezObjectWithParams((string) greeters[x],
					  [REZ_POS, pos, FALSE, TRUE,
					   REZ_PARAM, 1,
					   REZ_ROT, ZERO_ROTATION, FALSE,
					   REZ_PARAM_STRING,
					   (string) n[0] + "|" + json + "|" + (string) rc1 + "|" + (string) rc2]);
	  greeters = llListReplaceList(greeters, [(key)(string)n[0], obj], x + AVATAR, x + OBJECT);
	  PUSH(obj);
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
