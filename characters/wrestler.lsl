#include "include/animesh.h"
#include "include/controlstack.h"
#include "src/animesh/include/eye-of-ekron.h"

#define log(x) debug(x)
#ifndef debug
#define debug(x)
#endif

string currentAnimation;
string pastAnimation;
string targetAnimation;
string pastTargetAnim;
key target_avi  = NULL_KEY;
integer target_strength;
vector size;

vector  SitTarget       = <0.,0.,.1>;   // Change this to <0.,0.,-.15> or lower, to raise balls above cushion
vector  SitTargetRef    = <0.,0.,.1>;   // Don't change this, unless you're replacing earlier versions
                                        // with a custom SitTarget.  In that case, set to match SitTarget.

integer ADJUSTABLE  = FALSE;
float   DELTA       = 0.01;        // cm to move
float   EPSILON     = 0.005;       // cm position error tolerance, should be about half delta
vector  Offset;
vector  BallPos;
vector BallRelPos;
rotation BallRot;

#define NullKey NULL_KEY

integer Chan;
integer Group;
integer Adjusting;
key     Avatar;
string  Name;
integer ListenHandle;
integer UserHandle;

integer ExprEnabled = TRUE;
string  Expression;
float   ExprTimer;

list Expressions = [
      ""
    , "express_open_mouth"          // 1
    , "express_surprise_emote"      // 2
    , "express_tongue_out"          // 3
    , "express_smile"               // 4
    , "express_toothsmile"          // 5
    , "express_wink_emote"          // 6
    , "express_cry_emote"           // 7
    , "express_kiss"                // 8
    , "express_laugh_emote"         // 9
    , "express_disdain"             // 10
    , "express_repulsed_emote"      // 11
    , "express_anger_emote"         // 12
    , "express_bored_emote"         // 13
    , "express_sad_emote"           // 14
    , "express_embarrassed_emote"   // 15
    , "express_frown"               // 16
    , "express_shrug_emote"         // 17
    , "express_afraid_emote"        // 18
    , "express_worry_emote"         // 19
    , "SLEEP"                       // 20
    , "RANDOM"                      // 21
];

string RandomExpression;

list RandomExpressions = [
      ""
    , "express_open_mouth"
    , "express_open_mouth"
    , "express_open_mouth"
    , "express_surprise_emote"
    , "express_surprise_emote"
    , "express_surprise_emote"
    , "express_smile"
    , "express_cry_emote"
    , "express_kiss"
    , "express_kiss"
    , "express_laugh_emote"
    ];


float last_chat;
integer wins;
integer losses;
string last_hold;

string chatString(string s) {
  integer idx = llSubStringIndex(s, "%s");
  if (idx == -1) return s;
  if (idx == 0) {
    return llGetDisplayName(target_avi) + llGetSubString(s, 2, -1);
  } else if (idx == llStringLength(s)) {
    return llGetSubString(s,0,-3) + llGetDisplayName(target_avi);
  }
  return llGetSubString(s,0,idx-1) +
    llGetDisplayName(target_avi) +
    llGetSubString(s, idx + 2, -1);
}

AIChat(string d, string s) {
  last_chat = llGetTime();
  string avdesc = llLinksetDataRead((string) target_avi + "-desc");
  string text = "You are wrestling.";
  if (wins > 0 || losses > 0) {
    text = text + "  You have won " + (string) wins + " holds and lost "+ (string) losses + ".";
  }
  llMessageLinked(LINK_THIS, CHATBOT,
		  "*" + chatString(d) + "*|"  +
		  avdesc + "|" + chatString(text) + "|" + chatString(s),
		  target_avi);
}

// Animation names with a "*" suffix get open mouth
// Those with a suffix of "::" followed by a number
//   get the expression associated with that number.
//   This can optionally be followed by another "::" delim,
//   with a timer value following.

string getExpression(string anim) {
  if (llGetSubString(anim,-1,-1) == "*") {
    Expression = (string) Expressions[1];
    ExprTimer = 0.5;
    return llGetSubString(anim, 0, -2);
  }
  integer ix = llSubStringIndex(anim, "::");
  if (ix == -1) {
    Expression = "";
    ExprTimer = 0.5;
    return anim;
  }
  list parms = llParseString2List(anim, ["::"], []);
  anim = (string) parms[0];
  integer exprIx = (integer) parms[1];
  Expression = (string) Expressions[exprIx];
  ExprTimer  = (float) parms[2];

  if (ExprTimer <= 0.0) {
    ExprTimer = 0.5;
  }
  
  return anim;
}

integer parseAnimationData(list data) {
  integer me = (integer) (string) data[0];
  integer m = (integer) (string) data[1];
  string a1 = (string) data[2];
  integer n =  (integer) (string) data[3];
  string a2 = (string) data[4];
  pastTargetAnim = targetAnimation;
  pastAnimation = currentAnimation;
  integer x;
  if (me == m) {
    targetAnimation = getExpression(a2);
    last_hold = currentAnimation = getExpression(a1);
  } else {
    targetAnimation = getExpression(a1);
    last_hold = currentAnimation = getExpression(a2);
  }
  return (me == m);
}

