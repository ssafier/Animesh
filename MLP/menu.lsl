// MLPV2 by Learjeff Innis, based on
//MLP MULTI-LOVE-POSE V1.2 - Copyright (c) 2006, by Miffy Fluffy (BSD License)
// 15-color balls by Lizz Silverstar

integer MAX_BALLS   = 6;

string  Version      = "MLPV2.4z9";

integer b;
integer b0;
integer ballusers;
list    BallColors;
integer ch;
integer chat = 0;
integer group;
integer i;
integer menu;
integer menuusers;
integer redo = 1;
integer swap;
integer visible;
integer BallCount;
integer SaneMenuOrder;
integer ReloadOnRez;
integer Running;
integer ListenId;

integer Adjusting;
string  LastPose;

integer BallsNeeded;
key SitterBallZero = NULL_KEY;

float Volume = 1.;      // for playing sounds
float alpha;
string cmd;
string pose;
string Posemsg;     // for 'AGAIN'
key owner;
key user;
key user0;
list buttons;
list buttonindex;
list commands;
list menus;
list balls;
list users;

key  NullKey    = NULL_KEY;

list SoundNames;
list Sounds;
list LMButtons;
list LMParms;
list MenuStack = [0];     // indices to previous menus, for "BACK" command

list Scripts = [
      "~menucfg"
    , "~pos"
    , "~pose"
    , "~poser"
    , "~poser 1"
    , "~poser 2"
    , "~poser 3"
    , "~poser 4"
    , "~poser 5"
    ];

integer MenuPage;       // which page of current menu we're on, 0 for first

stop() {
    llMessageLinked(LINK_THIS,0,"POSE","0,"+(string)BallCount);        //msg to pos/pose
    llMessageLinked(LINK_THIS,0,"POSEB", "stand");
    llMessageLinked(LINK_THIS, 1, "STOP", NullKey);
    llSleep(0.5);

    killBalls();
    
    swap = 0;
    Adjusting = FALSE;
}


// check_poses() {
// }


// setup for a pose based on menu characteristics
setup_pose() {
    if (BallsNeeded) {                  // if submenu includes balls:
        if (BallCount != BallsNeeded) {
            // rezBalls();       // if not enough balls present: create balls
            integer current = BallCount;
            string posername;
        
            if (BallsNeeded == BallCount) return;
        
            while (BallCount > BallsNeeded) {
                --BallCount;
                llSay(ch + BallCount, "DIE");
                // setBallState(BallCount, FALSE);
                posername = "~poser";
                if (BallCount > 0) {
                    posername += " " + (string)BallCount;
                }
                llSleep(0.1);
                llSetScriptState(posername, FALSE);
            }
            
            while (BallCount < BallsNeeded) {
	      if (BallCount == 0) {
		llRezObject("~ball", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, ch + BallCount);
	      } else {
		llWhisper(-10101,"wrestler|"+(string) BallCount+"|"+(string) (ch + BallCount));
	      }
	      
	      // setBallState(BallCount, TRUE);
	      posername = "~poser";
	      if (BallCount > 0) {
		posername += " " + (string)BallCount;
	      }
	      llSetScriptState(posername, TRUE);
	      
	      ++BallCount;
            }
            
            // Only do this if there were no balls
            if (! current) {
	      llMessageLinked(LINK_THIS,0,"REPOS",NullKey);  //msg to pos
            }
        
            llSleep(0.2);       // give balls a chance to rez
            llSetTimerEvent(60.0);
        }
        integer ix;
        for (ix = 0; ix < BallsNeeded; ++ix) {
            llSay(ch + ix, llList2String(BallColors, ix)     // to ball: color, ballnum, adjusting
                + "|" + (string) ix
                + "|" + (string) Adjusting);
        }
        if (ballusers) setBalls("GROUP");           //if group access only
    }
}


unauth(string button, string who) {
        llDialog(user0, "\n" + button + " button allowed only for " + who, ["OK"], -1);
}


