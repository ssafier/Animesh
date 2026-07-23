#include "include/animesh.h"
#ifdef DEBUGGING
#define EyeOfEkron (key) "6456374b-8b39-f398-1233-e4ba1a4a7835"
#else
#define EyeOfEkron (key) "d7313cec-6f94-8ea0-6359-c2ad0b922f52"
#endif

#ifndef STEP
#define STEP 1.6667
#endif

#ifndef debug
#define debug(x)
#endif

integer brain = 0x922f52;
integer channel;
integer handle;

list filters;

integer status;
string animation;
integer running;

key avatar;
string avatar_json;
integer avatar_handle;

integer sml;
integer rp;
string rp_name;
integer sps;

integer is_following;
vector REGION_MIN;
vector REGION_MAX;

vector current_target_pos;  // where I am moving to

vector g_target;
float g_tau;
vector g_scale;
vector home;
integer moving;
integer wander_state;
integer wait_time;
// Variables for stuck detection
vector g_last_pos;
integer g_stuck_count = 0;
integer g_wedged_count = 0;

#ifdef WALK_TIME
clear_animation() {
  if (animation == WALK) {
    llMessageLinked(LINK_THIS, LOOP_WALK, "|0", NULL_KEY);
  }
  if (animation != "") {
    llStopObjectAnimation(animation); animation = "";
  }
}
#define stop_animation() if (animation != "") { llStopObjectAnimation(animation); animation = ""; }
#else
#define clear_animation() if (animation != "") { llStopObjectAnimation(animation); animation = ""; }
#define stop_animation() clear_animation()
#endif

make_region(vector a, vector b) {
  vector min;
  vector max;
  if (a.x < b.x) { min.x = a.x; max.x = b.x; } else { min.x = b.x; max.x = a.x; }
  if (a.y < b.y) { min.y = a.y; max.y = b.y; } else { min.y = b.y; max.y = a.y; }
  if (a.z < b.z) { min.z = a.z; max.z = b.z; } else { min.z = b.z; max.z = a.z; }
  REGION_MIN = min;
  REGION_MAX = max;
}

vector clamp_to_region(vector target, float offset) {
    vector clamped = target;
    if (clamped.x < (REGION_MIN.x - offset)) clamped.x = REGION_MIN.x;
    if (clamped.x > (REGION_MAX.x + offset)) clamped.x = REGION_MAX.x;
    if (clamped.y < (REGION_MIN.y - offset)) clamped.y = REGION_MIN.y;
    if (clamped.y > (REGION_MAX.y + offset)) clamped.y = REGION_MAX.y;
    return clamped;
}

// Picks a random waypoint within the square region relative to the home position
pick_new_target() {
    float rx = llFrand(REGION_MAX.x - REGION_MIN.x) + REGION_MIN.x;
    float ry = llFrand(REGION_MAX.y - REGION_MIN.y) + REGION_MIN.y;
    current_target_pos = llGetPos();
    current_target_pos.x = rx;
    current_target_pos.y = ry;
    g_tau = llVecDist(llGetPos(), current_target_pos) / STEP;
    move_to_target();
}

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

integer stuck(vector pos) {
  // 1. Stuck Detection (Are we walking into a wall without triggering a collision?)
  if (llVecDist(pos, g_last_pos) < 0.1) {
    debug("stuck "+(string) g_stuck_count + " " + (string) llVecDist(pos, g_last_pos));
    g_stuck_count++;
    if (g_stuck_count > 3) { // Stuck for ~3 seconds
      g_wedged_count++;
      llStopMoveToTarget();
      if (g_wedged_count > 3) {
	debug("wedged");
	g_wedged_count = 0;
	llMoveToTarget(home, 1);
      }
      pick_new_target();
      g_stuck_count = 0;
      return 1;
    }
  } else {
    g_wedged_count = g_stuck_count = 0;      
  }
  g_last_pos = pos;
  return 0;
}

// Calculates rotation and terrain height, then applies the physical movement
move_to_target() {
  vector pos = llGetPos();
    
  // 1. Face the target (keeping Z strictly horizontal to stay upright)
  vector dir = llVecNorm(current_target_pos - pos);
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
    current_target_pos.z = hit.z + (g_scale.z / 2.0);
  }
  // 4. Move physically to the target (1.0 second tau for smooth acceleration)
  llMoveToTarget(current_target_pos, g_tau); 
}

