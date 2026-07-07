#include "src/animesh/include/animesh.h"

#define STRIDE 3
#define PARTNER "fd8154a7-d9fb-5435-bb31-dcf1545b41a5"
#define CLONE "74816720-f156-0428-8ab4-dc029e4da2f3"

integer handle;
integer brain;
string chat_animation = "Explosive animation - Leaning Discuss";
string walk_animation = "Explosive animation - Walk 13 Skip";
string bored_animation = "Explosive animation - Polish Nails";

integer count;
integer current;

vector home;
rotation home_rot;

key entrant;
list power;
string greet;
integer stride;
integer brain_state;

string chat_string;

stop_animations() {
  list animations = llGetObjectAnimationNames();
  integer i = llGetListLength(animations);
  while (i > 0) {
    --i;
    llStopObjectAnimation((string) animations[i]);
  }
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
    count = (integer) llLinksetDataRead("CONVERSE-COUNT");
    home = llGetPos();
    home_rot = llGetRot();
    state bored;
  }
}

state bored {
  state_entry() {
    stop_animations();
    llStartObjectAnimation(bored_animation);
    llSetTimerEvent(llFrand(4.0)*60.0+60.0);
    brain = llListen(2, "", NULL_KEY, "");
  }
  timer() {
    llSetTimerEvent(0);
    state chat;
  }
  state_exit() {
    llListenRemove(brain);
  }
  listen(integer chan, string name, key xyzzy, string msg) {
    if (chan == 2) {
      integer i = llSubStringIndex(msg, "|");
      entrant = (key) llGetSubString(msg,0, i-1);
      power = llParseString2List(llGetSubString(msg,i+1,-1), ["+"], []);
      state brain_cmd;
    }
  }
}

state chat {
  state_entry() {
    stop_animations();
    llStartObjectAnimation(chat_animation);

    handle = llListen(0,"", (key) PARTNER, "");
    brain = llListen(2, "", NULL_KEY, "");

    current = (integer) llFrand(count / STRIDE) + 1;
    llSay(0, llLinksetDataRead("CONVERSE-"+(string) current));
  }
  state_exit() {
    llListenRemove(handle);
    llListenRemove(brain);
  }
  listen(integer chan, string name, key xyzzy, string msg) {
    if (chan == 2) {
      integer i = llSubStringIndex(msg, "|");
      entrant = (key) llGetSubString(msg,0, i-1);
      power = llParseString2List(llGetSubString(msg,i+1,-1), ["+"], []);
      state brain_cmd;
    } 
    if (current != -1) {
      chat_string = llLinksetDataRead(llGetSubString(msg,0,64));
      if (chat_string != "") llSetTimerEvent(llFrand(1.5) + 1.25);
    }
  }
  timer() {
    llSetTimerEvent(0);
    llSay(0, chat_string);
    chat_string = "";
    current = -1;
    state bored;
  }
}

state brain_cmd {
  state_entry() {
    integer i = llListFindList(power, ["strength"]);
    integer strength;
    string text = (string) entrant + "|";
    if (i == -1) {
      text = text + "-1";
      strength = -1;
      power = [];
    } else {
      text = text + (string) power[i+1];
      strength = (integer)(string)power[i+1];
    }
    llRegionSayTo((key) PARTNER, 2, text);
    if (strength < 0) {
      stride = 3;
      greet = "NOOBY-";
    } else if (strength < 6) {
      greet = "WEAKER-";
      stride = 4;
    } else if (strength == 6) {
      greet = "SAME-";
      stride = 4;
    } else {
      greet = "STRONGER-";
      stride = 3;
    }
    count = (integer) llLinksetDataRead(greet+"COUNT");
    llSleep(1+llFrand(1.5));

    brain_state = 1;
    current = (integer) llFrand(count/stride) + 1;
    handle = llListen(0,"", (key) PARTNER, "");
    llSay(0, chatString(llLinksetDataRead(greet+(string)current),  entrant));
  }

  state_exit() {
    llListenRemove(handle);
    llListenRemove(brain);
  }

  listen(integer from, string name, key xyzzy, string msg) {
    chat_string = llLinksetDataRead(llGetSubString(msg,0,64));
    llSetTimerEvent(llFrand(1.5) + 1.25);
    brain_state++;
  }
  
  timer() {
    llSetTimerEvent(0);
    if (chat_string != "") {
      llSay(0,  chat_string);
      chat_string = "";
      if (stride == 3) llSetTimerEvent(3+llFrand(2));
    } else {
      llSay(0, "I'll get the door for you.  Just around the corner.  They are waiting for you.");
      llSay(3,"open");
      llRegionSayTo((key) CLONE, 2, (string) entrant + "|" + llDumpList2String(power,"+"));
      state bored;
    }
  }
}
