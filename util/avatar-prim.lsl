#ifndef debug
#define debug(x)
#endif

#define DELTA 0.01

key avatar;
vector offset;
vector pos;
rotation rot;

integer link_num;
float fAdjust;

integer handle;

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

  llSetPos(pos + offset * rot + SitTargetRef - SitTarget);
}

// enter "control ready" state.
control_ready() {
  debug("control ready");
  ControlsActive = 0;
  integer controls = CONTROL_FWD | CONTROL_BACK;

  llTakeControls(controls, TRUE, FALSE);
  llInstantMessage(avatar, "Allow adjusting your position by pressing FORWARD and BACK keys at the same time");
}

control_active() {
  debug("control active");
  integer controls = CONTROL_UP | CONTROL_DOWN | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_FWD | CONTROL_BACK;

  llTakeControls(controls, TRUE, FALSE);
  llInstantMessage(avatar, "Adjust your position using Pgup/Pgdn, Up/Down arrow, and shift-left/right arrow keys\nDisable by pressing Pgup and Pgdn keys at the same time");
  pos = llGetPos();
  rot = llGetRot();
}

default {
  on_rez(integer x) {
    if (x == 0) return;
    string param = llGetStartString();
    integer index = llSubStringIndex(param,"|");
    if (index == -1) llDie();
    avatar = (key) llGetSubString(param,0,index - 1);
    llListen((integer)("0x"+llGetSubString((string) llGetKey(), -4, -1)), "", NULL_KEY, "");
    llSetAlpha(1.0, ALL_SIDES);
    llSetLinkPrimitiveParamsFast(LINK_THIS,
				 [PRIM_SIT_FLAGS,
				  SIT_FLAG_ALLOW_UNSIT |
				  SIT_FLAG_SCRIPTED_ONLY]);
    link_num = -1;
    llRequestExperiencePermissions(avatar,"");
  }
  
  experience_permissions(key avi) {
    integer sitTest = llSitOnLink(avi, LINK_ROOT);
    if (sitTest == 1) {
      vector size = llGetAgentSize(avi);
      fAdjust = ((((0.008906 * size.z) + -0.049831) * size.z) + 0.088967) * size.z;
      integer linkNum = llGetNumberOfPrims();
      while(linkNum && link_num == -1) {
	if (avi == llGetLinkKey(linkNum))
	  link_num = linkNum;
	else
	  --linkNum;
      }
      offset = ZERO_VECTOR;
    }
  }

  changed(integer flag) {
    if (flag & CHANGED_LINK) {
      if (avatar != NULL_KEY && link_num != -1 &&
	  (llGetAgentSize(avatar) == ZERO_VECTOR ||
	   avatar != llGetLinkKey(link_num))) llDie();
    }
  }
  
  listen(integer chan, string name, key xyzzy, string msg) {
    integer index = llSubStringIndex(msg,"|");
    if (index == -1) return;
    debug(msg);
    vector pos = (vector) llGetSubString(msg, 0, index - 1);
    rotation rot = (rotation) llGetSubString(msg, index + 1, -1);
    llSetLinkPrimitiveParamsFast(LINK_THIS,
				 [PRIM_POSITION, pos, PRIM_ROTATION, rot]);
  }
}
