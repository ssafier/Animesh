#include "src/animesh/include/animesh.h"

#ifndef debug
#define debug(x)
#endif

#ifndef NOTECARD_NAME
#define NOTECARD_NAME "!Animations"
#endif

#define animesh_prim LINK_ROOT
integer avatar_prim;

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

stopAllObjectAnims() {
  list anims = llGetObjectAnimationNames();
  integer len = llGetListLength(anims);
  while(len) {
    --len;
    llStopObjectAnimation((string) anims[len]);
  }
}

// ----------------------
animate(key agent) {
  if (flags & afStopAll) {
    debug("stop");
    stopAllAnims(agent);
  }
  integer replace = (flags & afReplace) != 0;
  if (replace) {
    debug("replace");
    llStopAnimation((string) cached_animation[0]);
    llStopObjectAnimation((string) cached_animation[1]);
  }
  if (flags & afSwap) {
    list temp = translation;
    translation = [(string) temp[1], (string) temp[0]];
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
    debug("default");
    llStartAnimation((string) cached_animation[0]);
    llStartObjectAnimation((string) cached_animation[1]);
  }
  debug("done");
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
default {
  state_entry() {
    debug("Reading animations file.");
    flags = 0;
    current_avatar = NULL_KEY;
    cached_animation = ["stand","stand"];
    poses = [];

    integer objectPrimCount = llGetObjectPrimCount(llGetKey());
    integer currentLinkNumber = 0;
    avatar_prim = -1;
    while(currentLinkNumber <= objectPrimCount && avatar_prim == -1) {
      list params = llGetLinkPrimitiveParams(currentLinkNumber,
					     [PRIM_NAME]);
      switch((string) params[0]) {
      case "avi prim": {
	avatar_prim = currentLinkNumber;
	break;
      }
      default: break;
      }
      ++currentLinkNumber;
    }
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
    if (chan == resetAnimationState) {
      stopAllObjectAnims();
      stopAllAnims(current_avatar);
      flags = 0;
      current_avatar = NULL_KEY;
      cached_animation = ["stand","stand"];
      return;
    }
    if (chan != doAnimations &&
	chan != sitAvatar)  return;
    debug("animate "+msg);
    switch (chan) {
    case sitAvatar: {
      current_avatar = xyzzy;
      llMessageLinked(avatar_prim, 1, msg, current_avatar);
      break;
    }
    case doAnimations: { // animation | flags
      list m = llParseStringKeepNulls(msg, ["|"], []);
      translation = translateAnimation((string) m[0]);
      if (msg == "" || (string) translation[0] == "" || (string) translation[1] == "") {
	llOwnerSay("Animation not found "+msg);
	return;
      }
      debug("translate "+llDumpList2String(translation, " "));
      // should handle animation sequences in animators
      flags = (integer) (string) m[1];
      debug("current 1 "+(string) current_avatar);
      llRequestExperiencePermissions(current_avatar, "");
      break;
    }
    default: break;
    }
  }

  experience_permissions(key avi) {
    animate(avi);
  }

  experience_permissions_denied(key avi, integer x) {}

  changed(integer f) {
    if (f & CHANGED_INVENTORY) {
      llResetScript();
    }
  }
}

