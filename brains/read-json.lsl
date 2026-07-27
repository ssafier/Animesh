#ifndef debug
#define debug(x)
#endif

#ifndef NOTECARD
#define NOTECARD "Notecard"
#endif

key note_handle;

default {
  state_entry() {
    llLinksetDataReset();
    note_handle = llGetNumberOfNotecardLines(NOTECARD);
  }

  dataserver(key request, string data)  {
    if (request == note_handle) {
      note_handle = NULL_KEY;
      integer count = (integer)data;
      integer index;
      string json = "";
      for (index = 0; index < (count+1); ++index) {
	string line = llGetNotecardLineSync(NOTECARD, index);
	if (line == NAK) {
	  llOwnerSay("Notecard line reading failed");
	} else if (line != EOF && line != "") {
	  json = json + line;
	  if (line == "}") {
	    llSay(0, llJsonGetValue(json,["character"]));
	    llLinksetDataWrite(llJsonGetValue(json,["character"]), json);
	    json = "";
	  }
	}
      }
    }
    llRemoveInventory(NOTECARD);
    llRemoveInventory(llGetScriptName());
  }
}
