#include "include/animesh.h"
#include "include/controlstack.h"

GLOBAL_DATA;
key avi;
key http;

integer max(integer a, integer b) {
  if (a > b) return a; else return b;
}
#define set_max(a, b) a = max(a, b)

default {
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != GET_STRENGTH) return;
    GET_CONTROL_GLOBAL;
    avi = xyzzy;
    http = llHTTPRequest(SERVER+"/evolution/strength/"+llEscapeURL((string) xyzzy), [], "");
  }
  http_response(key id, integer status, list metadata, string body)
    {
        if (id != http) return;// exit if unknown
	// this returns max, but can check the next state and return different results
	integer strength = 300;
	set_max(strength, (integer) llJsonGetValue(body, ["sml"]));
	string rp =  llJsonGetValue(body, ["rp"]);
	switch ((integer) llJsonGetValue(rp,["strength"])) {
	case 1: strength = 200; break;
	case 3: set_max(strength, 1000); break;
	case 4: set_max(strength, 5000); break;
	case 5: set_max(strength, 10000); break;
	case 6: set_max(strength, 20000); break;
	case 7: set_max(strength, 100000); break;
	default: break;
	}
	string sps = llJsonGetValue(body,["sps"]);
	if (sps != "") {
	  string result = llJsonGetValue(sps,["total"]);
	  if (result != JSON_NULL && result != JSON_INVALID) {
	    set_max(strength, (integer) result);
	  }
	}
	PUSH(strength);
	key xyzzy = avi;
	NEXT_STATE;
    }
}
