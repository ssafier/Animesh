#include "src/animesh/include/animesh.h"

#ifndef debug
#define debug(x)
#endif

key current_avatar = NULL_KEY;
integer flags;
string animation;
string cached_animation;
// ---------------------
reset() {
  flags = 0;
  animation = "";
  current_avatar = NULL_KEY;
  cached_animation = "stand";
}

default {
  state_entry() {
    reset();
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan == resetAnimationState) {
      reset();
      return;
    }
    if (chan != doAnimate) return;
    
    integer index = llSubStringIndex(msg,"|");
    flags = (integer) llGetSubString(msg,0, index-1);
    animation = llGetSubString(msg,index+1,-1);
    
    // Bypass permissions completely if this is the Animesh script
    current_avatar = xyzzy; // Keep for tracking, even though it's an object key
        
    // Stop previous if replacing
    if ((flags & afReplace) != 0) llStopObjectAnimation(cached_animation);
        
    if ((flags & afCache) != 0) {
      if (!(flags & afReplace) && (animation != cached_animation)) llStopObjectAnimation(cached_animation);
      llStartObjectAnimation(cached_animation = animation);
    } else {
      llStartObjectAnimation(animation);
    }
  }
}
