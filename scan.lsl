#include "include/controlstack.h"
#include "include/animesh.h"

float radius;

default {
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != SCAN &&
	chan != CANCEL_SCAN) return;
    GET_CONTROL;
    switch(chan) {
    case SCAN: {
      string temp;
      POP(temp);
      radius = (float) temp;
      llSetTimerEvent(1);
      break;
    }
    case CANCEL_SCAN: {
      llSetTimerEvent(0);
      break;
    }
    default: break;
    }
    NEXT_STATE;
  }
  timer() {
    llSensor("", NULL_KEY, AGENT,  radius, PI);
  }
  sensor(integer num) {
    string detected = (string) num;
    while(num) {
      --num;
      key k = llDetectedKey(num);
      if (k != NULL_KEY) detected = detected + "|" + (string) k;
    }
    llMessageLinked(LINK_THIS, DETECTED, detected, llGetKey());
  }
}  
