#include "src/animesh/include/gym.h"
#include "include/particles/dome.h"

#define noAgents  2

#define TIMER 1.5
#define strength 1.0
#define damping 1.0
#define direction <0,-1,0>
key alpha;

default {
  state_entry() {
    alpha = NULL_KEY;
    llParticleSystem(Plasma_Dome);
  }
  
  link_message(integer from, integer chan, string msg, key xyzzy) {
    switch(chan) {
    case updateAlpha: {
      llSetTimerEvent(0);
      list loc = llGetObjectDetails(alpha = xyzzy, [ OBJECT_POS ]);
      llRotLookAt(llRotBetween(direction,
			       llVecNorm((vector) loc[0] - llGetPos())),
		  strength, damping);
      llSetTimerEvent(TIMER);
      break;
    }
    case noAgents: {
      llSetTimerEvent(0);
      alpha = NULL_KEY;
      llStopLookAt();
      break;
    }
    default: break;
    }
  }

  timer() {
    llSetTimerEvent(0);
    if (alpha != NULL_KEY) {
      list loc = llGetObjectDetails(alpha, [ OBJECT_POS ]);
      llRotLookAt(llRotBetween(direction,
			       llVecNorm((vector) loc[0] - llGetPos())),
		  strength, damping);
      llSetTimerEvent(TIMER);
    }
  }
}