parse_json() {
  sml = (integer) llJsonGetValue(avatar_json, ["sml"]);
  string rp_json = llJsonGetValue(avatar_json, ["rp"]);
  string sps_json = llJsonGetValue(avatar_json, ["sps"]);
  if (rp_json != "" && llStringLength(rp_json) > 3) {
    rp = (integer) llJsonGetValue(rp_json, ["strength"]);
    rp_name = llJsonGetValue(rp_json, ["proto"]);
  } else {
    rp = 0;
    rp_name = "";
  }
  if (sps_json != "" && llStringLength(sps_json) > 3) {
    sps = (integer) llJsonGetValue(rp_json, ["total"]);
  } else {
    sps = 0;
  }
}

string chatString(string s) {
  integer idx = llSubStringIndex(s, "%s");
  if (idx == -1) return s;
  if (idx == 0) {
    return llGetDisplayName(avatar) + llGetSubString(s, 2, -1);
  } else if (idx == llStringLength(s)) {
    return llGetSubString(s,0,-3) + llGetDisplayName(avatar);
  }
  return llGetSubString(s,0,idx-1) +
    llGetDisplayName(avatar) +
    llGetSubString(s, idx + 2, -1);
}

integer calculateIndex() {
  integer g = 0;
  if (sml > 0) {
    if (sml > 20000)
      g = 6;
    else if (sml > 16500)
      g = 5;
    else if (sml > 10000)
      g = 4;
    else if (sml > 5000)
      g = 3;
    else if (sml > 1000)
      g = 2;
    else
      g = 1;
  }
  if (rp > 0 && rp > g) g = rp;
  if (sps > 0) {
    integer h = 0;
    if (sps > 20000)
      h = 6;
    else if (sps > 16500)
      h = 5;
    else if (sps > 10000)
      h = 4;
    else if (sps > 5000)
      h = 3;
    else if (sps > 1000)
      h = 2;
    else
      h = 1;
    if (h > g) g = h;
  }
  if (g > 0) g--;
  g = g * 5 + (integer) llFrand(5);
  return g;
}

default {
  on_rez(integer ignore) {
    home = llGetPos();
    list params = llParseString2List(llGetStartString(), ["|"], []);
    avatar = (key) params[0];

    avatar_json = (string) params[1];
    list anims = llGetObjectAnimationNames();
    integer len = llGetListLength(anims);
    while(len) {
      --len;
      llStopObjectAnimation((string) anims[len]);
    }

    running = (ignore == 1);
    parse_json();
    wander_state = 0;

    llSetStatus(STATUS_PHYSICS, TRUE);
    llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y, FALSE);
    if (running == FALSE) return;

    make_region((vector) (string) params[2], (vector) (string) params[3]);
    g_scale = llGetScale();
    animation = LAND;

    list f = llParseString2List((string) params[4], ["+"], []);
    len = llGetListLength(f);
    filters = [avatar];
    while (len > 0) {
      --len;
      filters = [(key)(string)f[len]] + filters;
    }

    channel = (integer) ("0x"+llGetSubString((string) llGetKey(), -6, -1));
    handle = llListen(channel, "", "", "");
    avatar_handle = llListen(0, "", avatar, "");
    llListenControl(avatar_handle, FALSE);
    status = 7; // GREETING
    llStartObjectAnimation(animation);
    llSetTimerEvent(1.25);
  }

  timer() {
    llSetTimerEvent(0);
    clear_animation();
    llStartObjectAnimation(animation = STAND);
    state wander;
  }

  listen(integer chan, string name, key xyzzy, string msg) {
    if (llListFindList(filters,[xyzzy]) == -1) return;
    list params = llParseString2List(msg, ["|"], []);
    if (chan == 0) return;
    switch((string) params[0]) {
    case "STATUS": {
      llRegionSayTo(EyeOfEkron, brain,
		    "STATUS|" + (string) status + "|" + (string) llGetPos());
      break;
    }
    case "FREE": {
      llDie();
      break;
    }
   default: break;
    }      
  }
  state_exit() {
    llListenRemove(handle);
    llListenRemove(avatar_handle);
    llSetTimerEvent(0);
  }
    
}

