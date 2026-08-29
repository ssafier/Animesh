#include "src/animesh/include/animesh.h"
#include "src/animesh/include/controlstack.h"

integer handle;
integer channel;

key avatar;
key httpKey;
string json;
vector dir_vect;

default {
  state_entry() {
    channel = (integer)("0xE"+llGetSubString((string)llGetKey(), -5, -1));
    handle = llListen(channel, "", NULL_KEY, "");
    llListenControl(handle, FALSE);
  }

  state_exit() {
    llListenRemove(handle);
  }
  
  touch_start(integer x) {
    llSay(channel, "DIE");
    avatar = llDetectedKey(0);
    dir_vect = llVecNorm(llDetectedPos(0) - llGetPos()) * 2;
    llListenControl(handle, TRUE);
    llDialog(avatar, "Do you want to rez " + ANIMESH, ["Yes", "No"], channel);
  }
  
  listen(integer chan, string name, key xyzzy, string msg) {
    llListenControl(handle, FALSE);
    if (msg != "Yes") return;
    string request = "http://scott-safier.com/evolution/strength/" +
      llEscapeURL((string) avatar);
    httpKey = llHTTPRequest(request, [], "");
  }
      
  http_response(key request_id, integer status, list metadata, string body) {
    if (request_id != httpKey) return;
    if (status == 200 && body != "") {
      json = body;
      key obj = llRezObjectWithParams(ANIMESH,
				      [REZ_POS, llGetPos() + dir_vect, FALSE, TRUE,
				       REZ_PARAM, 1,
				       REZ_ROT, ZERO_ROTATION, FALSE,
				       REZ_PARAM_STRING,
				       (string) avatar + "|" +  json  + "|" + (string) llGetKey() + "|" +
				       REASON]);
    }
  }
}
