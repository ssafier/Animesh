#include "include/animesh.h"

#ifndef debug
#define debug(x)
#endif

list chatQ;
key http_key;
integer active;

string msgdefault;

default {
  state_entry() {
    chatQ = [];
    active = 0;
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (active) return;
    switch (chan) {
    case CHAT: {
      integer timerp = chatQ == [];
      chatQ = chatQ + [msg];
      if (chatQ) llSetTimerEvent(1.5 + llFrand(1.5));
      break;
    }
    case CHATBOT: {
      list params = llParseString2List(msg, ["|"], []);
      string json = "{\"avatar\":\"" + (string) xyzzy +
	"\", \"npc\":\"" + llGetObjectName() + "\", \"message\": \"" + (string) params[0] +
	"\", \"avatar-desc\":\"" + (string) params[1] +
	"\", \"text\":\"" + (string) params[2] + ".\"}";
      msgdefault = (string) params[3];
      active = TRUE;
      http_key = llHTTPRequest(SERVER + "RP/chat",[HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/json"], json);
      break;
    }
    default: break;
    }
  }
  
  http_response(key request_id, integer status, list metadata, string body) {
    if (request_id != http_key) return;
    active = FALSE;
    debug(body);
    if (status == 200) {
      string status = llJsonGetValue(body, ["status"]);
      if (status == "ok") {
	llSay(0, llJsonGetValue(body, ["reply"]));
	return;
      }
    }
    llSay(0, msgdefault);
  }

timer() {
    llSetTimerEvent(0);
    llShout(0, (string) chatQ[0]);
    if (llGetListLength(chatQ) == 1) {
      chatQ = [];
    } else {
      chatQ = llList2List(chatQ,1,-1);
      if (chatQ) llSetTimerEvent(1.5 + llFrand(1.5));
    }
  }
}
