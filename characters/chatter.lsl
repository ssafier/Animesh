#include "include/animesh.h"
#include "src/animesh/include/gym.h"

#ifndef debug
#define debug(x)
#endif

#define EyeOfEkron (key) "d7313cec-6f94-8ea0-6359-c2ad0b922f52"
#define Filters [EyeOfEkron, Abomination, Hulk, KalEl, BlackAdam]
integer brain = 0x922f52;
integer channel;
integer handle;
integer public;

string animation;

vector pos;
rotation rot;

#define Chat(msg) llSleep(1.5 + llFrand(1.5)); llSay(0, msg);

respond2Command(key from, string msg) {
  list chat;
  debug("command "+(string) from+" "+msg);
  switch(from) {
#ifdef CheckBlackAdam
  case BlackAdam: {
    switch (msg) {
    case "ABOMINATION": {
      debug("black adam abomination");
      chat = CheckBlackAdam;
      Chat((string) chat[(integer) llFrand(llGetListLength(chat))]);
      break;
    }
    default: break;
    }
    break;
  }
#endif
  case EyeOfEkron: {
    break;
  }
  default: break;
  }
}

respond2Default(key from, string msg) {
  list chat;
  switch(from) {
#ifdef RespondAbomination
  case Abomination: { // this is black adam
    if (msg == "Any wimp wanna wrestle?") {
      if (llFrand(1.0) > 0.5) {
	key superman = KalEl;
	llSay((integer) ("0x" + llGetSubString((string) superman, -6, -1)), "ABOMINATION");
      } else {
	chat = RespondAbomination;
	Chat((string) chat[(integer) llFrand(llGetListLength(chat))]);
      }
    }
    break;
  }
#endif
#ifdef RespondHulk
  case Hulk: {
    break;
  }
#endif
#ifdef RespondKalEl
  case KalEl: {
    chat = RespondKalEl;
    integer index = llListFindList(chat, [msg]);
    if (index != -1) {
      Chat((string) chat[index + 1]);
    }
    break;
  }
#endif
#ifdef RespondBlackAdam
  case BlackAdam: {
    debug("Black Adam");
    chat = RespondBlackAdam;
    integer index = llListFindList(chat, [msg]);
    if (index != -1) {
      Chat((string) chat[index + 1]);
    }
    break;
  }
#endif
  default: break;
  }
}

default {
  state_entry() {
    llSetStatus(STATUS_PHYSICS, TRUE);
    llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y, FALSE);

    channel = (integer) ("0x"+llGetSubString((string) llGetKey(), -6, -1));
    handle = llListen(channel, "", NULL_KEY, "");
    public = llListen(0,"",NULL_KEY,"");
    llStartObjectAnimation(animation = LEAN);
    list o = llGetPrimitiveParams([PRIM_POSITION, PRIM_ROTATION]);
    pos = (vector) o[0];
    rot = (rotation) o[1];
    llSetTimerEvent(60);
  }
  listen(integer chan, string name, key xyzzy, string msg) {
    list filters = Filters;
    if (llListFindList(filters, [xyzzy]) == -1) return;
    switch (chan) {
    case 0: {
      respond2Default(xyzzy, msg);
      break;
    }
    case channel: {
      respond2Command(xyzzy, msg);
      break;
    }
    default: break;
    }
  }
  timer() {
    list o = llGetPrimitiveParams([PRIM_POSITION, PRIM_ROTATION]);
    if ((vector) o[0] != pos || (rotation) o[1] != rot) {
      llSetStatus(STATUS_PHYSICS, FALSE);
      llSetLinkPrimitiveParamsFast(LINK_ROOT,
				   [PRIM_POSITION, pos, PRIM_ROTATION, rot]);
      llSetStatus(STATUS_PHYSICS, TRUE);
      llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y, FALSE);
    }
  }
}
