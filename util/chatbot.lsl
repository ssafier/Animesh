#include "src/animesh/include/animesh.h"
#include "src/server/include/mpg.h"

integer avatar_handle;
integer use_chatbot;
list avatars;

string create_avatar_description(key avi, string json) {
  string avdesc = "  Your opponent is "+ llGetDisplayName(avi) +".";
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
  avdesc = avdesc + "  They are " + (string) text[strength] + " compared to you " + (string) text[me] + ".";
  return avdesc;
}

string chatString(string s, key avatar) {
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

default {
  state_entry() {
    avatar_handle = llListen(0, "",NULL_KEY , "");
    llListenControl(avatar_handle, FALSE);
    avatars = [];
  }

  state_exit() {
    llListenRemove(avatar_handle);
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    switch(chan) {
    case RegisterChatter: {
      if (use_chatbot = llSameGroup(xyzzy)) {
	avatars = avatars + [xyzzy, create_avatar_description(xyzzy, msg)];
	llListenControl(avatar_handle, TRUE);
      } else {
	avatars = avatars + [xyzzy, ""];
      }
      break;
    }
    case CHATBOT_GREET: {
      integer index = llListFindList(avatars, [xyzzy]);
      if (index != -1) {
	string avdesc = (string) avatars[index + 1];
	index = llSubStringIndex(msg, "|");
	llMessageLinked(LINK_THIS, CHATBOT,
			"*" + chatString((string) llGetSubString(msg, 0, index - 1), xyzzy) + "*|" +
			avdesc + "|You are arriving.|" + 
			chatString((string) llGetSubString(msg, index + 1, - 1), xyzzy),
			xyzzy);
	break;
      }
    }
    default: break;
    }
  }

  listen(integer chan, string name, key xyzzy, string msg) {
    integer index = llListFindList(avatars, [xyzzy]);
    if (index != -1) {
      list action_keys = llParseString2List(llLinksetDataRead("action-keys"), ["|"], []);
      integer len = llGetListLength(action_keys);
      integer index = -1;
      integer i;
      for (i = 0; index == -1 && i < len; i++) {
	if (llSubStringIndex(msg, (string) action_keys[i]) == 0) index = i;
      }
      if (index != -1) {
	llMessageLinked(LINK_THIS, CHAT_ACTION, msg, xyzzy);
	return;
      }
      if (use_chatbot) {
	string avdesc = (string) avatars[index + 1];
	llMessageLinked(LINK_THIS, CHATBOT,
			msg + "|" + avdesc + "|" +chatString(" %s is talking to you.", xyzzy) +  "|I'm ignoring you.",
			xyzzy);
      }
    }
    return;
  }
}
