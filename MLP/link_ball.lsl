// MLPV2 Version 2 by Learjeff Innis.  Based on
// MLP MULTI-LOVE-POSE V1.2 - Copyright (c) 2006, by Miffy Fluffy (BSD License)

// To make ball phantom, put "*" as the first character in the ball's description
// or just make the ball phantom (which really works better for HUDs).
// The rest of the description, if any, is used for the sit pie menu and floating text.
// To make this take effect, use STOP to unrez the balls, and then select any pose.

// v2.4j - cancel old listen on rez
// v2.4m - handle control keys! To enable, begin ~ball description with a plus sign ("+"), following "*" if any.
// v2.4p - page up & down to enable/disable adjustment
// v2.4x - moved SitTarget to top.

#define RELAY_CHANNEL   -1812221819
#define CHANNEL_LOCK_BASE 5759720

#define log(x)
#define debug(x)
//llOwnerSay((string) (x))


vector  SitTarget       = <0.,0.,.1>;   // Change this to <0.,0.,-.15> or lower, to raise balls above cushion
vector  SitTargetRef    = <0.,0.,.1>;   // Don't change this, unless you're replacing earlier versions
                                        // with a custom SitTarget.  In that case, set to match SitTarget.

integer ADJUSTABLE  = FALSE;
float   DELTA       = 0.01;        // cm to move
float   EPSILON     = 0.005;       // cm position error tolerance, should be about half delta
vector  Offset;
vector  BallPos;
rotation BallRot;

#define NullKey NULL_KEY

integer Chan;
integer Group;
integer visible = TRUE;
integer Adjusting;
key     Avatar;
key capturee;
string  Name;
integer ListenHandle;

integer Number;
integer LockHandle;

integer ControlsActive;

// 15 color support, thanks to Liz Silverstein
// Color is passed as a string by object chat (from menu via poser*)
    
list colors = [ <0.0,0.0,0.0>,          // 0 = HIDE
                <0.835,0.345,0.482>,    // 1 = PINK
                <0.353,0.518,0.827>,    // 2 = BLUE
                <0.635,0.145,0.282>,    // 3 = PINK2 - Dark pink
                <0.153,0.318,0.627>,    // 4 = BLUE2 - Dark blue
                <0.128,0.500,0.128>,    // 5 = GREEN
                <1.000,0.000,1.000>,    // 6 = MAGENTA
                <1.000,0.000,0.000>,    // 7 = RED
                <1.000,0.500,0.000>,    // 8 = ORANGE
                <1.000,1.000,1.000>,    // 9 = WHITE
                <0.0,0.0,0.0>,          // 10 = BLACK
                <1.0,1.0,0.0>,          // 11 = YELLOW
                <0.0,0.8,0.8>,          // 12 = CYAN
                <0.5,0.0,0.0>,          // 13 = RED2
                <0.0,0.5,0.5>,          // 14 = TEAL
                <0.0,0.25,0.25>];       // 15 = GREEN2

integer captureTimer = 0;
capture(key avatar)
{
  relay(avatar, "@sit:" + (string) llGetKey() + "=force");
}
 
lock(key avatar)
{
  relay(avatar, "@unsit=n");
}
 
release(key avatar)
{
  relay(avatar, "@unsit=y");
  relay(avatar, "!release");
}
 
// write a message to the RLV Relay
relay(key avatar, string message)
{
  if (avatar != NULL_KEY)
    {
      llRegionSayTo(avatar, RELAY_CHANNEL, llGetObjectName() + "," + (string) avatar + "," + message);
      log("RLV: " + llGetObjectName() + "," + (string) avatar + "," + message);
    }
}

