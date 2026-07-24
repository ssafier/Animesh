#include "src/animesh/include/animesh.h"
#include "src/animesh/include/controlstack.h"
#include "src/animesh/include/npc.h"

#define PROCESS 2005
#define DIST <10,10,0>

integer handle;
integer channel;

key avatar;
key httpKey;
string json;

default {
  state_entry() {
    channel = (integer)("0x"+llGetSubString((string)llGetKey(), -4, -1));
    handle = llListen(channel, "", NULL_KEY, "");
    llListenControl(handle, FALSE);
  }
  touch_start(integer x) {
    avatar = llDetectedKey(0);
    string request = "http://scott-safier.com/evolution/strength/" +
      llEscapeURL((string) avatar);
    llMessageLinked(LINK_THIS, 502, "", avatar);
    httpKey = llHTTPRequest(request, [], "");
  }
  http_response(key request_id, integer status, list metadata, string body) {
    if (request_id != httpKey) return;
    if (status == 200 && body != "") {
      json = body;
      list l = NPCs;
      string npcs = llDumpList2String(llListSort(llList2ListSlice(l, 0, -1, 2, 0), 1, FALSE), "+");
      llMessageLinked(LINK_THIS, doMenu, "501|Rez a wrestler|"+npcs, avatar);
    }
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != 501) return;
    GET_CONTROL;
    string animesh;
    POP(animesh);
    if (animesh == "[time out]") return;
    vector v = llGetPos();
    rotation r = llGetRot();
    vector v1 = v + (DIST * r);
    vector v2 = v -  (DIST * r);
    llMessageLinked(LINK_THIS,
		    PROCESS,
		    animesh + "|" + (string) avatar + "|" +  json + "|"
		    + (string) v1 + "|" + (string) v2 + "|" + (string) llGetKey(), 
		    xyzzy);
  }
}
