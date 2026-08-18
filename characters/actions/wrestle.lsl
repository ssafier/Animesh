#include "src/animesh/include/animesh.h"
#include "src/animesh/include/controlstack.h"
#include "src/server/include/mpg.h"

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
integer sequence_count;

string create_fight_description() {
  string text = "You are engaged in a fight involving boxing, wrestling and martial arts.";
  if (wins > 0 || losses > 0) {
    text = text + "  For the individual actions in this fight, you have " + (string) wins + " wins and "+ (string) losses + " losses.";
  }
  return text;
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
    llLinksetDataWrite("Flip-win", "You foil %s's attack and flip them to the ground.");
    llLinksetDataWrite("Flip-loss", "%s foils your attack and flips you tot he ground.");
    llLinksetDataWrite("Headlock-win", "You flip %s to the ground and wrap your ");
    llLinksetDataWrite("Headlock-loss", "You are flipped to the ground, %s's legs wrapped around your head.");
    llLinksetDataWrite("Judo Throw-win", "You block %s's attack and throw them to the ground with a judo throw.");
    llLinksetDataWrite("Judo Throw-loss", "%s blocks your attack and uses judo throws you to the ground.");
    llLinksetDataWrite("Kicks-win", "You spin to the ground and kick %s's legs out from under them.");
    llLinksetDataWrite("Kicks-loss", "%s spins to the ground and kicks your legs out");
    llLinksetDataWrite("Piledriver-win", "You grab %s, flip him upside down, corkscrew-jump 10 feet in the air,  and smash them into the ground.");
    llLinksetDataWrite("Piledriver-loss", "% s grabs you, flips you upside down, corkscrew-jumps 10 feet in the air, and smashes you into the grou.");
    llLinksetDataWrite("Punch-win", "You knock %s down with a single punch.");
    llLinksetDataWrite("Punch-loss", "%s knows you down with a single punch.");
    llLinksetDataWrite("Roundhouse-win", "You attack %s with  a series of roundhouse punches.");
    llLinksetDataWrite("Roundhouse-loss", "%s attacks you with a series of roundhouse punches.");
    llLinksetDataWrite("ShoulderThrow-win", "You toss %s over your shoulder and throw them to the ground.");
    llLinksetDataWrite("ShoulderThrow-loss", "%s tosses you over their shoulder and throws you to the ground.");
    llLinksetDataWrite("Slam-win", "You lift %s and slam them to the ground.");
    llLinksetDataWrite("Slam-loss", "%s lifts you up and slams you to the ground.");
    llLinksetDataWrite("Somersault-win", "You block %s with a in-air somersault.");
    llLinksetDataWrite("Somersault-loss", "%s blocks your attack with a in-air somersault.");
    llLinksetDataWrite("Suplex-win", "You get %s in a suplex.");
    llLinksetDataWrite("Suplex-loss", "%s gets you in a suplex.");
    llLinksetDataWrite("Uppercut-win", "You hit %s with an uppercut, lifting them in the air before they crash to the ground.");
    llLinksetDataWrite("Uppercut-loss", "%s hits you with an uppercut, lifting you in the air before you crash to the ground.");
    llLinksetDataWrite("Turn Kick-win", "You kick %s's legs out and they fall to the ground.");
    llLinksetDataWrite("Turn Kick-loss", "%s kick your legs out from under you.");
    llLinksetDataWrite("Push Kick-win", "You jump-kick %s, pushing them back.");
    llLinksetDataWrite("Push Kick-loss", "%s jump-kicks you, pushing you back.");
    llLinksetDataWrite("Kickout-win", "%s attacks and you kick them away.");
    llLinksetDataWrite("Kickout-loss", "You attack %s and they kick you away.");
    llLinksetDataWrite("Jump Kick-win", "You attack %s with a series of explosive kicks.");
    llLinksetDataWrite("Jump Kick-loss", "%s attacks you with a series of explosive kicks.");
    llLinksetDataWrite("Head Kick-win", "You turn and reverse-kick %s in the head.");
    llLinksetDataWrite("Head Kick-loss", "%s turns and reverse-kicks you in the head.");
    llLinksetDataWrite("Punch Flip-win", "You hit %s with multiple punchs and backflip avoiding their counter-attack.");
    llLinksetDataWrite("Punch Flip-loss", "%s hits you with multiple punches and avoids your counter-attack with a back flip.");
    llLinksetDataWrite("Ready-win", "You approach %s confident in your victory.");
    llLinksetDataWrite("Ready-loss", "%s approachs you as you realize their size and power.");
    llLinksetDataWrite("Abs-win", "You stand amused as %s ineffectually pound your hard abs.");
    llLinksetDataWrite("Abs-loss", "You punch %s hard abs with no effect as they stand tall gloating.");
    llLinksetDataWrite("Arm Block-win", "You successfully block %s's attack with your arm.");
    llLinksetDataWrite("Arm Block-loss", "%s blocks your attack with their arms.");
    llLinksetDataWrite("Punch Elbow-win", "You thrust your elbow into %s neck and chin.");
    llLinksetDataWrite("Punch Elbow-loss", "%s thrusts their elbow into your neck and chin.");
    llLinksetDataWrite("One Two-win", "You attack %s wth a surpise one-two punch.");
    llLinksetDataWrite("One Two-loss", "%s surprises you with a one-two punch.");
    llLinksetDataWrite("Standoff-win", "You approach %s confident in your victory.");
    llLinksetDataWrite("Standoff-loss", "%s approachs you as you realize their size and power.");
    llLinksetDataWrite("Contempt-win", "You punch %s with contempt.");
    llLinksetDataWrite("Contempt-loss", "%s punches you hard, showing their contempt for you.");
    llLinksetDataWrite("Block Hit-win", "You block %s's attack.");
    llLinksetDataWrite("Block Hit-loss", "%s blocks your attack.");
    llLinksetDataWrite("Snap Kick-win", "Using the strength in your legs, you attack %s with a series of forward and reverse kicks.");
    llLinksetDataWrite("Snap Kick-loss", "Using the strength in their legs, %s attacks you with a series of forward and reverse kicks.");
    llLinksetDataWrite("Side Kick-win", "You kicks your powerful leg into %s side.");
    llLinksetDataWrite("Side Kick-loss", "%s kicks their powerful leg into your side.");
    llLinksetDataWrite("Double Kick-win", "You and %s engage in a kick fight.");
    llLinksetDataWrite("Double Kick-loss", "%s and you engage in a kick fight.");
    llLinksetDataWrite("Throw Kick-win", "You spin around and kick %s's legs out.");
    llLinksetDataWrite("Throw Kick-loss", "%s spins around and kicks your legs out.");
    llLinksetDataWrite("Neck-win", "You lift %s off the ground with a single hand, holding them by the neck.");
    llLinksetDataWrite("Neck-loss", "%s lifts you by the neck off the ground with a single hand ");
    llLinksetDataWrite("Head Grab-win", "You force %s head into your bicep, trapping it there by flexing.");
    llLinksetDataWrite("Head Grab-loss", "%s forces your head into their bicep trapping it there.");
    llLinksetDataWrite("Back Scissor-win", "You flip %s horizontally on your back, wrap your arms, and trap them in a back-scissor hold.");
    llLinksetDataWrite("Back Scissor-loss", "%s flips you horizontally onto their back, and traps you in a scissor hold with their powerful arms.");
    llLinksetDataWrite("Pecs Scissor-win", "You push %s to the ground and force his face between your pecs as you flex, trapping them there.");
    llLinksetDataWrite("Pecs Scissor-loss", "You are pushed to the ground, your face trapped between %s's pecs.");
    llLinksetDataWrite("Leg Scissor-win", "You push %s to the ground and force his face between your legs as you flex, trapping them there.");
    llLinksetDataWrite("Leg Scissor-loss", "You are pushed to the ground, your face trapped between %s's legs as they flex.");
    llLinksetDataWrite("Defeated-win", "%s sits defeated on the ground as you stand victorious over him.");
    llLinksetDataWrite("Defeated-loss", "%s stands victorious over you as you sit defeated.");
    llLinksetDataWrite("ArmW1-win", "%s grabs your immoveable hand.  They apply more and more force, eventually using two hands.  Finally you get bored and quickly push their arm down with such force you toss them into the air then the ground.");
    llLinksetDataWrite("ArmW1-loss", "You grab %s's immoveable hand.  You apply more and more force, eventually using two hands.  Finally they get bored and easilty flip your arms down, tossing you like a ragdoll into the ground.");
    llLinksetDataWrite("ArmW3-win", "%s grabs your immoveable hand.  They apply more and more force, eventually using two hands.  Finally you get bored and quickly push their arm down with such force you toss them into the air then the ground.");
    llLinksetDataWrite("ArmW3-loss", "You grab %s's immoveable hand.  You apply more and more force, eventually using two hands.  Finally they get bored and easilty flip your arms down, tossing you like a ragdoll into the ground.");
    llLinksetDataWrite("ArmW2-win", "%s grabs your immoveable hand.  They apply more and more force, eventually using two hands.  Finally you get bored and quickly push their arm down with such force you toss them into the air then the ground.");
    llLinksetDataWrite("ArmW2-loss", "You grab %s's immoveable hand.  You apply more and more force, eventually using two hands.  Finally they get bored and easilty flip your arms down, tossing you like a ragdoll into the ground.");    
    llLinksetDataWrite("PU1-win", "%s climbs on your back as you do push-ups.");
    llLinksetDataWrite("PU2-win", "%s climbs on your back as you do push-ups.");
    llLinksetDataWrite("PU1-loss", "You climb on %s back as they do push-ups.");
    llLinksetDataWrite("PU2-loss", "You climb on %s back as they do push-ups.");
    llLinksetDataWrite("HBP1-win", "You lift %s  and lay on your back to bench press them.");
    llLinksetDataWrite("HBP2-win", "You lift %s  and lay on your back to bench press them.");
    llLinksetDataWrite("HBP1-loss", "%s starts  to bench press you.");
    llLinksetDataWrite("HBP2-loss", "%s starts  to bench press you.");
    llLinksetDataWrite("HOP1-win", "You lift %s  overhead and press them.");
    llLinksetDataWrite("HOP2-win", "You lift %s  overhead and press them.");
    llLinksetDataWrite("HOP1-loss", "%s lifts you overhead and presses you.");
    llLinksetDataWrite("HOP2-loss", "%s lifts you overhead and presses you.");
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
	integer seq = !in_sequence;
	PEEK(temp);
	integer flags = afCache | afStopAll;
	if (temp == "SEQUENCE") {
	  in_sequence = TRUE;
	  POP(temp);
	  PEEK(temp);
	  PUSH("SEQUENCE");
	  if (!seq) {
	    flags = prior_flags;
	    ++sequence_count;
	    if (sequence_count < 10) force_menu = FALSE;
	  } else {
	    sequence_count = 0;
	  }
	} else {
	  in_sequence = FALSE;
	  sequence_count = 0;
	}
	
	llLinksetDataWrite("chat-default","This fight is below me.");
	string avdesc = llLinksetDataRead((string) xyzzy + "-desc");
	if (!in_sequence || seq) {
	  if (llFrand(1.0) <= probability_of_win) {
	    flags = flags | afSwap;
	    wins++;
	    string s = "win-" + (string) ((integer) llFrand(quotes) + 1);
	    if ((llGetTime() - last_chat)  > 15) {
	      string d = llLinksetDataRead(animation+"-win");
	      last_chat = llGetTime();
	      llMessageLinked(LINK_THIS, CHATBOT,
			      "*" + chatString(d) + "*|"  +
			      avdesc + "|" + llLinksetDataRead((string) current_avatar + "-scene")
			      + "|" + chatString(llLinksetDataRead(s)),
			      current_avatar);
	    }
	  } else {
	    string d = llLinksetDataRead(animation+"-loss");
	    losses++;
	    string s = "defeat-" + (string) ((integer) llFrand(quotes) + 1);
	    if ((llGetTime() - last_chat)  > 15) {
	      last_chat = llGetTime();
	      llMessageLinked(LINK_THIS, CHATBOT,
			      "*" + chatString(d) + "*|"  +
			      avdesc + "|" + llLinksetDataRead((string) current_avatar + "-scene")
			      + "|" + chatString(llLinksetDataRead(s)),
			      current_avatar);
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