//menu partly based on Menu Engine by Zonax Delorean (BSD License)
//llDialog(user, menuname, buttons(from index to nextindex-1), channel)  
doMenu(integer inhibit_showing) {
    integer colors = llList2Integer(balls,menu);
    integer ix;
    integer mask = 0xf;
    integer shift = 0;
    BallsNeeded = 0;
    BallColors = [];
    for (ix = 0; ix < MAX_BALLS; ++ix) {
        integer bc = (colors & mask) >> ix*4;
        BallColors += (list)bc; 
        if (bc) {
            BallsNeeded += 1;
        }
        mask = mask << 4;
    }
    
    if (inhibit_showing) {
        return;
    }

    b0 = llList2Integer(buttonindex, menu);         //position of first button for this (sub)menu
    b = llList2Integer(buttonindex, menu+1);        //position of first button for next (sub)menu

    b0 += MenuPage * 12;
    if (b - b0 > 12) {
        b = b0 + 12;
    }
    
    list buttons = llList2List(buttons, b0, b - 1);
    if (SaneMenuOrder) {
        buttons =
              llList2List(buttons, -3, -1)
            + llList2List(buttons, -6, -4)
            + llList2List(buttons, -9, -7)
            + llList2List(buttons, -12, -10);
    }
    llDialog(user, Version + "\n\n" + llList2String(menus,menu), buttons, ch - 1);
    llResetTime();
}

//  say(string str) {
//      if (menuusers) llWhisper(0,str);
//      else llOwnerSay(str);
//  }

/*
Chat(string str) {
    if (! chat) return;
    string name = llGetObjectName();
    llSetObjectName(":");
    llWhisper(0, "/me " + str);
    llSetObjectName(name);
}
*/
#define Chat(x)

//  turnScriptsOnOff(integer on) {
//      if (llGetInventoryType("~sequencer") == INVENTORY_SCRIPT) {
//          llSetScriptState("~sequencer", on);
//      }
//  }

// turn ball's poser# script on or off as needed, to save cycles
//  setBallState(integer ballnum, integer on) {
//      string posername = "~poser";
//      if (ballnum > 0) {
//          posername += " " + (string)ballnum;
//      }
//      llSetScriptState(posername, on);
//      // llOwnerSay("Setting " + posername + " " + (string) on);
//      
//      //  if (Running && ballnum == 0) {
//      //      turnScriptsOnOff(on);
//      //  }
//  }

killBalls() {
    integer bix;
    for (bix = 0; bix < MAX_BALLS; ++bix) {
        llSay(ch + bix, "DIE");      //msg to balls
    }
    BallCount = 0;
    llSetTimerEvent(0.0);
}

setBalls(string cmd) {
    integer ix;
    for (ix = 0; ix < BallCount; ++ix) {
        llSay(ch + ix, cmd);      //msg to balls
    }
}


touched(integer same_group) {
    if (user0 == owner || (menuusers == 1 && same_group) || menuusers == 2) {   //0=owner 1=group 2=all
        if (user0 != user) {
            if (llGetTime() < 60.0 && user != (key)"") {
                // continMenu(user0, "");
                llDialog(user0, "\n" + llKey2Name(user)
                    + " is using the menu, continue?",
                    ["Yes","Cancel"], ch - 1);
                return;
            }
            user = user0;
            group = same_group;
        }
        // present main menu
        // mainMenu();
        MenuPage = 0;
        menu = 0;
        doMenu(FALSE);
    }
}

list OptStack;      // options stack, for sequences to push/pop

