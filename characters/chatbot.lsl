#include "src/animesh/include/animesh.h"
#include "src/server/include/mpg.h"

#ifndef debug
#define debug(x)
#endif

key brain;
key avatar;
string animation;

#define CHANNEL ((integer)("0xE" + llGetSubString((string) brain, -5, -1)))
integer handle;
integer user_handle;

integer sml;
integer rp;
string rp_name;
integer sps;

vector home;
vector pos;
rotation rot;

#define clear_animation stop_animation
#define stop_animation() if (animation != "") { llStopObjectAnimation(animation); animation = ""; }

string chatString(string s) {
  integer idx = llSubStringIndex(s, "%s");
  if (idx == -1) return s;
  if (idx == 0) {
    return llGetDisplayName(avatar) + llGetSubString(s, 2, -1);
  } else if (idx == llStringLength(s)) {
    return llGetSubString(s,0,-3) + llGetDisplayName(avatar);
  }
  return llGetSubString(s,0,idx-1) +
    llGetDisplayName(avatar) +
    llGetSubString(s, idx + 2, -1);
}

AIChat(string text, string def_text) {
  string avdesc = llLinksetDataRead((string) avatar + "-desc");
  string scene =  llLinksetDataRead((string) avatar + "-scene");
  llMessageLinked(LINK_THIS, CHATBOT,
		  "*" + chatString(scene) + "*|"  + avdesc + "|" + chatString(text) + "|" +
		  chatString(def_text),  avatar);
}

string create_avatar_description(key avi, string json) {
  string avdesc = "  Your are talking to "+ llGetDisplayName(avi) +" a passing warrior.";
  string rp =  llJsonGetValue(json, ["rp"]);
  string sps = llJsonGetValue(json,["sps"]);
  string sml = llJsonGetValue(json, ["sml"]);
  integer strength = 1;
  integer str = -1;
  if (sml != JSON_INVALID && sml != JSON_NULL) {
    str = (integer) sml;
  }
  if (sps != JSON_INVALID && sps != JSON_NULL) {
    string result = llJsonGetValue(sps,["total"]);
    if (result != JSON_NULL && result != JSON_INVALID) {
      if ((integer) result > str) str = (integer) result;
    }
  }
  if (str >= 50000) strength = 7; else
    if (str >= 20000) strength = 6; else
      if (str >= 15000) strength = 5; else
	if (str >= 10000) strength = 4; else
	  if (str >= 5000) strength = 3; else
	    if (str >= 1000) strength = 2; else
	      if (str >= 300) strength = 1;
  str = (integer) llLinksetDataRead("strength");
  integer me;
  if (str >= 50000) me = 7; else
    if (str >= 20000) me = 6; else
      if (str >= 15000) me = 5; else
	if (str >= 10000) me = 4; else
	  if (str >= 5000) me = 3; else
	    if (str >= 1000) me = 2; else
	      if (str >= 300) me = 1;

  list text = StrengthText;
  if (rp != JSON_INVALID && rp != JSON_NULL) {
    string result = llJsonGetValue(rp,["proto"]);
    if (result != JSON_NULL && result != JSON_INVALID) {
      avdesc = avdesc + "  They have the powers of " + result;
      result = llJsonGetValue(rp,["strength"]);
      if (result != JSON_NULL && result != JSON_INVALID) {
	avdesc = avdesc + " and a  strength of " + (string) text[((integer) result) - 1] +
	  " compared to your strength of " + (string) text[me];
      }
      avdesc = avdesc + ".";
      result = llJsonGetValue(rp, ["alignment"]);
      if (result != JSON_NULL && result != JSON_INVALID) {
	list align = AlignmentText;
	avdesc = avdesc + " Their alignment is " + (string) align[(integer) result - 1];
      }
      return avdesc;
    } else {
      result = llJsonGetValue(rp,["strength"]);
      if (result != JSON_NULL && result != JSON_INVALID) {
	strength = (integer) result;
      }
    }
  }
  return avdesc;
}


default {
  // param string: <avatar key>|<avatar json>|<brain key>
  on_rez(integer x) {
    if (x == 0) return;
    home = llGetPos();
    list params = llParseString2List(llGetStartString(), ["|"], []);
    
    avatar = (key) (string) params[0];
    string avatar_json = (string) params[1];
    brain = (key) (string) params[2];
    llLinksetDataWrite((string) avatar + "-scene", (string) params[3]);
    llLinksetDataWrite((string) avatar, avatar_json);
    llLinksetDataWrite((string) avatar + "-desc",
		       create_avatar_description(avatar, avatar_json));
    list o = llGetPrimitiveParams([PRIM_POSITION, PRIM_ROTATION]);
    pos = (vector) o[0];
    rot = (rotation) o[1];

    llSetStatus(STATUS_PHYSICS, TRUE);
    llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y, FALSE);

    llSetTimerEvent(1.5);
  }

  timer() {
    llSetTimerEvent(0);
    state respond;
  }
}

state respond {
  state_entry() {
    llStartObjectAnimation(animation = STAND);
    handle = llListen(CHANNEL, "", NULL_KEY, "");
    user_handle = llListen(0, "", NULL_KEY, ""); // listen to everyone
    AIChat("[" + llGetDisplayName(avatar) + "] Helllo.", "Hello");
    llSetTimerEvent(60);
    llSensorRepeat("", avatar, AGENT, 96.0, PI, 1.0);
    llSetTimerEvent(0.1);
  }

  timer() {
    llSetTimerEvent(0);
    list o = llGetObjectDetails(avatar, [OBJECT_POS]);
    
    vector dir = llVecNorm((vector) o[0] - llGetPos());
    rotation rot = llRotBetween(<1.0, 0.0, 0.0>, <dir.x, dir.y, 0.0>);
    llRotLookAt(rot, 1.0, 0.75);

    llSetTimerEvent(2);
  }

  state_exit() {
    llListenRemove(handle);
    llListenRemove(user_handle);
    llSensorRemove();
    llSetTimerEvent(0);
  }

  listen(integer chan, string name, key xyzzy, string msg) {
    if (chan == CHANNEL) {
      list params = llParseString2List(msg, ["|"], []);
      switch((string) params[0]) {
      case "DIE": llDie();
      default: break;
      }
      return;
    }
    name = llGetDisplayName(xyzzy);
    if (name != "") AIChat("[" + name + "] " + msg, "I'm ignoring you.");
  }

  no_sensor() {
    // Avatar is offline or out of scanner range completely
    llListenRemove(handle);
    llListenRemove(user_handle);
    llSensorRemove();
    llSetTimerEvent(0);
    llSleep(0.1);
    llDie();
  }
}
