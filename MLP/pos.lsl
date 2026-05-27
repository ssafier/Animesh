// MLPV2 Version 2, by Learjeff Innis, based on
//MLP MULTI-LOVE-POSE V1.2 - Copyright (c) 2006, by Miffy Fluffy (BSD License)

#define MAX_BALLS  6

integer ch;
integer swap;
integer BallCount;

list    BallOrder;

integer Zoffset;

vector  RefPos;
rotation RefRot;

getRefPos() {   //reference position
  RefPos = llGetPos();
  RefRot = llGetRot();
  Zoffset = (integer)llGetObjectDesc();
  RefPos.z += (float) Zoffset / 100.;
  llMessageLinked(LINK_THIS,8,(string)RefPos,(string)RefRot);   //send reference position to pose
}

list Pdata;

getPosNew(string pdata) {
  Pdata = llParseString2List(pdata, [" "],[]);
}

setPos() {
  integer ix;
  integer ballIx;
  string pr;
  vector t;
  for (ix = 0; ix < BallCount; ++ix) {
    if (((integer) (string) BallOrder[ix]) == 0) {
      pr = (string)((t = (vector)llList2String(Pdata, 2*ix)) * RefRot + RefPos)
	+ (string)(llEuler2Rot((vector)llList2String(Pdata, 2*ix + 1) * DEG_TO_RAD) * RefRot *llEuler2Rot(<0,0,90>* DEG_TO_RAD));
      ballIx = (integer)llList2String(BallOrder, ix);
      llSay(ch + ballIx, pr);
    }
  }
  for (ix = 0; ix < BallCount; ++ix) {
    if (((integer) (string) BallOrder[ix]) != 0) {
      pr = (string)((vector)llList2String(Pdata, 2*ix) - t)
	+ (string)(llEuler2Rot((vector)llList2String(Pdata, 2*ix + 1) * DEG_TO_RAD) * RefRot *llEuler2Rot(<0,0,90>* DEG_TO_RAD));
      ballIx = (integer)llList2String(BallOrder, ix);
      llSay(ch + ballIx, pr);
    }
  }
}

getChan() {
  ch = (integer)("0x"+llGetSubString((string)llGetKey(),-4,-1));          //fixed channel for prim
}

default {
  state_entry() {
    getRefPos();
    getChan();
    BallOrder = [ "0", "1", "2", "3", "4", "5"];
  }

  on_rez(integer arg) {
    getRefPos();
    getChan();
  }
 
  link_message(integer from, integer num, string cmd, key pkey) {
    if (cmd == "PRIMTOUCH"){
      return;
    }

    if (num == 1 && cmd == "STOP") {
      swap = 0;
      return;
    }

    if (num) return;

    if (cmd == "POSE") {
      list parms = llCSV2List((string)pkey);
      BallCount = llList2Integer(parms,1);
      return;
    } else if (cmd == "POSEPOS") {
      // p = (integer)((string)pkey
      // BallOrder = [ 0, 1, 2, 3, 4, 5 ];
      getPosNew((string)pkey);
      // setPos();
    } else if (cmd == "ORDER") {
      BallOrder = llParseString2List((string)pkey, [" "], []);
      setPos();
    } else if (cmd == "REPOS") {
      getRefPos();
    } else if (llGetSubString(cmd, 0, 0) == "Z") {
      integer change = (integer)llGetSubString(cmd, 1, -1);
      Zoffset += change;
      RefPos.z += (float)change/100.;
      setPos();
      llOwnerSay("Height Adjustment: change by " + (string) change + "cm, new offset: " + (string)Zoffset + "cm");
      llSetObjectDesc((string)Zoffset);
    } else if (cmd == "GETREFPOS") {
      llMessageLinked(LINK_THIS,8,(string)RefPos,(string)RefRot);   //send reference position to pose
    }
  }
}
