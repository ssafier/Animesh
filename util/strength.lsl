#include "include/animesh.h"
#include "include/controlstack.h"
#include "src/server/include/mpg.h"

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
  http_response(key id, integer status, list metadata, string json)
    {
        if (id != http) return;// exit if unknown
	if (status != 200) return;
	string avdesc = "  Your opponent is "+ llGetDisplayName(avi) +".";
	string rp =  llJsonGetValue(json, ["rp"]);
	string sps = llJsonGetValue(json,["sps"]);
	string sml = llJsonGetValue(json, ["sml"]);
	integer strength = 1;
	integer str = -1;

	if (sml != JSON_INVALID && sml != JSON_NULL) {
	  str = (integer) sml;
	}
	if (sps != JSON_INVALID && sps != JSON_NULL) {
	  string result = llJsonGetValue(sps,["total"]);
	  if (result != JSON_NULL && result != JSON_INVALID) {
	    if ((integer) result > str) str = (integer) result;
	  }
	}
	if (str >= 50000) strength = 7; else
	  if (str >= 20000) strength = 6; else
	    if (str >= 15000) strength = 5; else
	      if (str >= 10000) strength = 4; else
		if (str >= 5000) strength = 3; else
		  if (str >= 1000) strength = 2; else
		    if (str >= 300) strength = 1;
	PUSH(str);
	str = (integer) llLinksetDataRead("strength");
	integer me;
	if (str >= 50000) me = 7; else
	  if (str >= 20000) me = 6; else
	    if (str >= 15000) me = 5; else
	      if (str >= 10000) me = 4; else
		if (str >= 5000) me = 3; else
		  if (str >= 1000) me = 2; else
		    if (str >= 300) me = 1;

	list text = StrengthText;
	if (rp != JSON_INVALID && rp != JSON_NULL) {
	  string result = llJsonGetValue(rp,["proto"]);
	  if (result != JSON_NULL && result != JSON_INVALID) {
	    avdesc = avdesc + "  They have the powers of " + result;
	    result = llJsonGetValue(rp,["strength"]);
	    if (result != JSON_NULL && result != JSON_INVALID) {
	      avdesc = avdesc + " and a  strength of " + (string) text[((integer) result) - 1] +
		" compared to your strength of " + (string) text[me];
	    }
	    avdesc = avdesc + ".";
	    result = llJsonGetValue(rp, ["alignment"]);
	    if (result != JSON_NULL && result != JSON_INVALID) {
	      list align = AlignmentText;
	      avdesc = avdesc + " Their alignment is " + (string) align[(integer) result - 1];
	    }
	  } else {
	    result = llJsonGetValue(rp,["strength"]);
	    if (result != JSON_NULL && result != JSON_INVALID) {
	      strength = (integer) result;
	    }
	  }
	}
	avdesc = avdesc + "  They are " + (string) text[strength] + " compared to you " + (string) text[me] + ".";
	key xyzzy = avi;
	NEXT_STATE;
    }
}
