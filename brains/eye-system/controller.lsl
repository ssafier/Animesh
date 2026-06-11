#include "src/animesh/include/gym.h"

#define checkVisitors  1
#define noAgents  2
#define s_getStrength "8"
#define s_greet "2000"

#define cScanTime  1
#define nextState checkVisitors
#define controlData(s) s_getStrength + "+" + s_checkAlpha + "+" + s_greet + "|" + s

integer handle;
integer running = 0;

#ifndef debug
#define debug(x)
#endif

integer find(key k, list l) {
  integer len = llGetListLength(l);
  integer i;
  debug("find "+(string)k+" "+(string) len);
  for (i = 0; i < len; ++i) {
    if ((key) l[i] == k) return TRUE;
  }
  debug("not found");	
  return FALSE;
}

default {
  on_rez(integer x) {
    llResetScript();
  }
  state_entry() {
    llSetTimerEvent(cScanTime);
  }
  state_exit() {
    llSetTimerEvent(0);
  }
  timer() {
    llSetTimerEvent(0);
    llSensor("", "", AGENT, DISTANCE, TWO_PI);
    llSetTimerEvent(cScanTime); 
  }
  sensor(integer num) {
    llSetTimerEvent(0); // turn off
    key k = llDetectedKey(0);
    if (k == NULL_KEY) { llSetTimerEvent(cScanTime); return; }
    if (running == 0) {
      running = 1;
    }
    integer i = 0;
    string s = "";
    list area = llGetAgentList(AGENT_LIST_PARCEL, []);
    while (i < num) {
      k = llDetectedKey(i);
      if (k == NULL_KEY) {
	llMessageLinked(LINK_THIS,  nextState, controlData(s), NULL_KEY);
	llSetTimerEvent(cScanTime); 
	return; 
      }
      if (find(k, area)) {
	if (s != "") s = s + "~";
	s = s + (string) k;
	debug(k);
      }
      
      i++;
    }
    if (s == "") {
      if (running == 1) {
	llMessageLinked(LINK_THIS, noAgents, "", NULL_KEY);
      }
      running = 0;
    } else {
      debug((string) nextState + " " +  controlData(s));
      llMessageLinked(LINK_THIS, nextState, controlData(s), NULL_KEY);
    }
    llSetTimerEvent(cScanTime);
  }
  no_sensor() {
    if (running == 1) llMessageLinked(LINK_SET, noAgents, "", NULL_KEY);
    running = 0;
    llSetTimerEvent(cScanTime);
  }
}

