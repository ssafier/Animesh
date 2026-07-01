#include "include/animesh.h"
#include "include/controlstack.h"

#define PROCESS 2005
#define DIST <2,2,0>

integer handle;
integer channel;

key avatar;
key httpKey;
string json;

key last_animesh;

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
    if (last_animesh != NULL_KEY)
      llMessageLinked(LINK_THIS, 502, "", last_animesh);
    httpKey = llHTTPRequest(request, [], "");
  }
  http_response(key request_id, integer status, list metadata, string body) {
    if (request_id != httpKey) return;
    if (status == 200 && body != "") {
      json = body;
      last_animesh = NULL_KEY;
      llMessageLinked(LINK_THIS, doMenu, "501|Rez a wrestler|Spiderman+Snow Symbiote+Azazel+Firestorm+Rogue+Northstar+Human Torch+Ben Grimm+Batman+Damien Wayne+Red Robin+Harley Quinn+Dark Phoenix+Flash+Reverse Flash+Thor Odinson+Ironman+Hal Jordan+Captain America+Lobo+Adam Warlock+Amazon+Red Hulk+Invincible+Omni-Man", avatar);
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

  object_rez(key o) { last_animesh = o; }
}
