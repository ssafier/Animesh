#include "include/animesh.h"

#define WP_ONE "<182.06000, 9.59519, 2202.04900>"
#define WP_TWO "<150.20890, 85.36724, 2202.04900>"
#define START WP_ONE + "|" + WP_TWO + "|"

integer g_running;
list poses;
integer pindex;
string animation;

integer handle;

default {
  state_entry() {
    g_running = FALSE;
    poses = ["GET HAMPTED (Mens Physique) Stand Pose 1", 14.29,
	     "GET HAMPTED (Mens Physique) Stand Pose 2",10.29,
	     "GET HAMPTED (Mens Physique) Stand Pose 3",10.29,
	     "GET HAMPTED (Mens Physique) Stand Pose 4", 10.71,
	     "GET HAMPTED (Mens Physique) Stand Pose 5",14.29,
	     "GET HAMPTED (Mens Physique) Stand Pose 6",18.54,
	     "GET HAMPTED (Mens Physique) Stand Pose 7",20.0,
	     "GET HAMPTED (Mens Physique) Stand Pose 8",20.83,
	     "Jeff Hampton Posing Routine 1 MR OLYMPIA",60.0,
	     "Jeff Hampton Posing Routine 2 MR OLYMPIA",19.25,
	     "Jeff Hampton Posing Routine 3 MR OLYMPIA",58.33,
	     "Jeff Hampton Posing Routine 4 MR OLYMPIA",50.0
	     ];
    pindex = 0;
    animation = "";
    handle = llListen(0,"", NULL_KEY, "");
  }
  listen(integer chan,string name, key xyzzy, string msg) {
    if (llSubStringIndex(msg = llToLower(msg),"tiny") != 0) return;
    switch (llGetSubString(msg,5,-1)) {
    case "pose": {
      llSetTimerEvent(0.1);
      break;
    }
    case "stop": {
      if (animation != "") {
	llStopObjectAnimation(animation);
	animation = "";
      }
      llSetTimerEvent(0);
      break;
    }
    default: break;
    }
  }

  timer() {
    llSetTimerEvent(0);
    if (pindex >= llGetListLength(poses)) pindex = 0;
    if (animation != "") llStopObjectAnimation(animation);
    llStartObjectAnimation(animation =(string) poses[pindex]);
    llSetTimerEvent((float) poses[pindex + 1]);
    pindex += 2;
  }
}
