#include "src/animesh/include/animesh.h"
#include "src/animesh/include/controlstack.h"
#include "src/server/include/mpg.h"

#define NOTECARD_NAME "!Wrestling"

#ifndef debug
#define debug(x)
#endif

integer quotes;

integer avatar_prim;
key current_avatar;
float probability_of_win;
integer handle;

// chatbot
float last_chat;
integer wins;
integer losses;
string msgdefault;

integer in_sequence;
integer prior_flags;
float sequence_count;
integer sequence_win;

key note_handle;

string create_fight_description() {
  string text = "You are engaged in a fight involving boxing, wrestling and martial arts.";
  if (wins > 0 || losses > 0) {
    text = text + "  For the individual actions in this fight, you have " + (string) wins + " wins and "+ (string) losses + " losses.";
  }
  return text;
}

linksetLine(string line) {
  list temp = llParseString2List(line, ["|"], []);
  if (llGetListLength(temp) != 2) return;
  list states = llParseString2List((string) temp[0], ["+"], []);
  string data = (string) temp[1];
  integer i = 0;
  while (i < llGetListLength(states)) {
    llLinksetDataWrite((string) states[i], data);
    ++i;
  }
}

integer max(integer a,integer b) { if (a > b) return a; return b; }
#define set_max(a, b) a = max(a, b)