state wander {
  state_entry() {
    list greetings = GREETINGS;
    llMessageLinked(LINK_THIS,
		    CHAT,
		    chatString((string) greetings[calculateIndex()]),
		    avatar);
    handle = llListen(channel, "", "", "");
    avatar_handle = llListen(0, "", avatar, "");
    is_following = FALSE;
    wander_state = 0;
    moving = FALSE;
    llListenControl(avatar_handle, FALSE);
    llSetTimerEvent(0.5);         
    llSensorRepeat("", avatar, AGENT, 96.0, PI, 1.0);
    // Initialize the first wander target
    pick_new_target();
  }

  state_exit() {
    llListenRemove(handle);
    llListenRemove(avatar_handle);
    llSensorRemove();
    llSetTimerEvent(0);
  }

  sensor(integer num) {
    vector av_pos = llDetectedPos(0);
    rotation av_rot = llDetectedRot(0);
    
        // Check if the avatar is inside the defined region
    if (av_pos.x >= (REGION_MIN.x - 2) && av_pos.x <= (REGION_MAX.x + 2) &&
	av_pos.y >= (REGION_MIN.y - 2) && av_pos.y <= (REGION_MAX.y + 2)) {
      //debug("in region");
      if (!is_following) llListenControl(avatar_handle, TRUE);
      is_following = TRUE;
      vector my_pos = llGetPos();
      if (llVecDist(av_pos, current_target_pos) > 0.1) {
	vector ideal_pos = av_pos - llVecNorm(av_pos - my_pos);
	current_target_pos = clamp_to_region(ideal_pos,0);
	current_target_pos.z = av_pos.z;
      }
    } else {
      // Avatar is logged in, but outside the region bounds
      if (is_following) {
	is_following = FALSE;
	llListenControl(avatar_handle, FALSE);
	pick_new_target();
      }
    }
  }
    
  no_sensor() {
    // Avatar is offline or out of scanner range completely
    is_following = FALSE;
    llRegionSayTo(EyeOfEkron,brain, "DEPART");
    llSleep(0.1);
    llListenRemove(handle);
    llListenRemove(avatar_handle);
    llDie();
  }

  timer() {
    vector my_pos = llGetPos();
    float dist = llVecDist(my_pos, current_target_pos);
      
    if (is_following) { // target set in sensor
      wander_state = 1;
      if (dist > 2.5) {
	// We are more than 1.5m away from the follow spot, WALK to it
	if (animation != WALK) {
	  stop_animation();
#ifdef WALK_TIME
	  llMessageLinked(LINK_THIS, LOOP_WALK,
			  WALK + "|" + (string) WALK_TIME, NULL_KEY);
#else
	  llStartObjectAnimation(animation = WALK);
#endif
	}
	moving = TRUE;
	if (stuck(my_pos)) return;
	move_to_target();
      } else {
	// We are close enough to the follow spot, STAND
	wander_state = 2;
	moving = FALSE;
#ifdef WALK_TIME
	llMessageLinked(LINK_THIS, STOP_WALK, "", NULL_KEY);
#endif
	llStopMoveToTarget();
	llRotLookAt(llDetectedRot(0), 1.0, 1.0); // Look the same direction as avatar
	if (animation != STAND) {
	  clear_animation();
	  llStartObjectAnimation(animation = STAND);
	}
      }
    } else {
      if (wander_state != 4) {
	wander_state = 3;
	moving = TRUE;
	if (stuck(my_pos)) return;
	// 2. Check horizontal distance to target
	if (dist < 1.0) {
	  // Reached destination, pick a new spot
	  wander_state = 4;
	  moving = FALSE;
#ifdef WALK_TIME
	llMessageLinked(LINK_THIS, STOP_WALK, "", NULL_KEY);
#endif
	  llStopMoveToTarget();
	  wait_time = llGetUnixTime() + (integer) llFrand(15);
	  clear_animation();
	  llStartObjectAnimation(animation = STAND);
	} else {
	  move_to_target();
	}
      } else {
	if (llGetUnixTime() > wait_time) {
	  wander_state = 3;
	  moving = TRUE;
	  stop_animation();
#ifdef WALK_TIME
	  llMessageLinked(LINK_THIS, LOOP_WALK,
			  "|" + WALK + "|" + (string) WALK_TIME, NULL_KEY);
#else
	  llStartObjectAnimation(animation = WALK);
#endif
	  pick_new_target();
	}
      }
    }
  }
    
  collision_start(integer num_detected)  {
    if (!moving || avatar == NULL_KEY) return;
    integer hits = obstacle();
    if (hits == 4 || hits == 0) return; // step or floor or nothing
    debug("hits " +(string) hits);
    if (llDetectedType(0) & AGENT) {
      if (llDetectedKey(0) == avatar) is_following = TRUE;
      if (llAgentInExperience(llDetectedKey(0)))
	llMessageLinked(LINK_THIS, BUMP, (string) llDetectedPos(0), llDetectedKey(0));
    } else {
      if (g_stuck_count > 3) g_wedged_count = g_stuck_count = 0; 
      llStopMoveToTarget();
      pick_new_target();
    }
  }
  
  listen(integer chan, string name, key xyzzy, string msg) {
    if (llListFindList(filters,[xyzzy]) == -1) return;
    list params = llParseString2List(msg, ["|"], []);
    if (chan == 0) {
      switch (llToLower(msg)) {
      case llToLower(llGetObjectName()): {
	llMessageLinked(LINK_THIS, CHAT,"That's my name.  Don't abuse it!", avatar);
	break;
      }
      case "ok "+llToLower(llGetObjectName())+" let's wrestle.":
      case llToLower(llGetObjectName())+" let's wrestle.":
      case "let's wrestle": {
	if (animation != "") llStopObjectAnimation(animation);
#ifdef WALK_TIME
	llMessageLinked(LINK_THIS, STOP_WALK, "", NULL_KEY);
#endif
	llStopMoveToTarget();
	llMessageLinked(LINK_THIS, WRESTLE, avatar_json, avatar);
	state wait;
      }
#ifdef SPOTTER
      case "spot me":
      case "spot me.": {
	// Determine the root object of the user
	key root_id = llList2Key(llGetObjectDetails(avatar, [OBJECT_ROOT]), 0);
    
	// If the root is the user's own UUID, they are standing.
	// If it's a different UUID, they are sitting on an object!
	if (root_id != user_id && root_id != NULL_KEY) {
        
	  // Send a direct message to the machine they are sitting on
	  // Format:  action | user_uuid | my_animesh_uuid | role_requested
	  string msg = "offer_service|" + (string)user_id + "|" + (string)llGetKey() + "|trainer";
	  
	  llRegionSayTo(root_id, SYSTEM_CHANNEL, msg);
	  
	} else {
	  llRegionSayTo(avatar, 0, "You need to be on the machine first, dummy.");
	}
      }
#endif
      default:break;
      }
      return;
    }
    switch((string) params[0]) {
    case "STATUS": {
      llRegionSayTo(EyeOfEkron, brain,
		    "STATUS|" + (string) status + "|" + (string) llGetPos());
      break;
    }
    case "FREE": {
      llDie();
	break;
    }
    default: break;
    }      
  }
}

state wait {
  state_entry() {
    handle = llListen(channel, "", NULL_KEY, "");
  }

  state_exit() {
    llListenRemove(handle);
  }

  listen(integer chan, string name, key xyzzy, string msg) {
    if (llListFindList(filters,[xyzzy]) == -1) return;
    list params = llParseString2List(msg, ["|"], []);
    switch((string) params[0]) {
    case "STATUS": {
      llRegionSayTo(EyeOfEkron, brain,
		    "STATUS|" + (string) status + "|" + (string) llGetPos());
      break;
    }
    case "FREE": {
      llDie();
      break;
    }
    default: break;
    }      
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != WRESTLE_DONE) return;
    while (llGetListLength(llGetObjectAnimationNames())) llSleep(0.1);
    if (animation != "") llStartObjectAnimation(animation);
    state wander;
  }
}