default {
  state_entry() {
    // Set up physical constraints
    llSetStatus(STATUS_PHYSICS, TRUE);
    // CRITICAL: Prevents the physical object from falling over!
    llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y, FALSE);

    list l = llGetBoundingBox(llGetKey());
    size = (vector) l[1] - (vector) l[0];
    size.z = 0;

    Name = llGetObjectDesc();
    Avatar = llGetKey();
    Chan = -10101;
    Group = 0;
        
    if (ListenHandle) {
      llListenRemove(ListenHandle);
      ListenHandle = 0;
    }

    log(Chan);
    if (Chan != 0) {
      ListenHandle = llListen(Chan,"",NullKey,"");
      // start timer unless ball was dragged from inv
    }
    UserHandle = llListen(BroadcastChannel, "", EyeOfEkron, "");
    currentAnimation = "Default";
    llStartObjectAnimation(currentAnimation);
  }

  state_exit() {
    llSetTimerEvent(0);
    llListenRemove(UserHandle);
    if (ListenHandle) {
      llListenRemove(ListenHandle);
      ListenHandle = 0;
    }
  }

  listen(integer channel, string name, key object, string str) {
    if (channel == BroadcastChannel) {
      if (object != EyeOfEkron) return;
      list temp = llParseString2List(str,["|"],[]);
      if (llGetObjectName() != (string) temp[3]) return;
      key avatar = (key) (string) temp[1];
      string called = llGetDisplayName(avatar);
      string animesh = (string) temp[2];
      llSleep(5 + llFrand(3.5));
      llMessageLinked(LINK_THIS, CHATBOT,
		      "*A gym-rat " + called + " and " + animesh +
		      " enter the gym.  You challenge one or both to wrestle *|"  +
		      called + " is a gym rat looking to build muscle|[" + animesh +
		      "] to ["+ called +
		      "]" + llGetObjectName() + " is in the wrestling ring again.|Wanna wrestle?",
		      avatar);
    }

    list l = llParseString2List(str, ["|"],[]);
    if ((string) l[0] == "wrestler" && (string) l[1] == "1") {
      llListenRemove(ListenHandle);
      Chan = (integer) (string)l[2];
      state get_target;
    }
  }
}

state get_target {
  state_entry() {
    llSetStatus(STATUS_PHYSICS, TRUE);
    // CRITICAL: Prevents the physical object from falling over!
    llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y, FALSE);
    ListenHandle = llListen(Chan,"",NullKey,"");
    BallRelPos = ZERO_VECTOR;
    llSetTimerEvent(60);
  }
  listen(integer channel, string name, key object, string str) {
    integer ix;
    ix = llSubStringIndex(str,">");    
    if (ix != -1) {
      BallRelPos = (vector)llGetSubString(str,0,ix);
      BallRot = (rotation)llGetSubString(str,ix+1,-1);
      vector posOffset = <0.45, 0.6, 0.0>;
      BallRot = llEuler2Rot(<0,0,240>)*BallRot;
    } else {
      list ldata = llParseString2List(str, ["|"], []);
      switch ((string) ldata[0] ) {
      case "ANIMATE": {
	parseAnimationData(llList2List(ldata, 1, -1));
	break;
      }
      case "SITTER": {
	if ((target_avi = (key)(string)ldata[1]) != NULL_KEY) {
	  llListenRemove(ListenHandle);
	  llSetTimerEvent(0);
	  llLinksetDataWrite("strength", (string) MY_STRENGTH);
	  llMessageLinked(LINK_THIS, GET_STRENGTH, (string) RETURN_MAX_STRENGTH + "|", target_avi);
	}
	break;
      }
      default: break;
      }
    }
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != RETURN_MAX_STRENGTH) return;
    GET_CONTROL;
    string temp;
    POP(temp);
    target_strength = (integer) temp;
    float prob = ProbabilityWin(target_strength, MY_STRENGTH);
    llSay(Chan+8,"PROB|"+(string) prob);
    list intro;
    if (prob < 0.1) {
      intro = absolute;
    } else if (prob > 0.67) {
      intro = weaker;
    } else {
      intro = equal;
    }
    AIChat("%s confidential approaches you and accepts your challenge.",
	   "A challenger.");
    state wrestling;
  }
  timer() {
    llSay(0, "Guess not.");
    llSetTimerEvent(0);
    state default;
  }
}