// return TRUE if caller should do menu
integer handle_cmd(string button, integer sequenced) {
   integer ix = llSubStringIndex(button, "[PUSH] ");
    if (ix == 0) {
        // push_opts(llGetSubString(button, 7, -1));
        if (llGetSubString(button, 7, -1) == "NOCHAT") {
            OptStack += (list)chat;
            chat = 0;
        }
        return FALSE;
    }
    
    if (button == "[POP]") {
        // pop option
        chat = llList2Integer(OptStack, llGetListLength(OptStack)-1);
        OptStack = llDeleteSubList(OptStack, -1, -1);
        return FALSE;
    }
    
    b = llListFindList(buttons, (list) button);                     //find position of cmd
    
    // if not found, perhaps it's a hidden menu
    if (sequenced && b < 0) {
        integer newmenu = llListFindList(menus,[ button ]);         //find submenu
        if (newmenu < 0) {
            return FALSE;        // not a menu, not a button: shouldn't ever happen
        }
        integer oldmenu = menu;
        menu = newmenu;
        doMenu(TRUE);
        setup_pose();
        menu = oldmenu;
        return FALSE;
    }
        
    string cmd = llList2String(commands,b);                         //get command

    if (cmd == "TOMENU") {
        integer newmenu = llListFindList(menus,[ button ]);         //find submenu
        if (newmenu == -1) return FALSE;
        if (sequenced) {
            integer oldmenu = menu;
            menu = newmenu;
            doMenu(TRUE);
            setup_pose();
            menu = oldmenu;
            return FALSE;
        }
        i = llList2Integer(users, newmenu); 
        if (user == owner || (i == 1 && group) || i == 2) {         //0=owner 1=group 2=all
            MenuStack = (list)menu + (MenuStack=[]) + MenuStack;
            MenuPage = 0;
            menu = newmenu;
            doMenu(sequenced);
            return FALSE;
        }
        if (i == 1) unauth(button, "group");
        else unauth(button, "owner");
        return FALSE;
    } else if (cmd == "BACK") {
        if (MenuPage) {
            --MenuPage;                                           
            doMenu(sequenced);
            return FALSE;
        }
        menu = llList2Integer(MenuStack,0);
        MenuStack = llList2List(MenuStack,1,-1);
        doMenu(sequenced);
        return FALSE;
    } else if (cmd == "MORE") {
        ++MenuPage;
        doMenu(sequenced);
        return FALSE;
    } else if ((integer)cmd > 0) {                                  //POSE
        if (Adjusting && button != pose) {
            llMessageLinked(LINK_THIS,0,"SAVE",pose);               //msg to pos/pose
            llMessageLinked(LINK_THIS,1,"SAVEPROP",NullKey);        //msg to ~props
            llSleep(5.);
        }
        setup_pose();
        Posemsg = cmd + "," + (string) BallCount;
        llMessageLinked(LINK_THIS,0,"POSE", Posemsg);               //msg to pose
        llMessageLinked(LINK_THIS,0,"POSEB", (key)button);          //msg to memory
        Chat(button);
        pose = button;
    } else if (cmd == "SWAP") {
        swap += 1;
        llMessageLinked(LINK_THIS,0,"SWAP",(key)((string)swap));              //msg to pos/pose
    } else if (cmd == "STAND") {
        if (Adjusting && button != pose) {
            llMessageLinked(LINK_THIS,0,"SAVE",pose);               //msg to pos/pose
            llMessageLinked(LINK_THIS,1,"SAVEPROP",NullKey);        //msg to ~props
            llSleep(5.);
        }
        setup_pose();
        llMessageLinked(LINK_THIS,0,"POSE","0,"+(string)BallCount);        //msg to pos/pose
        llMessageLinked(LINK_THIS,0,"POSEB", "stand");
        Chat(button);
        pose = "stand";
    } else if (cmd == "STOP") {
        Chat(button);
        stop();
        return FALSE;
    } else if (cmd == "ADJUST") {
        Adjusting = ! Adjusting;
        setBalls("ADJUST|" + (string)Adjusting);
    } else if (cmd == "HIDE") {
        setBalls("0");
    } else if (cmd == "SHOW") {
        setBalls("SHOW");
    } else if (cmd == "DUMP") {
        llMessageLinked(LINK_THIS,1,"DUMP",NullKey);
    } else if (cmd == "INVISIBLE") {
        visible = !visible;
        llSetAlpha((float)visible*alpha, ALL_SIDES);
    } else if (cmd == "REDO") {
        redo = !redo;
        if (redo) llWhisper(0, button+" ON"); else llWhisper(0, button+" OFF");
    } else if (cmd == "CHAT") {
        chat = !chat;
        if (chat) llWhisper(0, button+" ON"); else llWhisper(0, button+" OFF");
    } else if (cmd == "BALLUSERS") {
        ballusers = !ballusers;
        if (ballusers) {
            llOwnerSay(button+" GROUP");
            setBalls("GROUP");
        } else {    
            llOwnerSay(button+" ALL");
            setBalls("ALL");
        }
    } else if (cmd == "MENUUSERS") {
        if (user == owner) {
            if (!menuusers) {
                menuusers = 1;
                llOwnerSay(button+" GROUP");
            } else if (menuusers == 1) {
                menuusers = 2;
                llOwnerSay(button+" ALL");
            } else if (menuusers == 2) {
                menuusers = 0;
                llOwnerSay(button+" OWNER");
            }
        } else unauth(button, "owner");
    } else if (cmd == "RESET" || cmd == "RELOAD" || cmd == "RESTART") {
        stop();
        Chat(button);
        if (cmd == "RESET") {
            llResetScript();
        } else {
            llResetOtherScript("~memory");
            if (cmd == "RESTART") {
                llResetScript();
            }
        }
    } else if (cmd == "OFF") {
        llMessageLinked(LINK_THIS,0,"POSE","0,"+(string)BallCount);        //msg to pos/pose
        llMessageLinked(LINK_THIS,0,"POSEB", "stand");
        stop();
        if (user == owner) {
            llOwnerSay(button);
            llResetOtherScript("~run");
            llResetScript();
        }
        unauth(button, "owner");
        return FALSE;
    } else if (cmd == "VOLUME") {
        Volume += .25;
        if (Volume == 1.25) Volume -= 1.25;
        string vol = (string)Volume;
        llWhisper(0, "Volume: " + vol);
        llMessageLinked(LINK_THIS, 0, "VOLUME", (key)vol);
    } else if (llGetSubString(cmd, 0, 0) == "Z" || (cmd == "SAVE")) {    //SAVE or Z-adjust
        llMessageLinked(LINK_THIS,0,cmd,pose);                           //msg to pos/pose
        doMenu(sequenced);
        return FALSE;
    } else if (cmd == "LINKMSG") {
        // menu button to send LM to a non-MLPV2 script
        integer ix = llListFindList(LMButtons, [button]);
        if (ix != -1) {
            list lmparms = llCSV2List(llList2String(LMParms, ix));
            llMessageLinked(
                llList2Integer(lmparms, 1),     // destination link#
                llList2Integer(lmparms, 2),     // 'num' arg
                llList2String(lmparms, 3),      // 'str' arg
                user0);                         // key arg
            if (llList2Integer(lmparms,0)) {    // inhibit remenu?
                return FALSE;                         //   yes, bug out
            }
        }
    } else if (cmd == "SOUND") {
        integer ix = llListFindList(SoundNames, (list)button);
        if (ix >= 0) {
            llPlaySound(llList2String(Sounds, ix), Volume);
        }
    }
    return TRUE;
}


