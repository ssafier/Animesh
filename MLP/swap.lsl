//MPLV2 Version 2.3 by Learjeff Innis, based on
//MLP MULTI-LOVE-POSE V1.2 - Copyright (c) 2006, by Miffy Fluffy (BSD License)

// This script handles configurable SWAP behavior.
// It reads .SWAP* files to get set of ball-orders per pose.
// When a pose button is used, we store a list of ball orders for this pose as PoseData.
// When SWAP button is used, ~menu sends "SWAP" LM, with an incremented index.
// When we get this LM, we send on an "ORDER" LM containing the ball order string for that index.


integer Checking = FALSE;       // whether doing consistency check

list    Poses;                  // name of each pose with swap configured
list    Data;                   // data for each pose, indexed as Poses.
                                //  format: colon-separated list of space-sep list of ballnums

string  Pose;                   // current pose name
list    PoseData;               // data for this pose
string  LastPoseOrder;          // ball order for last swap

integer ChatChan;               // chan for talking to object
integer SwapIx;

float probability_of_win;

init()
{
    ChatChan = - 1 - (integer)llFrand(-DEBUG_CHANNEL);
}


string plural(string singular, string plural, integer count) {
    if (count != 1) {
        return plural;
    }
    return singular;
}

announce()
{
    integer pcount = llGetListLength(Poses);
    llOwnerSay((string) pcount
        + plural(" pose", " poses", pcount)
        + " with swaps ("
        + llGetScriptName()
        + ": "
        + (string)llGetFreeMemory()
        + " bytes free)");
}


add_pose(string pose, string data) {
    if (llListFindList(Poses, (list)pose) != -1) {
        llOwnerSay("Multiple *.SWAP* entries for pose '" + pose + "'");
    }
    Poses += (list) pose;
    Data  += (list) data;
}

set_pose(string pose) {
    Pose = pose;

    integer ix = llListFindList(Poses, (list)pose);

    if (ix == -1) {
        PoseData = ["0 1 2 3 4 5", "1 0 2 3 4 5"];
        return;
    }

    PoseData = ["0 1 2 3 4 5"] + llParseString2List(llList2String(Data, ix), ["  :  ", "  : ", " :  ", " : ", " :", ": ", ":"], []);
}

handle_swap(integer swapping) {
    integer count = llGetListLength(PoseData);
    if (count == 0) {
        return;
    }
    integer ix = SwapIx;
    string data = llList2String(PoseData, ix);
    LastPoseOrder = data;
    llMessageLinked(LINK_THIS, 0, "ORDER", data);
}


// Globals for reading card config
integer ConfigLineIndex;
list    ConfigCards;        // list of names of config cards
string  ConfigCardName;     // name of card being read
integer ConfigCardIndex;    // index of next card to read
key     ConfigQueryId;

integer next_card() {
    if (ConfigCardIndex >= llGetListLength(ConfigCards)) {
        ConfigCards = [];
        return (FALSE);
    }
    
    ConfigLineIndex = 0;
    ConfigCardName = llList2String(ConfigCards, ConfigCardIndex);
    ConfigCardIndex++;
    ConfigQueryId = llGetNotecardLine(ConfigCardName, ConfigLineIndex);
    llOwnerSay("Reading " + ConfigCardName);
    return (TRUE);
}                             


default {
    state_entry() {
        llSleep(0.25);       // give ~run a chance to shut us down
        string item;
        ConfigCards = [];
        integer n = llGetInventoryNumber(INVENTORY_NOTECARD);
        while (n-- > 0) {
            item = llGetInventoryName(INVENTORY_NOTECARD, n);
            if (llSubStringIndex(item, ".SWAP") != -1) {
                ConfigCards += (list) item;
            }
        }

        ConfigCardIndex = 0;
        ConfigCards = llListSort(ConfigCards, 1, TRUE);
        if (! next_card()) {
            state on;
        }
    }

    dataserver(key query_id, string data) {
        if (query_id != ConfigQueryId) {
            return;
        }                                
        if (data == EOF) {
            if (next_card()) {
                return;
            }
            state on;
        }

        data = llStringTrim(data, STRING_TRIM);
        if (llGetSubString(data,0,0) != "/" && llStringLength(data)) {          // skip comments and blank lines

            list ldata = llParseStringKeepNulls(data, ["  |  ","  | "," |  "," | "," |","| ","|"], []);
            string pose = llList2String(ldata, 0);
            string data = llList2String(ldata, 1);
            add_pose(pose, data);
        }
        ++ConfigLineIndex;
        ConfigQueryId = llGetNotecardLine(ConfigCardName, ConfigLineIndex);       //read next line of positions notecard
    }

    state_exit() {
        announce();
    }
}

state re_on
{
    state_entry() {
        state on;
    }
}

state on {
    state_entry() {
      init();
    }

    on_rez(integer arg) {
        state re_on;
    }
    
    link_message(integer from, integer num, string str, key dkey) {
	if (num == -45679) {
	  probability_of_win = (float) str;
	  //	  llSay(0, "win "+str);
	  return;
	}
      
        if (str == "PRIMTOUCH" || num < 0) {
            return;
        }
        if (num == 1 && str == "STOP") {
            SwapIx = 0;
            return;
        }
        if (num == 0) {
            if (str == "POSEB") {
                set_pose((string)dkey);
            } else if (str == "POSEPOS") {
	      // MODIFICATION: Randomize the swap order every time a pose is loaded
	      integer count = llGetListLength(PoseData);
	      if (count > 0) {
		// Pick a random index based on available swap configurations
		float w = llFrand(1.0);
		//llSay(0,(string)w +" "+ (string) probability_of_win);
		if (w > probability_of_win) {
		  if (SwapIx == 1) {
		    SwapIx = 0;
		    handle_swap(TRUE);
		    llSleep(0.01);
		  } else {
		    handle_swap(FALSE);
		  }
		} else {
		  if (SwapIx == 0) {
		    SwapIx = 1;
		    handle_swap(TRUE);
		    llSleep(0.01);
		  } else {
		    handle_swap(FALSE);
		  }
		}
		llMessageLinked(LINK_THIS, -3031963, LastPoseOrder,NULL_KEY);
	      } else {
		handle_swap(FALSE);
	      }
            } else if (str == "SWAP") {
                SwapIx = (integer)((string)dkey);
                handle_swap(TRUE);
            }
            return;
        }
    }
}

