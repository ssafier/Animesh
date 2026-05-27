#include "include/animesh.h"

#define HOME <169.00848, 85.51353, 2201.70703>
list patrol = [<169.00848, 80.96202, 2202.12842>,
	       <150.75906, 80.96202, 2202.12842>,
	       <134.70116, 82.36063, 2200.32544>,
	       <137.35650, 75.90836, 2201.58300>,
	       <135.45090, 74.08201, 2201.58300>,
	       <134.57170, 72.14067, 2201.58300>,
	       <135.87380, 69.72604, 2201.58300>,
	       <137.67180, 69.49168, 2201.58300>,
	       <137.67180, 16.01735, 2201.33400>,
	       <166.17660, 16.01735, 2201.33400>,
	       <182.00390, 64.01768, 2202.17200>];


integer handle;
string animation = "Default";

default {
  state_entry() {
    llStopObjectAnimation(animation);
    if (llFrand(1.0) > 0.5) {
      animaton = "Rifle";
    } else {
      animation = "Default";
    }
    llStartObjectAnimation(animation);
    handle = llListen(2,"", NULL_KEY, "");
  }
  state_exit() {
    llListenRemove(handle);
  }
  listen(integer chan, string name, key xyzzy, string msg) {
    switch(msg) {
    case "patrol": {
      llMessageLinked(LINK_THIS, PATH, patrol, NULL_KEY);
      break;
    }
    case "stop": {
      llMessageLinked(LINK_THIS,STOP, "", llGetKey());
      break;
    }
    case "home":   {
      state go_home;
      break;
    }
    default: break;
    }
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    switch(chan) {
    case PathDone: {
      state go_home;
      break;
    }
    default: break;
    }
  }
}

state go_home {
  state_entry() {
    llMessageLinked(LINK_THIS, GOTO, (string) HOME, llGetKey());
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    switch(chan) {
    case WanderDone: {
      
      state default;
      break;
    }
    case BUMP: {
      llMessageLinked(LINK_THIS, GOTO, (string) HOME, llGetKey());
      break;
    }
    default: state default;
    }
  }
}