default {
    state_entry() {
        ch = (integer)("0x"+llGetSubString((string)llGetKey(),-4,-1));
        killBalls();

        llSleep(2.0);       // give ~run a chance to shut us down
        llSetScriptState("~menucfg", TRUE);
        
        integer ix;
        for (ix = llGetListLength(Scripts)-1; ix >= 0; --ix) {
            string script = llList2String(Scripts, ix);
            if (llGetInventoryType(script) == INVENTORY_SCRIPT) {
                llResetOtherScript(script);
            }
        }
        alpha = llGetAlpha(0);                                //store object transparancy (alpha)
        if (alpha < 0.1) alpha = 0.5; else visible = 1;       //if invisible store a visible alpha
    }

    link_message(integer from, integer num, string str, key id) {
        if (from != llGetLinkNumber()) { return; }
        if (num >= 0) { return;}
        
        // LMs from ~memory, passing configuration
        if (num == -1) {
            buttons = llCSV2List(str);
        } else if (num == -2) {
            commands = llCSV2List(str);
        } else if (num == -3) {
            menus = llCSV2List(str);
        } else if (num == -4) {
            buttonindex = llCSV2List(str);
        } else if (num == -5) {
            balls = llCSV2List(str);
        } else if (num == -6) {
            users = llCSV2List(str);
        } else if (num == -7) {
            LMButtons = llCSV2List(str);
        } else if (num == -8) {
            LMParms = llParseStringKeepNulls(str, ["|"], []);
        } else if (num == -9) {
            SoundNames = llCSV2List(str);
        } else if (num == -10) {
            Sounds = llCSV2List(str);
        } else if (num == -20) {
            list args = llCSV2List(str);
            redo            = (integer) llList2String(args,0);
            chat            = (integer) llList2String(args,1);
            ballusers       = (integer) llList2String(args,2);
            menuusers       = (integer) llList2String(args,3);
            SaneMenuOrder   = (integer) llList2String(args,4);
            ReloadOnRez     = (integer) llList2String(args,5);

            state on;
        }
    }

    state_exit() {
        llOwnerSay("("+llGetScriptName()+": "+(string)llGetFreeMemory()+" bytes free)");
        llWhisper(0, Version + ": READY");
    }
}

