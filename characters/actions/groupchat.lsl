#include "src/animesh/include/animesh.h"

string target_name;
key httpKey;
key detected_id;
key avatar;

default {
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan != GROUP_CHAT) return;
    target_name = msg;
    avatar = xyzzy;
    // Fire a sensor to find all avatars within 96 meters
    llSensor("", NULL_KEY, AGENT, 96.0, PI);
  }

  sensor(integer total_number) {
    integer i;
    for (i = 0; i < total_number; ++i) {
      detected_id = llDetectedKey(i);
      string display_name = llToLower(llGetDisplayName(detected_id));
      if (display_name == target_name) {
	string json = "{\"avatar\":\"" + (string) avatar +
	  "\", \"npc\":\"" + llGetObjectName() +
	  "\", \"toadd\":\"" + (string) detected_id + "\"}";
	string request = "RP/groupadd/";
	httpKey = llHTTPRequest(SERVER + "RP/group-chat",
				[HTTP_METHOD, "POST",
				 HTTP_MIMETYPE, "application/json"],
				json);
	return;
      }
    }
    llSay(0, "Cannot find "+target_name);
  }
  http_response(key request_id, integer status, list metadata, string body) {
    if (request_id != httpKey) return;
    if (status == 200 && body != "") {
      llLinksetDataWrite((string) detected_id, body);
      llMessageLinked(LINK_THIS, RegisterChatter, body, detected_id);
      llSleep(0.1);
      llMessageLinked(LINK_THIS, CHATBOT_GREET,
		      llGetDisplayName(detected_id) + " has arrived and greets everyone*|Hi",
		      detected_id);
      detected_id = NULL_KEY;

    }
  }
}