handle_control(key id, integer level, integer change) {
  debug("handle control "+(string)id+" "+(string)level+" "+(string)change);
  if (Avatar == NullKey) {
    return;
  }
    
  if ((level & CONTROL_FWD) && (level & CONTROL_BACK)) {
    ControlsActive = ! ControlsActive;
    if (ControlsActive) {
      control_active();
    } else {
      control_ready();
    }
    return;
  }
    
  if (!ControlsActive) {
    return;
  }


  if (level & CONTROL_UP) {
    Offset.z += DELTA;
  } else if (level & CONTROL_DOWN) {
    Offset.z -= DELTA;
  } else if (level & CONTROL_LEFT) {
    Offset.y += DELTA;
  } else if (level & CONTROL_RIGHT) {
    Offset.y -= DELTA;
  } else if (level & CONTROL_FWD) {
    Offset.x += DELTA;
  } else if (level & CONTROL_BACK) {
    Offset.x -= DELTA;
  } else {
    return;
  }

  llSetPos(BallPos + Offset * BallRot + SitTargetRef - SitTarget);
}

// enter "control ready" state.
control_ready() {
  debug("control ready");
  ControlsActive = 0;
  integer controls = CONTROL_FWD | CONTROL_BACK;

  llTakeControls(controls, TRUE, FALSE);
  llInstantMessage(Avatar, "Allow adjusting your position by pressing FORWARD and BACK keys at the same time");
}

control_active() {
  debug("control active");
  integer controls = CONTROL_UP | CONTROL_DOWN | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_FWD | CONTROL_BACK;

  llTakeControls(controls, TRUE, FALSE);
  llInstantMessage(Avatar, "Adjust your position using Pgup/Pgdn, Up/Down arrow, and shift-left/right arrow keys\nDisable by pressing Pgup and Pgdn keys at the same time");
  BallPos = llGetPos() + SitTarget - SitTargetRef;
  BallRot = llGetRot();
}



render() {
  if (!visible || (Avatar != NullKey && !Adjusting)) {
    // hidden
    llSetScale(<0.01,0.01,0.01>);
    llSetAlpha(0.0, ALL_SIDES);
    llSetText("",<1.0,1.0,1.0>,1.0);    
  } else if (Avatar != NullKey && Adjusting) {
    // sitting and adjusting
    llSetAlpha(0.2,ALL_SIDES);
    llSetText("Adjust",<1.0,1.0,1.0>,1.0);
    llSetScale(<0.1,0.1,5.0>);
  } else {
    // shown
    llSetAlpha(1.0, ALL_SIDES);
    llSetScale(<0.2,0.2,0.2>);
    if (Adjusting) {
      llSetText("Adjust",<1.0,1.0,1.0>,1.0);
    } else {
      llSetText(Name,<1.0,1.0,1.0>,1.0);
    }
  }
}

show() {
  visible = TRUE;
  render();
}

hide() {
  visible = FALSE;
  render();
}