state wrestling {
  state_entry() {
    //llSay(0,"wrestling");
    ListenHandle = llListen(Chan,"",NullKey,"");
    UserHandle = llListen(0, "", target_avi, "");
    llSetStatus(STATUS_PHYSICS, FALSE);
    if (BallRelPos != ZERO_VECTOR) {
      llSleep(0.5);
      list g_target = llGetObjectDetails(target_avi,[OBJECT_POS]);
      vector as = llGetAgentSize(target_avi);
      as.z = 0;
      vector dir = llVecNorm((vector) g_target[0] - llGetPos());
      rotation rot = llRotBetween(<1.0, 0.0, 0.0>, <dir.x, dir.y, 0.0>);
      //      llSay(0,(string)llRot2Euler(rot)+" "+(string)llRot2Euler(BallRot));
      BallPos = (vector) g_target[0] + BallRelPos + (((size / 2) + (as / 2) + <0.005,0,0>)  * rot);
      BallRot = rot;
      llRequestExperiencePermissions(target_avi, "");
    }
  }
  experience_permissions(key avi) {
    llSetPos(BallPos);
    llRotLookAt(BallRot, 1.0, 0.75);
    llStopAnimation(pastTargetAnim);
    llStopObjectAnimation(pastAnimation);
    llStartAnimation(targetAnimation);
    llStartObjectAnimation(currentAnimation);
    //llSetTimerEvent(1);
  }
  experience_permissions_denied(key avi, integer reason) {
    state default;
  }
  
  listen(integer channel, string name, key object, string str) {
    if (channel == 0 && object == target_avi) {
      AIChat("[" + llGetDisplayName(target_avi) + "] " + str, "Ok");
      return;
    }
    integer ix;
    // llSay(0,str);
    ix = llSubStringIndex(str,">");    
    if (ix != -1) {
      BallRelPos = (vector)llGetSubString(str,0,ix);
      BallRot = (rotation)llGetSubString(str,ix+1,-1);
      //      vector posOffset = <0.45, 0.6, 0.0>;
      //      vector target = BallPos + posOffset;
      //      target = target * BallRot;
      llSetTimerEvent(0);
      llSleep(0.5); // let avatar finish moving

      list g_target = llGetObjectDetails(target_avi,[OBJECT_POS]);
      vector as = llGetAgentSize(target_avi);
      as.z = 0;
      vector dir = llVecNorm((vector) g_target[0] - llGetPos());
      rotation rot = llRotBetween(<1.0, 0.0, 0.0>, <dir.x, dir.y, 0.0>);
      //      llSay(0,(string)llRot2Euler(rot)+" "+(string)llRot2Euler(BallRot));
      BallPos = (vector) g_target[0] + BallRelPos;
      llSetPos(BallPos);
      llRotLookAt(BallRot, 1.0, 0.75);
      //      llSetTimerEvent(1);
      //llRotLookAt(BallRot,1.0,0.75);
    } else if (str == "0") {    //HIDE
      // hide();
    } else if (str == "SHOW") { //SHOW
      // show();
    } else if (str == "ADJUST|1") {
      Adjusting = TRUE;
    } else if (str == "ADJUST|0") {
      Adjusting = FALSE;
    } else if (str == "SAVE") {
      llSay(Chan+16,(string)(llGetPos() + SitTarget - SitTargetRef)+(string)llGetRot());
    } else if (str == "GROUP") {
      Group = 1;
    } else if (str == "ALL") {
      Group = 0;
    } else if (str == "DIE") {
      llSay(Chan+8, (string)NullKey);    //msg to poser (don't reanimate after STOP)
      AIChat("["+llGetDisplayName(target_avi)+"]"+" leave the ring.", "Bye");
      llStopObjectAnimation(currentAnimation);
      state default;
    } else if (str == "LIVE") {
      // llSay(Chan+8,"ALIVE");    //msg to poser -> to menu
    } else {
      list ldata = llParseString2List(str, ["|"], []);
      switch ((string) ldata[0] ) {
      case "SAY": {
	string chat;
	if (((integer) (string) ldata[1]) == TRUE) {
	  chat = "You have won the " + last_hold + " against %s";
	  wins++;
	} else {
	  chat = "You have lost the " + last_hold + " to %s.";
	  losses++;
	}
	AIChat(chat, chat);
	break;
      }
      case "ANIMATE": {
	integer win = parseAnimationData(llList2List(ldata, 1, -1));
	llStopAnimation(pastTargetAnim);
	llStopObjectAnimation(pastAnimation);
	llStartAnimation(targetAnimation);
	llStartObjectAnimation(currentAnimation);
	break;
      }
      case "SITTER": {
	key new_target = (key)(string)ldata[1];
	if (target_avi != new_target && new_target == NULL_KEY) {
	  AIChat("["+llGetDisplayName(target_avi)+"]"+" leave the ring.", "Bye");
	  target_avi = NULL_KEY;
	  target_strength = 0;
	  llListenRemove(ListenHandle);
	  llStopObjectAnimation(currentAnimation);
	  llSetTimerEvent(0);
	  state default;
	}
	break;
      }
      default: {
	string ballIx = llList2String(ldata,1);
	Adjusting = (integer) llList2String(ldata,2);
	break;
      }
      }
    }
  }

  timer() {
    list g_target = llGetObjectDetails(target_avi,[OBJECT_POS]);
    vector dir = llVecNorm((vector) g_target[0] - llGetPos());
    rotation rot = llRotBetween(<1.0, 0.0, 0.0>, <dir.x, dir.y, 0.0>)  * llEuler2Rot(<0,0,90>*DEG_TO_RAD);
    //    llSay(0,(string)dist);
    llRotLookAt(BallRot = rot, 1.0, 0.75);
  }
}
