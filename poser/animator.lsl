#include "src/animesh/include/animesh.h"

#ifndef debug
#define debug(x)
#endif

#ifndef NOTECARD_NAME
#define NOTECARD_NAME "!Animations"
#endif

#define animesh_prim LINK_THIS
key avatar_prim;

// [name, pose1, pose2,...]
list poses;

key note_handle;
integer initialized = FALSE;

integer flags;
list translation;
list cached_animation;
key current_avatar;

// -------------------------
stopAllAnims(key avi) {
  list anims = llGetAnimationList(avi);
  integer len = llGetListLength(anims);
  while(len) {
    --len;
    llStopAnimation((key) anims[len]);
  }
}

// ---------------------
reset() {
  flags = 0;
  current_avatar = NULL_KEY;
  cached_animation = ["stand","stand"];
}

// ----------------------
animate(key agent) {
  if (current_avatar == NULL_KEY) return;
  if (flags & afStopAll) {
    stopAllAnims(agent);
  }
  integer replace = (flags & afReplace) != 0;
  if (replace) {
    llStopAnimation((string) cached_animation[0]);
    llStopObjectAnimation((string) cached_animation[1]);
  }
  if ((flags & afCache) != 0) {
    if (!replace && (translation != cached_animation)) {
      llStopAnimation((string) cached_animation[0]);
      llStopObjectAnimation((string) cached_animation[1]);
    }
    cached_animation = translation;
    llStartAnimation((string) cached_animation[0]);
    llStartObjectAnimation((string) cached_animation[1]);
  } else {
    llStartAnimation((string) cached_animation[0]);
    llStartObjectAnimation((string) cached_animation[1]);
  }
}

//----------------------
list translateAnimation(string a) {
  integer l = llGetListLength(poses);
  integer x = 0;
  while (x < l) {
    if ((string) poses[x] == a) return llList2List(poses, x+1, x+2);
    x += 3;
  }
  return [];
}

//----------------------
initialize(string avi_data) {
  if (initialized) return;
  vector size = llGetScale();
  vector pos = llGetPos();
  pos.z -= (size.z / 2.0);
  pos.x += 0.5;
  avatar_prim = llRezObjectWithParams("avi_prim", [REZ_POS, pos, FALSE, TRUE,
						  REZ_PARAM, 1,
						  REZ_ROT, ZERO_ROTATION, FALSE,
						  REZ_PARAM_STRING, avi_data]);
}

//----------------------
default {
  state_entry() {
    debug("Reading animations file.");
    reset();
    poses = [];
    note_handle = llGetNumberOfNotecardLines(NOTECARD_NAME);
  }

  // pose|<sequence>|<sequence>
  // <sequence> = animation (?+flex(?: time))(? ~<sequence>)
  dataserver(key request, string data)  {
    if (request == note_handle) {
      note_handle = NULL_KEY;
      integer count = (integer)data;
      integer index;
            
      for (index = 0; index < (count+1); ++index) {
	string line = llGetNotecardLineSync(NOTECARD_NAME, index);
	if (line == NAK) {
	  llOwnerSay("Notecard line reading failed");
	} else if (line != EOF) {
	  if (line != "") {
	    list l = llParseString2List(line, ["|"], []);
	    switch(llToLower((string) l[0])) {
	    case "pose": {
	      list p = llList2List(l,1,-1);
	      if (llGetListLength(p) == 3) {
		poses = poses + p;
	      }
	      break;
	    }
	    default: break;
	    }
	  }
	} else {
	  debug("Animations loaded.");
	  //llOwnerSay("poses "+llDumpList2String(poses," "));
	}
      }
    }
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != doAnimations &&
	chan != sitAvatar)  return;
    debug("animate "+msg);
    switch (chan) {
    case sitAvatar: {
      integer index = llSubStringIndex(msg, "|");
      current_avatar = (key) llGetSubString(msg, 0, index - 1);
      initialize(msg);
      break;
    }
    case doAnimations: { // animation | flags
      if (chan == resetAnimationState) {
	reset();
	return;
      }
      list m = llParseStringKeepNulls(msg, ["|"], []);
      translation = translateAnimation((string) m[0]);
      if (msg == "" || (string) translation[0] == "" || (string) translation[1] == "") {
	llOwnerSay("Animation not found "+msg);
	return;
      }
      debug("translate "+llDumpList2String(translation, " "));
      // should handle animation sequences in animators
      flags = (integer) (string) m[1];
      llRequestExperiencePermissions(current_avatar, "");
      break;
    }
    default: break;
    }
  }

  experience_permissions(key avi) {
    animate(avi);
  }

  changed(integer f) {
    if (f & CHANGED_INVENTORY) {
      llResetScript();
    }
  }

  object_rez(key object) {
    if (object == avatar_prim) initialized = TRUE;
    llMessageLinked(LINK_THIS, avatarSeated, "", object);
  }
}

