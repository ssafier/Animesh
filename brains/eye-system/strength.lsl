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
    debug("in area "+inArea);
    list avatars = llParseString2List(inArea, ["~"], []);
    current_in_area = avatars; // Save the full list for building the output later
    list new_avatars = llParseString2List(entered, ["~"], []);
    list gone_baby = llParseString2List(departing, ["~"], []);
    if (llGetListLength(new_avatars) > 0 ||
	(llGetListLength(gone_baby) > 0 && llGetListLength(avatars) > 0)) {
      string request = "http://scott-safier.com/evolution/rank/" + llEscapeURL(llDumpList2String(avatars, ","));
      httpKey = llHTTPRequest(request, [], "");
      avi = xyzzy;
    }
  }

  http_response(key request_id, integer status, list metadata, string body) {
    if (request_id != httpKey) return;
    key id = avi; 
    list out;
    if (status == 200 && body != "") {
      list players = llJson2List(body);
      integer l = llGetListLength(players);
      integer i;
      // Update our cache with the newly fetched data
      // players layout: [uuid, name+resident, strength, rank]
      for(i = 0; i < l; i = i + 2) {
        string p_uuid = (string) players[i];
        string p_strength = (string) players[i + 1];
        out = out + [p_strength, p_uuid];
      }
    }
    PUSH(llDumpList2String(out,"+"));
    key xyzzy = avi;
    NEXT_STATE;
  }
}
