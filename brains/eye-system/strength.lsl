#include "include/controlstack.h"

#define getStrength 8

key httpKey;
integer cFloater;
key avi;

GLOBAL_DATA;

// --- Cache Tracking Variables ---
list cache_uuids = [];
list cache_strengths = [];

// --- State Variables ---
// Stores the target avatars across the HTTP wait state
list current_in_area = []; 

default {
  on_rez(integer f) {
    cFloater = f - 1;
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != getStrength) return;
    GET_CONTROL_GLOBAL;
    
    string inArea = "";
    POP(inArea);
    string entered = "";
    POP(entered);
    string departing = "";
    POP(departing);
    // put them back
    PUSH(departing);
    PUSH(entered);
      
    list avatars = llParseString2List(inArea, ["~"], []);
    current_in_area = avatars; // Save the full list for building the output later
    avatars = llParseString2List(departing, ["~"], []);
    // 1. Clean the cache (Remove avatars that have departed)
    integer i;
    if (avatars != []) {
      integer len = llGetListLength(cache_uuids);
      for (i = 0; i < len; i += 2) {
        string c_uuid = (string)cache_uuids[i];
        if (llListFindList(avatars, [c_uuid]) == -1) {
	  // Avatar is no longer in area; delete from cache
	  cache_uuids = llDeleteSubList(cache_uuids, i, i+1);
        }
      }
    }

    // 2. Identify new avatars that need fetching
    list new_avatars = llParseString2List(entered, ["~"], []);
    // 3. Dispatch HTTP request for new avatars OR proceed immediately
    if (llGetListLength(new_avatars) > 0) {
        string request = "http://scott-safier.com/evolution/rank/" + llEscapeURL(llDumpList2String(new_avatars, ","));
        httpKey = llHTTPRequest(request, [], "");
        avi = xyzzy; 
    } else {
        // Everyone is already in the cache! Build the output immediately.
      integer len = llGetListLength(current_in_area);
      string out = "";
      for (i = 0; i < len; ++i) {
	string a_uuid = (string) current_in_area[i];
	integer idx = llListFindList(cache_uuids, [a_uuid]);
	if (idx != -1) {
	  if (out != "") out += "+";
	  out += (string)cache_uuids[idx + 1] + "+" + a_uuid;
	}
      }
      PUSH(out);
      NEXT_STATE;
    }
  }

  http_response(key request_id, integer status, list metadata, string body) {
    if (request_id != httpKey) return;
    key id = avi; 
    if (status == 200 && body != "") {
      list players = llJson2List(body);
      integer l = llGetListLength(players);
      integer i;
      
      // Update our cache with the newly fetched data
      // players layout: [uuid, name+resident, strength, rank]
      for(i = 0; i < l; i = i + 2) {
        string p_uuid = (string) players[i];
        string p_strength = (string) players[i + 1];
        
        // Add to cache, checking to prevent duplicate entries
        integer idx = llListFindList(cache_uuids, [p_uuid]);
        if (idx == -1) {
	  cache_uuids += [p_uuid, p_strength];
        } else {
	  cache_strengths = llListReplaceList(cache_uuids, [p_strength], idx + 1, idx + 1);
        }
      }
    }
    
    // Build the final output string from the combined cache
    string out = "";
    integer j;
    for (j = 0; j < llGetListLength(current_in_area); ++j) {
      string a_uuid = (string) current_in_area[j];
      integer idx = llListFindList(cache_uuids, [a_uuid]);
      if (idx != -1) {
	if (out != "")
	  out += "+";
	out +=(string)cache_uuids[idx + 1] + "+" + a_uuid;
      }
    }
    
    PUSH(out);
    key xyzzy = avi;
    NEXT_STATE;
  }
}
