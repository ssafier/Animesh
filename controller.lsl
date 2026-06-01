// -- ANIMESH CONTROLLER --
#include "include/animesh.h"

list g_animesh_keys = [
    "00000000-0000-0000-0000-000000000001", 
    "00000000-0000-0000-0000-000000000002"
];
list g_expected_states = [ACT_IDLE, ACT_IDLE]; 

integer get_channel(key id) {
  return (integer)("0x" + llGetSubString((string)id, 0, 7));
}

// and update expected state for animesh character
send_command(key target, integer action) {
  integer chan = get_channel(target);
  // Sends a highly optimized string like "1|2"
  llRegionSayTo(target, chan, (string)CMD_ACTION + "|" + (string)action);
  
  integer index = llListFindList(g_animesh_keys, [(string)target]);
  if (index != -1) {
    g_expected_states = llListReplaceList(g_expected_states, [action], index, index);
  }
}

default {
  state_entry() {
    llListen(CONTROLLER_CHAN, "", NULL_KEY, "");
  }

  listen(integer channel, string name, key id, string message) {
    if (llGetOwnerKey(id) != llGetOwner()) return; 

    list parsed = llParseString2List(message, ["|"], []);
    integer prefix = (integer)(string)parsed[0]; // Fast, safe cast
    
    switch (prefix) {
    case CMD_ERROR: {
      integer error_type = (integer)(string)parsed[1];
      key my_animesh = (key)(string)parsed[2];
      
      switch (error_type) {
      case ERR_COLLISION: {
	integer hit_type = (integer)(string)parsed[3];
	key hit_uuid = (key)(string)parsed[4];
        
	integer hit_index = llListFindList(g_animesh_keys, [(string)hit_uuid]);
	switch(hit_index) {
	case -1: {
	  send_command(my_animesh, ACT_TALK);
	  send_command(hit_uuid, ACT_TALK);
	  break;
	}
	case TYPE_AVATAR: {
	  send_command(my_animesh, ACT_IDLE);
	  break;
	}
	default: {
	  // Hit a wall, calculate new path
	  // send_command(my_animesh, ACT_WALK); 
	  break;
	}
	}
	break;
      }
      case ERR_STUCK: {
	send_command(my_animesh, ACT_IDLE);
	break;
      }
      default: break;
      }
      break;
    }      
    case CMD_STATUS: {
      // For future use (e.g., Animesh reports arriving at destination)
      break;
    }
    default: break;
    }
  }
}
