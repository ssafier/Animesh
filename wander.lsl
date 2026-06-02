// LSL Script for an Animesh character that wanders within a  region
// and actively dodges obstacles using physics collisions.

#include "include/animesh.h"
#include "include/controlstack.h"

#ifndef STEP
#define STEP 1.4
#endif

vector g_min;
vector g_max;
vector g_scale;

integer g_moving;

string g_animation = "Walk"; 

vector g_home;
vector g_target;
float g_tau;

// Variables for stuck detection
vector g_last_pos;
integer g_stuck_count = 0;
integer g_wedged_count = 0;

integer obstacle() {
  integer hits = 0;
  vector p = llGetPos();
  vector p1 = p;
  vector t = p + <10,0,0>*llGetRot();
  vector t1 = t;
  list r = llCastRay(p, t, [RC_REJECT_TYPES, RC_REJECT_AGENTS]);
  if (llGetListLength(r) > 1) hits = 1;
  p1.z = p.z - (g_scale.z / 2.0);
  t1.z = t.z - (g_scale.z / 2.0);
  r = llCastRay(p1, t1, [RC_REJECT_TYPES, RC_REJECT_AGENTS]);
  if (llGetListLength(r) > 1) hits = hits | 2;  
  p1.z = p.z + (g_scale.z / 2.0);
  t1.z = t.z + (g_scale.z / 2.0);
  r = llCastRay(p1, t1, [RC_REJECT_TYPES, RC_REJECT_AGENTS]);
  if (llGetListLength(r) > 1) hits = hits | 4;
  return hits;
}

// Picks a random waypoint within the square region relative to the home position
pick_new_target() {
  vector s = g_max - g_min;
  float x = llFrand(s.x) - (s.x / 2.0);
  float y = llFrand(s.y) - (s.y / 2.0);
    
  g_target = g_home + <x, y, 0>;
  g_tau = llVecDist(llGetPos(), g_target) / STEP;
  move_to_target();
}

// Calculates rotation and terrain height, then applies the physical movement
move_to_target() {
  vector pos = llGetPos();
    
  // 1. Face the target (keeping Z strictly horizontal to stay upright)
  vector dir = llVecNorm(g_target - pos);
  rotation rot = llRotBetween(<1.0, 0.0, 0.0>, <dir.x, dir.y, 0.0>);
  llRotLookAt(rot, 1.0, 0.75);
    
  // 2. Calculate ground height at the target's next step
  vector offset = pos + (<STEP + 0.05, 0, 0> * llGetRot());
  vector down = offset;
  down.z = 1;
  list floor = llCastRay(offset, down, [RC_REJECT_TYPES, RC_REJECT_AGENTS]);
  if (llGetListLength(floor) > 1 && (integer) floor[0] >= 0) {
    vector hit = (vector)floor[1]; // hit is ground
    // 3. Keep the center of the prim safely above ground 
    g_target.z = hit.z + (g_scale.z / 2.0);
  }
  // 4. Move physically to the target (1.0 second tau for smooth acceleration)
  llMoveToTarget(g_target, g_tau); 
}

// --- EVENTS ---
default {
  state_entry() {
    // Set up physical constraints
    llSetStatus(STATUS_PHYSICS, TRUE);
    // CRITICAL: Prevents the physical object from falling over!
    llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y, FALSE);
    g_scale = llGetScale();
    g_moving = FALSE;
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != STOP &&
	chan != WANDER) return;
    GET_CONTROL;
    switch(chan) {
    case STOP: {
      g_moving = FALSE;
      llStopMoveToTarget();
      if (g_animation != "") {
	llStopObjectAnimation(g_animation);
	g_animation = "";
      }
      llSetTimerEvent(0);
      break;
    }
    case WANDER: {
      string temp;
      POP(temp);
      vector p1 = (vector) temp;
      POP(temp);
      vector p2 = (vector) temp;
      g_moving = TRUE;
      POP(g_animation);
      if (p1.x < p2.x) {
	g_min.x = p1.x;
	g_max.x = p2.x;
      } else {
	g_min.x = p2.x;
	g_max.x = p1.x;
      }
      if (p1.y < p2.y) {
	g_min.y = p1.y;
	g_max.y = p2.y;
      } else {
	g_min.y = p2.y;
	g_max.y = p1.y;
      }
      if (p1.z < p2.z) {
	g_min.z = p1.z;
	g_max.z = p2.z;
      } else {
	g_min.z = p2.z;
	g_max.z = p1.z;
      }
      g_last_pos = llGetPos();
      g_home = (g_min + g_max) / 2.0;
      llStartObjectAnimation(g_animation);
      llStopMoveToTarget();
      pick_new_target();
      // Use a timer to check progress and repath
      llSetTimerEvent(1.0);
      break;
    }
    default:  break;
    }
    NEXT_STATE;
  }
    
  timer() {
    vector pos = llGetPos();
    
    // 1. Stuck Detection (Are we walking into a wall without triggering a collision?)
    if (llVecDist(pos, g_last_pos) < 0.2) {
      //llSay(0, "stuck "+(string) g_stuck_count);
      g_stuck_count++;
      if (g_stuck_count > 3) { // Stuck for ~3 seconds
	g_wedged_count++;
	llStopMoveToTarget();
	if (g_wedged_count > 3) {
	  //llSay(0, "wedged");
	  g_wedged_count = 0;
	  llMoveToTarget(g_home, 0.1);
	}
	pick_new_target();
	g_stuck_count = 0;
	return;
      }
    } else {
      g_wedged_count = g_stuck_count = 0;      
    }
    g_last_pos = pos;

    // 2. Check horizontal distance to target
    float dist = llVecDist(<pos.x, pos.y, 0.0>, <g_target.x, g_target.y, 0.0>);

    if (dist < 1.0) {
      // Reached destination, pick a new spot
      llStopMoveToTarget();
      pick_new_target();
    } else  {
      // Continuously update movement to adapt to terrain slopes
      g_tau = g_tau - 1;
      move_to_target();
    }
  }
    
  collision_start(integer num_detected)  {
    if (!g_moving) return;
    integer hits = obstacle();
    //llSay(0, (string) hits);
    if (hits == 4 || hits == 0) return; // step or floor or nothing
    //llSay(0,(string) hits);
    if (llDetectedType(0) & AGENT) {
      llMessageLinked(LINK_THIS, BUMP, (string) llDetectedPos(0), llDetectedKey(0));
    } else {
      if (g_stuck_count > 3) g_wedged_count = g_stuck_count = 0; 
      llStopMoveToTarget();
      pick_new_target();
    }
  }
}
