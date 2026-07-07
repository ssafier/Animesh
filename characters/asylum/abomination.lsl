#include "src/animesh/include/animesh.h"

#define PARTNER "1c62e572-0450-17f0-9b4d-80344a35c06b"

integer handle;
integer brain;

string chat_animation = "Explosive animation - Lean and Chat";
string stretching_animation = "Stretching";
string dbi_animation = "front_double_bicep_looped";
string mm_animation = "JEFF HAMPTON POSING MR OLYMPIA (New Most Muscular)";
string abs_animation = "POSE_AbsRightThigh_R";
string rbi_animation = "S_RightBicep";
string schest_animation = "Explosive animation - Single Hand Chest Pound";
string chest_animation = "Explosive animation - Chest Pound";
string proud_animation = "Explosive animation - Proud";

string response;

vector home;
rotation home_rot;

key entrant;
integer strength;

list greet;
integer stride;
integer brain_state;

string choose(list l) {
  return (string) l[(integer) llFrand(llGetListLength(l))];
}

stop_animations() {
  list animations = llGetObjectAnimationNames();
  integer i = llGetListLength(animations);
  while (i > 0) {
    --i;
    llStopObjectAnimation((string) animations[i]);
  }
}

string chatString(string s, key avatar) {
  string name = llGetDisplayName(avatar);
  integer idx = llSubStringIndex(s, name);

  if (idx == -1) return s;
  if (idx == 0) {
    return "%s" + llGetSubString(s, llStringLength(name), -1);
  } else if (idx == llStringLength(s)) {
    return llGetSubString(s,0,-1 - llStringLength(name)) + "%s";
  }
  return llGetSubString(s,0,idx-1) + "%s" +
    llGetSubString(s, idx + llStringLength(name), -1);
}


default {
  state_entry() {
    
    home = llGetPos();
    home_rot = llGetRot();
    
    state waiting;
  }
}

state waiting {
  state_entry() {
    stop_animations();
    string animation = choose([stretching_animation, schest_animation, mm_animation, chest_animation, proud_animation]);
    llStartObjectAnimation(animation);
    handle = llListen(0,"", PARTNER, "");
    brain = llListen(2,"", PARTNER, "");
  }
  
  listen(integer chan, string name, key xyzyy, string msg) {
    if (chan == 2) {
      integer i = llSubStringIndex(msg, "|");
      entrant  = (key) llGetSubString(msg,0,i-1);
      strength = (integer) llGetSubString(msg,0,i-1);
      state brain_cmd;
    }
    response = llLinksetDataRead(llGetSubString(msg,0,64));
    if (response != "") {
      stop_animations();
      llStartObjectAnimation(choose([chat_animation, rbi_animation, dbi_animation, abs_animation]));
      llSetTimerEvent(llFrand(1.5) + 1.25);
    }
  }
  
  timer() {
    llSetTimerEvent(0);
    llSay(0, response);
    llSleep(llFrand(1.5) + 1.5);
    stop_animations();
    string animation = choose([stretching_animation, schest_animation, mm_animation, chest_animation, proud_animation]);
    llStartObjectAnimation(animation);
  }
  
  state_exit() {
    llListenRemove(handle);
    llListenRemove(brain);
  }
}

state brain_cmd {
  state_entry() {
    stop_animations();
    string animation = choose([dbi_animation, mm_animation, abs_animation, rbi_animation, schest_animation, chest_animation, proud_animation]);
    llStartObjectAnimation(animation);
    handle = llListen(0,"", PARTNER, "");
    brain = llListen(2,"", PARTNER, "");
    brain_state = 1;
  }
  
  state_exit() {
    llListenRemove(handle);
    llListenRemove(brain);
  }

  listen(integer chan, string name, key xyzyy, string msg) {
    if (brain_state == 1) msg = chatString(msg, entrant);
    ++brain_state;
    response = llLinksetDataRead(llGetSubString(msg,0,64));
    llSetTimerEvent(llFrand(1.5) + 1.25);
  }

  timer() {
    llSetTimerEvent(0);
    if (response == "") state waiting;
    llSay(0, response);
    if (stride == 4 && brain_state > 2) {
      llSleep(llFrand(1.5) + 1.5);
      state waiting;
    }
  }
}