state re_on {
    state_entry() {
        state on;
    }
}

state on {
    state_entry() {
        ch = (integer)("0x"+llGetSubString((string)llGetKey(),-4,-1));
        owner = llGetOwner();
        ListenId = llListen(ch - 1, "", NullKey, "");                      //listen for pressed buttons
        // llWhisper(0, "Channel: " + (string)ch);

        killBalls();

        Running = TRUE;
        llMessageLinked(LINK_SET, -11003, "READY", NullKey);
    }
    
    on_rez(integer arg) {
        if (ReloadOnRez) {
            llResetScript();
        }
        BallCount = 0;
        // turnScriptsOnOff(TRUE);
        llSetTimerEvent(0.0);
        
        state re_on;
    }

    touch_start(integer tcount) {
        user0 = llDetectedKey(0);
	// MODIFICATION: Lock menu to the person sitting on Ball 0
        if (SitterBallZero != NULL_KEY && user0 != SitterBallZero) {
            llRegionSayTo(user0, 0, "Only the avatar seated on the main poseball can use this menu.");
            return;
        }
        touched(llDetectedGroup(0));
    }
    
    listen(integer channel, string name, key id, string button) {
        if (id != user) {
            if (button == "Yes") {
                user = id;
                group = llSameGroup(user0);
                // present main menu
                // mainMenu();
                MenuPage = 0;
                menu = 0;
                doMenu(FALSE);
            } else if (button != "Cancel") {
                // continMenu(id, "Selection cancelled because ");
                llDialog(id, "\nSelection cancelled because "
                    + llKey2Name(user)
                    + " is using the menu, continue?",
                    ["Yes","Cancel"], ch - 1);

            }
            return;
        }
        if (handle_cmd(button, FALSE) && redo) doMenu(FALSE);
    }


    link_message(integer from, integer num, string str, key id) {
      // MODIFICATION: Track who sits on Ball 0
        if (num == -11000) { 
            list parts = llParseString2List(str, ["|"], []);
            if (((integer)(string)parts[0]) == 0) { // If it's Ball 0
                SitterBallZero = id;
                user = id; // Automatically hand over the active menu session
		setBalls("SITTER|" + (string)SitterBallZero);
            }
            return;
        }
        if (num == -11001) {
            if ((integer)str == 0) { // If Ball 0 stood up
                SitterBallZero = NULL_KEY;
                if (user == id) user = NULL_KEY; // Clear active menu session
		setBalls("SITTER|" + (string)NULL_KEY);
		killBalls();
            }
            return;
        }
        if (str == "PRIMTOUCH") {
            user0 = id;
            touched(num);
            return;
        }
        if (num == 0 && str == "AGAIN") {
            llMessageLinked(LINK_THIS,0,"POSE", Posemsg);           //msg to pose
            llMessageLinked(LINK_THIS,0,"POSEB", (key)pose);        //msg to memory
            return;
        }
        if (num == -12002) {
            handle_cmd(str, TRUE);
            return;
        }
    }

    timer() {
        setBalls("LIVE");           //msg to balls: stay alive
    }
}    
