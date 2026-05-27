//MPLV2 Version 2.1, Lear Cale, from:
//MLP MULTI-LOVE-POSE V1.2 - Copyright (c) 2006, by Miffy Fluffy (BSD License)

#define MAX_AVS 6

integer a;
integer ch;
integer i;
integer swap;
string pose;

list    BallOrder;

list    PRs;    // pos/rot pairs for Save

list anims;     // strided list of anims, indexed by pose*6
vector pos = <-1.,-1.,-1>;
rotation rot;
integer BallCount;      // number of balls
integer UpdateCount;    // number of balls we've heard from, for save

string prStr(string str) {
  i = llSubStringIndex(str,">");
  vector p = ((vector)llGetSubString(str,0,i) - pos) / rot;
  vector r = llRot2Euler((rotation)llGetSubString(str,i+1,-1) / rot)*RAD_TO_DEG;
  return "<"+round(p.x, 3)+","+round(p.y, 3)+","+round(p.z, 3)+"> <"+round(r.x, 1)+","+round(r.y, 1)+","+round(r.z, 1)+">";
}

string round(float number, integer places) {
  float shifted;
  integer rounded;

  shifted = number * llPow(10.0,(float)places);
  rounded = llRound(shifted);
  string str = (string)((float)rounded / llPow(10.0, (float)places));
  str = llGetSubString(str,0,llSubStringIndex(str, ".") + places);
    
  // remove trailing zeros
  string lastdig;
  while ((lastdig = llGetSubString(str, -1, -1)) == "0") {
    str = llGetSubString(str, 0, -2);
  }
  return str;
}

check_anim(string aname) {
  if (aname == "") {
    return;
  }
  if (   aname != "PINK"
	 && aname != "BLUE"
	 && aname != "stand"
	 && aname != "sit_ground") {

    // ignore expression suffix of "*" or "::nnn"
    if (llGetSubString(aname, -1, -1) == "*") {
      aname = llGetSubString(aname, 0, -2);
    } else {
      integer ix = llSubStringIndex(aname, "::");
      if (ix != -1) {
	aname = llGetSubString(aname, 0, ix-1);
      }
    }
  }
}

getChan() {
  ch = (integer)("0x"+llGetSubString((string)llGetKey(),-4,-1));  //fixed channel for prim
}

set_anims(integer startIx) {
  integer ix;
  integer ballIx;
  string an;
  string saystr = "";
  for (ix = 0; ix < BallCount; ++ix) {
    integer ballIx = (integer)llList2String(BallOrder, ix);
    an = llList2String(anims, startIx + ix);
    // Modification: pass this to the animesh which then handles the animations.
    saystr = saystr + "|" + (string) ix + "|" + an;
    //llMessageLinked(LINK_THIS,ch + ballIx, an,(key)"");   //msg to poser*
  }
  saystr = (string) BallOrder[1] + saystr;
  llSay(ch + 1, "ANIMATE|" + saystr);
}

integer orig_ball_index(integer ix) {
  // ix is actual ball index.
  // but balls may be swapped, and we want to save as original ball number
  // need to do inverse transform of BallOrder

  integer jx;
  for (jx = 0; jx < llGetListLength(BallOrder); ++jx) {
    if ((integer)llList2String(BallOrder, jx) == ix) {
      return(jx);
    }
  }
  llSay(0, "ERROR: Can't find ball index "
        + (string) ix
        + " in "
        + llList2CSV(BallOrder)
        + ".  .SWAP config probably incorrrect.  Don't save results to notecard.");
  return ix;
}

default {

  link_message(integer from, integer num, string data, key id) {
    if (num != 9+a) return;

    if (data == "LOADED") state on;
        
    list ldata = llParseString2List(data,["  |  ","  | "," |  "," | "," |","| ","|"],[]);
        
    integer ix;
    string  an;
        
    for (ix = 0; ix < MAX_AVS; ++ix) {
      an = llList2String(ldata, ix + 1);

      if (a > 1) {
	check_anim(an);
      } else if (a) { //pose1: set default
	if (an == "") an = "sit_ground";
      } else {        //pose0: set stand
	if (an == "") an = "stand";
      }
      anims += an;
    }
    ++a;
  }
  state_exit() {
    llOwnerSay((string)a+" poses loaded ("+llGetScriptName()+": "+(string)llGetFreeMemory()+" bytes free)");
  }
}


state on {
  state_entry() {
    getChan();
    BallOrder = [ "0", "1", "2", "3", "4", "5"];
  }
    
  on_rez(integer arg) {
    getChan();
  }

  link_message(integer from, integer num, string cmd, key akey) {
    if (num == -3031963) {
      list l = llParseString2List(cmd,[" "],[]);
      llSay(ch + 1, "SAY|" + (string) (((integer)(string)l[1]) == 0));
      return;
    }
    if (cmd == "PRIMTOUCH"){
      return;
    }

    if (num == 8) {
      pos = (vector)cmd;                   //revtrieve reference position from pos
      rot = (rotation)((string)akey);
      return;
    }

    if (num) return;

    if (cmd == "POSE") {
      list parms = llCSV2List((string)akey);
      BallCount = llList2Integer(parms,1);
      a = llList2Integer(parms,0) * 6;
      //llOwnerSay("Pose set anims");
      set_anims(a);
    } else if (cmd == "ORDER") {
      BallOrder = llParseString2List((string)akey, [" "], []);
      //llOwnerSay("Order set anims");
      set_anims(a);
    } else if (cmd == "SAVE") {
      pose = (string)akey;
      state save;
    }
  }
}

state save {
  state_entry() {
    // llMessageLinked(LINK_THIS,0,"GETREFPOS","");    //msg to pos: ask ref position
    // llSleep(0.5);
    integer ix;
    PRs = [ "", "", "", "", "", "" ];

    for (ix = 0; ix < MAX_AVS; ++ix) {
      llListen(ch+16+ix,  "", NULL_KEY, "");
      llSay(ch+ix,"SAVE");       //msg to balls
    }
    llSetTimerEvent(10.);
    UpdateCount = 0;
  }


  listen(integer channel, string name, key id, string pr) {
    integer ix = channel - (ch + 16);       // get actual ball number
    integer ballIx = orig_ball_index(ix);
        
    // This shouldn't be possible, now that ~pos sends an '8' in getRefPos
    if (pos.x == -1.) {
      llSleep(3.);
      llOwnerSay("Internal error, aborting save.  Try again");
      state on;
      return;
    }
        
    PRs = llListReplaceList(PRs, (list)pr, ballIx, ballIx);

    if (++UpdateCount == BallCount) {
      pr = "";
      integer ix;
      for (ix = 0; ix < BallCount; ++ix) {
	pr += prStr(llList2String(PRs, ix)) + " ";
      }                    

      //llOwnerSay("{"+pose+"} " + pr);
      llMessageLinked(LINK_THIS, 1, pose, pr);       //write to memory
      state on;
    }
  }

  link_message(integer from, integer num, string posstr, key rotkey) {
    if (posstr == "PRIMTOUCH"){
      return;
    }
    if (num != 8) return;
    pos = (vector)posstr;                   //revtrieve reference position from pos
    rot = (rotation)((string)rotkey);
  }

  timer() {
    llOwnerSay("Timeout: save failed.  Try again");
    state on;
  }

  state_exit() {
    llSetTimerEvent(0);
  }   
}