default {
  on_rez(integer channel) {
    Name = llGetObjectDesc();
    if (Name == "" || Name == "(No Description)") {
      Name = "Pose";
    } else {
      if (llSubStringIndex(Name, "*") == 0 && channel != 0) {
	llSetPrimitiveParams([PRIM_PHANTOM, TRUE]);
	Name = llGetSubString(Name, 1, -1);
      }
      if (llSubStringIndex(Name, "+") == 0) {
	ADJUSTABLE = TRUE;
	Name = llGetSubString(Name, 1, -1);
      }
      if (Name == "none") {
	Name = "";
      }
    }
    llSitTarget(SitTarget, ZERO_ROTATION);
    if (Name != "") {
      llSetSitText(Name);
    } else {
      llSetSitText("");
    }
    Avatar = NullKey;
    Chan = channel;
    Group = 0;

    if (ListenHandle) {
      llListenRemove(ListenHandle);
      ListenHandle = 0;
    }

    log(Chan);
    if (Chan != 0) {
      ListenHandle = llListen(Chan,"",NullKey,"");
      // start timer unless ball was dragged from inv
      llSetTimerEvent(180.0);
    }
        
    if (llGetObjectDesc() == "ADJUSTABLE") {
      ADJUSTABLE = TRUE;
    }
  }

  changed(integer change) {
    if (change != CHANGED_LINK) return;
    Avatar = llAvatarOnSitTarget();
    if (Avatar != NullKey) {
      llSetTimerEvent(0);
      captureTimer = 0;
      if (Group) {
	if (!llSameGroup(Avatar)) {
	  llUnSit(Avatar);
	  llWhisper(0,"no permission to use poseball");
	  return;
	}
      }
      if (ADJUSTABLE) {
	llRequestExperiencePermissions(Avatar, "");
      }
    llSay(Chan+8,(string)Avatar);     //requests perm, sets animation
    render();
    } else {
      llSay(Chan+8,(string) NULL_KEY);     //requests perm, sets animation
      show();
    }
  }

  listen(integer channel, string name, key object, string str) {
    integer ix;
    ix = llSubStringIndex(str,">");    
    if (ix != -1) {
      BallPos = (vector)llGetSubString(str,0,ix);
      BallRot = (rotation)llGetSubString(str,ix+1,-1);
      llSetPos(BallPos + Offset + SitTargetRef - SitTarget);
      llSetRot(BallRot);
    } else if (str == "0") {    //HIDE
      hide();
    } else if (str == "SHOW") { //SHOW
      show();
    } else if (str == "ADJUST|1") {
      Adjusting = TRUE;
      render();
    } else if (str == "ADJUST|0") {
      Adjusting = FALSE;
      render();
    } else if (str == "SAVE") {
      llSay(Chan+16,(string)(llGetPos() + SitTarget - SitTargetRef)+(string)llGetRot());
    } else if (str == "GROUP") {
      Group = 1;
    } else if (str == "ALL") {
      Group = 0;
    } else if (str == "DIE") {
      llSay(Chan+8, (string)NullKey);    //msg to poser (don't reanimate after STOP)
      llDie();
    } else if (str == "LIVE") {
      llSetTimerEvent(180.0);
      // llSay(Chan+8,"ALIVE");    //msg to poser -> to menu
    } else if (llSubStringIndex(str, "CAPTURE:") == 0) {
      log("Capture");
      capturee = (key) llGetSubString(str, 8, -1);
      if (capturee == NULL_KEY) return;
      capture(capturee);
      captureTimer = 1;
      llSetTimerEvent(2);
    } else if (llSubStringIndex(str, "FREE:") == 0) {
      log("FREE");
      capturee = (key) llGetSubString(str, 5, -1);
      if (capturee != Avatar) return;
      llUnSit(Avatar);
      Avatar = NULL_KEY;
    } else {
      list ldata = llParseString2List(str, ["|"], []);
      integer colorIx = (integer) llList2String(ldata,0);
      string ballIx = llList2String(ldata,1);
      Adjusting = (integer) llList2String(ldata,2);
      if ((colorIx > 0) && (colorIx < 16)) { // this must be a color setting  
	llSetColor(llList2Vector(colors, colorIx),ALL_SIDES);     //pull the color out of the list
	render();
	llSetObjectName("~ball" + ballIx);
	Number = (integer) ballIx + 1;
	debug("ball listen "+(string)(CHANNEL_LOCK_BASE + Number));
	if (LockHandle) {
	  llListenRemove(LockHandle);
	}
	LockHandle = llListen(CHANNEL_LOCK_BASE + Number, "", NullKey, "");
	BallPos = llGetPos() + SitTarget - SitTargetRef;
	BallRot = llGetRot();
      }
    }
  }

  timer() {                       //not heard "LIVE" from menu for a while: suicide
    if (captureTimer == 0) { llDie(); return; }
    llSetTimerEvent(0);
    captureTimer = 0;
    if (capturee == NULL_KEY || llAvatarOnSitTarget() == capturee) return;
    llRegionSayTo(capturee, -19630303, "656|");
    llSleep(2);
    llRegionSayTo(capturee, -19630303, "657|"+(string) llGetKey());
    llSleep(2);
    llRegionSayTo(capturee, -19630303, "656|");
  }

  experience_permissions(key id)    { 
    if (Avatar != id) return;
    control_ready();
  }

  moving_end() {
    vector newpos = llGetPos() + SitTarget - SitTargetRef;
    if (llVecMag(newpos - (BallPos + Offset)) > EPSILON) {
      // we didn't move it, someone else did.  Deal with it.
      BallPos = newpos;
    }
    BallRot = llGetRot();
  }

  control(key id, integer level, integer change) {
    debug("control "+(string)id+" "+(string)level+" "+(string)change);
    handle_control(id, level, change);
  }
}
