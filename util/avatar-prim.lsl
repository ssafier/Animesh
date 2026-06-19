#include "src/animesh/include/animesh.h"

#ifndef debug
#define debug(x)
#else
#define DEBUGGING
#endif

#define DELTA 0.01

key avatar = NULL_KEY;
string avatar_json;

vector offset;
vector pos;
rotation rot;

integer link_num;
float fAdjust;

integer animesh_channel;

integer ControlsActive;
vector SitTargetRef = ZERO_VECTOR;
vector SitTarget = ZERO_VECTOR;

handle_control(key id, integer level, integer change) {
  debug("handle control "+(string)id+" "+(string)level+" "+(string)change);
  if (avatar == NULL_KEY)  return;
    
  if ((level & CONTROL_FWD) && (level & CONTROL_BACK)) {
    ControlsActive = ! ControlsActive;
    if (ControlsActive) {
      control_active();
    } else {
      control_ready();
    }
    return;
  }
    
  if (!ControlsActive)  return;

  if (level & CONTROL_UP) {
    offset.z += DELTA;
  } else if (level & CONTROL_DOWN) {
    offset.z -= DELTA;
  } else if (level & CONTROL_LEFT) {
    offset.y += DELTA;
  } else if (level & CONTROL_RIGHT) {
    offset.y -= DELTA;
  } else if (level & CONTROL_FWD) {
    offset.x += DELTA;
  } else if (level & CONTROL_BACK) {
    offset.x -= DELTA;
  } else {
    return;
  }

  llSetLinkPrimitiveParamsFast(link_num,
			       [PRIM_POS_LOCAL, pos + offset * rot + SitTargetRef - SitTarget]);
}

// enter "control ready" state.
control_ready() {
  debug("control ready");
  ControlsActive = 0;
  integer controls = CONTROL_FWD | CONTROL_BACK;

  llTakeControls(controls, TRUE, FALSE);
}

control_active() {
  debug("control active");
  integer controls = CONTROL_UP | CONTROL_DOWN | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_FWD | CONTROL_BACK;

  llTakeControls(controls, TRUE, FALSE);
  pos = llGetLocalPos();
  rot = llGetLocalRot();
}

default {
  state_entry() {
    if (llGetLinkNumber() == 0) return;
#ifdef DEBUGGING
    llSetLinkAlpha(LINK_THIS, 1.0, ALL_SIDES);
    llSetLinkPrimitiveParamsFast(LINK_THIS,
				 [PRIM_SIZE, <0.5,0.5,0.1>,PRIM_POS_LOCAL, <0.5,0,-0.5>]);
#else
    llSetLinkAlpha(LINK_THIS, 0, ALL_SIDES);
    llSetLinkPrimitiveParamsFast(LINK_THIS,
				 [PRIM_SIZE, <0.05,0.05,0.01>,PRIM_POS_LOCAL, <0,0,-0.5>]);
#endif
    
    llSetLinkPrimitiveParamsFast(LINK_THIS,
				 [PRIM_SIT_FLAGS,
				  SIT_FLAG_ALLOW_UNSIT |
				  SIT_FLAG_SCRIPTED_ONLY]);
    llLinkSitTarget(LINK_THIS, <0,0,0.01>, ZERO_ROTATION);

    if (avatar == NULL_KEY) return;
    llRequestExperiencePermissions(avatar,""); 
  }
  
  experience_permissions(key avi) {
    debug(avi);
    integer sitTest = llSitOnLink(avi, LINK_THIS);
    if (sitTest == 1) {
      debug("here");
      vector size = llGetAgentSize(avi);
      fAdjust = ((((0.008906 * size.z) + -0.049831) * size.z) + 0.088967) * size.z;
      integer linkNum = llGetNumberOfPrims();
      link_num = -1;
      while(linkNum && link_num == -1) {
	if (avi == llGetLinkKey(linkNum))
	  link_num = linkNum;
	else
	  --linkNum;
      }
      offset = ZERO_VECTOR;
      control_ready();
      llMessageLinked(LINK_ROOT, avatarSeated, "", avatar);
    }
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    debug((string) chan + " " + msg + " " + (string) xyzzy);
    switch(chan) {
    case 1: {
      integer index = llSubStringIndex(msg, "|");
      avatar_json = llGetSubString(msg, index + 1, -1);
      llRequestExperiencePermissions(avatar = xyzzy, "");
      break;
    }
    case 2: {
      integer index = llSubStringIndex(msg,"|");
      if (index == -1) return;
      debug(msg);
      vector pos = (vector) llGetSubString(msg, 0, index - 1);
      rotation rot = (rotation) llGetSubString(msg, index + 1, -1);
      llSetLinkPrimitiveParamsFast(LINK_THIS,
				   [PRIM_POS_LOCAL, pos, PRIM_ROT_LOCAL, rot]);
      break;
    }
    default: break;
    }
  }

  changed(integer flag) {
    if (flag & CHANGED_LINK) {
      debug("key "+(string)llGetLinkKey(link_num));
      if (avatar != NULL_KEY && link_num != -1 && avatar != llGetLinkKey(link_num)) {
	debug("change");
	llMessageLinked(LINK_ROOT, ACTION_OFF, "", avatar);
	llSetLinkPrimitiveParamsFast(LINK_THIS,
#ifdef DEBUGGING
				     [PRIM_SIZE, <0.5,0.5,0.1>,PRIM_POS_LOCAL, <0.5,0,-0.5>]
#else
				     [PRIM_SIZE, <0.05,0.05,0.01>,PRIM_POS_LOCAL, <0,0,-0.5>]
#endif
				     );
	avatar = NULL_KEY;
      }
    }
  }
  control(key id, integer level, integer change) {
    debug("control "+(string)id+" "+(string)level+" "+(string)change);
    handle_control(id, level, change);
  }
}
