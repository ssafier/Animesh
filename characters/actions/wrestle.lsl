#include "src/animesh/include/animesh.h"
#include "src/animesh/include/controlstack.h"

#ifndef debug
#define debug(x)
#endif

#ifdef DEBUGGING
#define EyeOfEkron (key) "6456374b-8b39-f398-1233-e4ba1a4a7835"
#else
#define EyeOfEkron (key) "d7313cec-6f94-8ea0-6359-c2ad0b922f52"
#endif

integer quotes;

integer avatar_prim;
key current_avatar;
float probability_of_win;
integer handle;

integer max(integer a,integer b) { if (a > b) return a; return b; }
#define set_max(a, b) a = max(a, b)

integer avatar_strength(string json) {
  integer strength = 300;
  set_max(strength, (integer) llJsonGetValue(json, ["sml"]));
  string rp =  llJsonGetValue(json, ["rp"]);
  switch ((integer) llJsonGetValue(rp,["strength"])) {
  case 1: strength = 200; break;
  case 3: set_max(strength, 1000); break;
  case 4: set_max(strength, 5000); break;
  case 5: set_max(strength, 10000); break;
  case 6: set_max(strength, 20000); break;
  case 7: set_max(strength, 100000); break;
  default: break;
  }
  string sps = llJsonGetValue(json,["sps"]);
  if (sps != "") {
    string result = llJsonGetValue(sps,["total"]);
    if (result != JSON_NULL && result != JSON_INVALID) {
      set_max(strength, (integer) result);
    }
  }
  return strength;
}

integer strength2index(integer str) {
  if (str >= 100000) return 6; else
    if (str >= 20000) return 5; else
      if (str >= 10000) return 4; else
	if (str >= 5000) return 3; else
	  if (str >= 1000) return 2; else
	    if (str >= 300) return 1;
  return 0;
}

string chatString(string s) {
  integer idx = llSubStringIndex(s, "%s");
  if (idx == -1) return s;
  if (idx == 0) {
    return llGetDisplayName(current_avatar) + llGetSubString(s, 2, -1);
  } else if (idx == llStringLength(s)) {
    return llGetSubString(s,0,-3) + llGetDisplayName(current_avatar);
  }
  return llGetSubString(s,0,idx-1) +
    llGetDisplayName(current_avatar) +
    llGetSubString(s, idx + 2, -1);
}

default {
  state_entry() {
    integer objectPrimCount = llGetObjectPrimCount(llGetKey());
    integer currentLinkNumber = 0;
    avatar_prim = -1;
    while(currentLinkNumber <= objectPrimCount && avatar_prim == -1) {
      list params = llGetLinkPrimitiveParams(currentLinkNumber,
					     [PRIM_NAME]);
      switch((string) params[0]) {
      case "avi prim": {
	/*
	llSetLinkPrimitiveParamsFast(currentLinkNumber,
				     [PRIM_SIZE, <0.5,0.5,0.1>,PRIM_POS_LOCAL, <0.5,0,-0.5>]
				     );
	llSetLinkAlpha(currentLinkNumber,1,ALL_SIDES);
	*/
	avatar_prim = currentLinkNumber;
	break;
      }
      default: break;
      }
      ++currentLinkNumber;
    }
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != WRESTLE &&
	chan != ACTION_OFF &&
	chan != avatarSeated &&
	chan != returnLeaf) return;
    switch (chan) {
    case WRESTLE: {
      handle = llListen(0, "", current_avatar = xyzzy, "");
      integer index = llSubStringIndex(msg, "|");
      string avatar_json = llGetSubString(msg, index + 1, -1);
      integer strength = avatar_strength(avatar_json);
      index = strength2index(strength) * 5;

      quotes = index + 4;

      probability_of_win = ProbabilityWin((float) strength,
					  (float) llLinksetDataRead("strength"));
      llMessageLinked(LINK_THIS, sitAvatar, msg, xyzzy);
      break;
    }
    case ACTION_OFF: {
      llMessageLinked(LINK_THIS, resetAnimationState, "", current_avatar);
      llMessageLinked(LINK_THIS, menuOff, "", current_avatar);
      current_avatar = NULL_KEY;
      llListenRemove(handle);
      llMessageLinked(LINK_THIS, WRESTLE_DONE, "", NULL_KEY);
      break;
    }
    case avatarSeated: {
      llMessageLinked(LINK_THIS, getLeaf, (string) returnLeaf + "|Ready", current_avatar);
      break;
    }
    case returnLeaf: {
      string temp;
      string animation;
      vector p1;
      vector p2;
      rotation r1;
      rotation r2;
      debug("leaf "+msg);
      GET_CONTROL;
      POP(temp);
      if (temp != "STRING") {
	animation = temp;
	POP(temp);
	p1 = (vector) temp;
	POP(temp);
	r1 = (rotation) temp;
	POP(temp);
	p2 = (vector) temp;
	POP(temp);
	r2 = (rotation) temp;
	llMessageLinked(avatar_prim, 2,(string)p2 + "|" + (string)r2, current_avatar);
	integer flags = afCache | afStopAll;
	if (llFrand(1.0) <= probability_of_win) {
	  flags = flags | afSwap;
	  string s = "win-" + (string) ((integer) llFrand(quotes) + 1);
	  llMessageLinked(LINK_THIS, CHAT, chatString(llLinksetDataRead(s)),
			  current_avatar);
	} else {
	  string s = "defeat-" + (string) ((integer) llFrand(quotes) + 1);
	  llMessageLinked(LINK_THIS, CHAT, chatString(llLinksetDataRead(s)),
			  current_avatar);
	}
	llMessageLinked(LINK_THIS, doAnimations,
			animation + "|" + (string)flags, current_avatar);
      }
      llMessageLinked(LINK_THIS, getLeaf, (string) returnLeaf + "|<root node>", current_avatar);
      break;
    }
    default: break;
    }
  }

  listen(integer chan, string name, key xyzzy, string msg) {
    switch(llToLower(msg)) {
    case "menu": {
      llMessageLinked(LINK_THIS, getLeaf, (string) returnLeaf + "|<root node>", current_avatar);
      break;
    }
    case "stop": {
      llUnSit(current_avatar);
      break;
    }
    case "help": {
        llInstantMessage(current_avatar, "Allow adjusting your position by pressing FORWARD and BACK keys at the same time");
	llInstantMessage(current_avatar, "Adjust your position using Pgup/Pgdn, Up/Down arrow, and shift-left/right arrow keys\nDisable by pressing Pgup and Pgdn keys at the same time");
	break;
    }
    default: break;
    }
  }
}