integer avatar_strength(string json) {
  integer strength = 300;
  set_max(strength, (integer) llJsonGetValue(json, ["sml"]));
  string rp =  llJsonGetValue(json, ["rp"]);
  switch ((integer) llJsonGetValue(rp,["strength"])) {
  case 0:
  case 1: { strength = 200; break; }
  case 3: { set_max(strength, 1000); break; }
  case 4: { set_max(strength, 5000); break; }
  case 5: { set_max(strength, 10000); break; }
  case 6: { set_max(strength, 12000); break; }
  case 7: { set_max(strength, 20000); break; }
  default: { set_max(strength, 100000); break; }
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
  if (str >= 100000) return 7; else
    if (str >= 20000) return 6; else
      if (str >= 15000) return 5; else
	if (str >= 10000) return 4; else
	  if (str >= 5000) return 3; else
	    if (str >= 1000) return 2; else
	      if (str >= 300) return 1;
  return 0;
}

AIChat(string d, string avdesc, string s) {
  last_chat = llGetTime();
  llMessageLinked(LINK_THIS, CHATBOT,
		  "*" + chatString(d) + "*|"  +
		  avdesc + "|" + llLinksetDataRead((string) current_avatar + "-scene")
		  + "|" + chatString(llLinksetDataRead(s)),
		  current_avatar);
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
  on_rez(integer x) {
    if (x == 0) return;
    llLinksetDataWrite("seq-win","Bored now.");
    llLinksetDataWrite("seq-loss","Aw come on.");
    note_handle = llGetNumberOfNotecardLines(NOTECARD_NAME);
  }
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

  dataserver(key request, string data)  {
    if (request == note_handle) {
      note_handle = NULL_KEY;
      integer count = (integer)data;
      integer index;
            
      for (index = 0; index <= count; ++index) {
	string line = llGetNotecardLineSync(NOTECARD_NAME, index);
	if (line == NAK) {
	  llOwnerSay("Notecard line reading failed");
	} else if (line != EOF) {
	  if (line != "") linksetLine(line);
	} else {  // EOF
	  debug("Configuration loaded.");
	}
      }
    }
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != WRESTLE &&
	chan != ACTION_OFF &&
	chan != avatarSeated &&
	chan != returnLeaf) return;
    switch (chan) {
    case WRESTLE: {
      string avatar_json = llLinksetDataRead((string) xyzzy);
      integer strength = avatar_strength(avatar_json);
      integer index = strength2index(strength) * 5;

      quotes = index + 4;

      probability_of_win = ProbabilityWin((float) strength,
					  (float) llLinksetDataRead("strength"));
      llMessageLinked(LINK_THIS, sitAvatar, msg, xyzzy);
      break;
    }
    case ACTION_OFF: {
      string msg;
      string avdesc = llLinksetDataRead((string) xyzzy + "-desc");
      if (wins == 0) {
	  llMessageLinked(LINK_THIS, CHATBOT,
			  "*you are defeated*|" + avdesc +
			  "|You loose the fight|I give.",
			  current_avatar);
      } else if (losses == 0) {
	llMessageLinked(LINK_THIS, CHATBOT,
			"*you are victorious*|" + avdesc +
			"|You win the fight|I give.",
			current_avatar);
      } else {
	llMessageLinked(LINK_THIS, CHATBOT,
			"*fight ends*|" + avdesc +
			"|The fight is over and you respond based on wins and losses|Good fight.",
			current_avatar);
      }
      current_avatar = NULL_KEY;
      llMessageLinked(LINK_THIS, stopSequence, "", NULL_KEY);
      llMessageLinked(LINK_THIS, resetAnimationState, "", current_avatar);
      llMessageLinked(LINK_THIS, menuOff, "", current_avatar);
      current_avatar = NULL_KEY;
      llMessageLinked(LINK_THIS, WRESTLE_DONE, "", NULL_KEY);
      break;
    }
    case avatarSeated: {
      integer objectPrimCount = llGetObjectPrimCount(llGetKey());
      integer currentLinkNumber = 0;
      avatar_prim = -1;
      while(currentLinkNumber <= objectPrimCount && avatar_prim == -1) {
	list params = llGetLinkPrimitiveParams(currentLinkNumber, [PRIM_NAME]);
	switch((string) params[0]) {
	case "avi prim": {
	  avatar_prim = currentLinkNumber;
	  break;
	}
	default: break;
	}
	currentLinkNumber++;
      }
      llSetLinkAlpha(avatar_prim,1,ALL_SIDES);
      llLinksetDataWrite((string)(current_avatar = xyzzy) + "-scene",
			 create_fight_description());
      llMessageLinked(LINK_THIS, getLeaf, (string) returnLeaf + "|Ready", current_avatar);
      last_chat = llGetTime();
      sequence_count = 0;
      llMessageLinked(LINK_THIS, CHATBOT,
		      "*approaching*|" + llLinksetDataRead((string) xyzzy + "-desc")  +
		      "|You have been challenged to a fight|Game on.",
		      current_avatar);
      break;
    }
    case returnLeaf: {
      string temp;
      string animation;
      vector p1;
      vector p2;
      rotation r1;
      rotation r2;
      integer force_menu = TRUE;
      
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
	llMessageLinked(avatar_prim, 2,(string)p2 + "|" + (string)(r2 * r1), current_avatar);
	PEEK(temp);
	integer flags = afCache | afStopAll;
	integer n = -1;
	if (llSubStringIndex(temp,"SEQUENCE") == 0) {
	  in_sequence = TRUE;
	  POP(temp);
	  n = (integer) llGetSubString(temp,9,-1);
	  PEEK(temp);
	  PUSH("SEQUENCE-" + (string) n);
	  float time = llGetTime();
	  if (n != 1) {
	    flags = prior_flags;
	    if ((time - sequence_count) < 10) {
	      force_menu = FALSE;
	    } else {
	      sequence_count = time;
	    }
	    if ((time - last_chat)  > 15) {
	      if (sequence_win == TRUE) {
		AIChat(llLinksetDataRead(animation+"-win"),
		       llLinksetDataRead((string) xyzzy + "-desc"),
		       "seq-win");
	      } else {
		AIChat(llLinksetDataRead(animation+"-loss"),
		       llLinksetDataRead((string) xyzzy + "-desc"),
		       "seq-loss");
	      }
	    } 
	  } else {
	    sequence_count = time;
	  }
	} else {
	  in_sequence = FALSE;
	  sequence_count = 0;
	}
	
	llLinksetDataWrite("chat-default","This fight is below me.");
	if (!in_sequence || (n == 1)) {
	  if (llFrand(1.0) <= probability_of_win) {
	    flags = flags | afSwap;
	    wins++;
	    string s = "win-" + (string) ((integer) llFrand(quotes) + 1);
	    sequence_win = TRUE;
	    if ((llGetTime() - last_chat)  > 15) {
	      AIChat(llLinksetDataRead(animation+"-win"),
		     llLinksetDataRead((string) xyzzy + "-desc"),
		     s);
	    }
	  } else {
	    losses++;
	    string s = "defeat-" + (string) ((integer) llFrand(quotes) + 1);
	    sequence_win = FALSE;
	    if ((llGetTime() - last_chat)  > 15) {
	      AIChat(llLinksetDataRead(animation+"-loss"),
		     llLinksetDataRead((string) xyzzy + "-desc"),
		     s);
	    }
	  }
	}
	prior_flags = flags;
	llMessageLinked(LINK_THIS, doAnimations,
			animation + "|" + (string)flags, current_avatar);
      } 

      if (force_menu)
	llMessageLinked(LINK_THIS, getLeaf, (string) returnLeaf + "|<root node>", current_avatar);
      break;
    }
    default: break;
    }
  }
}

