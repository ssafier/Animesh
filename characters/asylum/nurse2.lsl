#include "src/animesh/include/animesh.h"

#define STRIDE 3
#define PARTNER "1c62e572-0450-17f0-9b4d-80344a35c06b"

integer handle;
integer brain;

string sit_animation = "Explosive animation - Sit Reading";
string stand_animation = "Explosive animation - Arm Gesture looped";
string this_way_animation  = "Explosive animation - Arm Gesture looped";

integer count;

vector home;
rotation home_rot;

key entrant;
string power;

instruct_noob() {
  list o = llGetObjectDetails(entrant,[OBJECT_POS]);
  llRotLookAt( llRotBetween( <0.0,-1.0,0.0>, llVecNorm( (vector) o[0]  - llGetPos() ) ),
	       1.0, 0.4 );
  llSleep(1.25+llFrand(1.5));
  llSay(0, "Oh, darling, look at you! You’ve signed your little forms, every single one of them. Ah yes, yes. I knew you’d see reason. You’re such a good boy to trust us.");
  llSleep(1.25+llFrand(1.5));
  o = llGetObjectDetails(entrant,[OBJECT_POS]);
  llRotLookAt( llRotBetween( <0.0,-1.0,0.0>, llVecNorm( (vector) o[0]  - llGetPos() ) ),
	       1.0, 0.4 );
  llSay(0,"Now, you listen to me, and you listen close. The doctor has worked so hard on this machine, day and night, just for you. He’s perfected it! It’s a miracle, truly it is.");
  llSleep(1.25+llFrand(1.5));
  o = llGetObjectDetails(entrant,[OBJECT_POS]);
  llRotLookAt( llRotBetween( <0.0,-1.0,0.0>, llVecNorm( (vector) o[0]  - llGetPos() ) ),
	       1.0, 0.4 );
  llSay(0,"So here is what you need to do for your Annie: do you see those big, beautiful, flashing RED buttons? I want you to press them. Don't be afraid! Just press them right down. The machine is going to read your sweet, special DNA, and then you just have to select your reconfiguration target. Whatever you want to become, dear, it’s all right there.");
  llSleep(1.25+llFrand(1.5));
  o = llGetObjectDetails(entrant,[OBJECT_POS]);
  llRotLookAt( llRotBetween( <0.0,-1.0,0.0>, llVecNorm( (vector) o[0]  - llGetPos() ) ),
	       1.0, 0.4 );
  llSay(0,"I know it looks big and scary, but I give you my solemn word, I swear it on everything holy: the machine is perfectly safe. I wouldn't lie to you. You know I'm your number one fan, don't you? Now go on. Press it.");
  llSleep(3 + llFrand(3));
  o = llGetObjectDetails(entrant,[OBJECT_POS]);
  llRotLookAt( llRotBetween( <0.0,-1.0,0.0>, llVecNorm( (vector) o[0]  - llGetPos() ) ),
	       1.0, 0.4 );
  llSay(0,"Come right this way, dear. Step along now, don't be a slowpoke!");
  stop_animations();
  llStartObjectAnimation(this_way_animation);
  count = 0;
  llSetTimerEvent(1);
}

welcome(string proto) {
  llSleep(1.25+llFrand(1.5));
  llSay(0,"Well, look at you! Ah yes, yes, I see you’ve been here before, haven't you? You’re an old hand at this!");
  list o = llGetObjectDetails(entrant,[OBJECT_POS]);
  llRotLookAt( llRotBetween( <0.0,-1.0,0.0>, llVecNorm( (vector) o[0]  - llGetPos() ) ),
	       1.0, 0.4 );
  llSleep(1.25+llFrand(1.5));
  llSay(0, "Let me just sneak a peek at your chart here... hmmm... well, my goodness! Look at those power levels of "+proto+"! My, aren't you a special one?");
  o = llGetObjectDetails(entrant,[OBJECT_POS]);
  llRotLookAt( llRotBetween( <0.0,-1.0,0.0>, llVecNorm( (vector) o[0]  - llGetPos() ) ),
	       1.0, 0.4 );  llSleep(1.25+llFrand(1.5));
  llSay(0,"Well, you are perfectly free to use the machine again if you want to. But that’s not all! The Doctor also invites you to go down and enjoy his basement dungeon. If you happen to have a prisoner with you, or if you just want to go down and visit an inmate, you just go right ahead and go for it!");
  o = llGetObjectDetails(entrant,[OBJECT_POS]);
  llRotLookAt( llRotBetween( <0.0,-1.0,0.0>, llVecNorm( (vector) o[0]  - llGetPos() ) ),
	       1.0, 0.4 );
  llSleep(1.25+llFrand(1.5));
  llSay(0,"Personally, I don't care to go down there. It is absolutely not my department!");
  o = llGetObjectDetails(entrant,[OBJECT_POS]);
  llRotLookAt( llRotBetween( <0.0,-1.0,0.0>, llVecNorm( (vector) o[0]  - llGetPos() ) ),
	       1.0, 0.4 );
  llSleep(3 + llFrand(3));
  llSay(0, "Duty calls, so I am going right back to work! There are things to tidy, charts to organize, and important matters to attend to. You just stay put and be a good little bird, you hear? I'll be keeping an eye on things!");
  o = llGetObjectDetails(entrant,[OBJECT_POS]);
  llRotLookAt( llRotBetween( <0.0,-1.0,0.0>, llVecNorm( (vector) o[0]  - llGetPos() ) ),
	       1.0, 0.4 );
  llSleep(1.25+llFrand(1.5));
}

stop_animations() {
  list animations = llGetObjectAnimationNames();
  integer i = llGetListLength(animations);
  while (i > 0) {
    --i;
    llStopObjectAnimation((string) animations[i]);
  }
}

default {
  state_entry() {
    home = llGetPos();
    home_rot = llGetRot();
    state sitting;
  }
}

state sitting {
  state_entry() {
    stop_animations();
    llSetLinkPrimitiveParamsFast(LINK_ROOT,
				 [PRIM_POSITION, home,
				  PRIM_ROTATION, home_rot]);
    llStartObjectAnimation(sit_animation);
    brain = llListen(2, "", PARTNER, "");
  }
  state_exit() {
    llListenRemove(brain);
  }
  listen(integer chan, string name, key xyzzy, string msg) {
    if (chan == 2) {
      integer i = llSubStringIndex(msg, "|");
      entrant = (key) llGetSubString(msg,0, i-1);
      if ((i + 1) >= llStringLength(msg)) {
	power = "";
      } else {
	power = llGetSubString(msg,i+1,-1);
      }
      state scan_for_entrant;
    }
  }
}

state scan_for_entrant {
  state_entry() {
    llSetTimerEvent(1);
  }
  timer() {
    llSensor("", entrant, AGENT, 96.0, PI);
  }
  sensor(integer x) {
    vector pos = llDetectedPos(0);
    if (pos.x > 16.98 &&
	pos.x < 29.33 &&
	pos.y > 34 &&
	pos.y < 45) {
      llSetTimerEvent(0);
      state greet;
    }
  }
  no_sensor() {
    state sitting;
  }
}

state greet {
  state_entry() {
    stop_animations();
    llStartObjectAnimation("Explosive animation - Sit Stand");
    llSetTimerEvent(8.6);
    llSay(0, "Oh, hello there, "+llGetDisplayName(entrant)+"! Welcome!");
    llSleep(llFrand(1.5)+1.25);
    llSay(0,"My goodness, it is just so wonderful to finally have you here. I’ve been looking forward to this all day! Come in, come right on in, and make yourself comfortable. Don't you be shy now! You just let me know if you need anything at all, because I am right here to take care of you. We are going to have the most splendid time together, I just know it!");
    llSleep(llFrand(1.5)+1.25);
    llSay(0,"Guess what I have right here in my hands? Ah yes, yes! I have your chart, dear! I’ve been reading through every single little page of it, and I must say, it is just absolutely fascinating. I’m going to keep it right here with me so I can look after you perfectly. We have to make sure everything goes exactly by the book, don't we? Of course we do!");
  }
  timer() {
    llSetTimerEvent(0);
    state stand;
  }    
}

state stand {
  state_entry() {
    stop_animations();
    llStartObjectAnimation(stand_animation);
    list o = llGetObjectDetails(entrant,[OBJECT_POS]);
    llRotLookAt( llRotBetween( <0.0,-1.0,0.0>, llVecNorm( (vector) o[0]  - llGetPos() ) ),
		 1.0, 0.4 );
    if (power == "") {
      instruct_noob();
    } else {
      integer i = llSubStringIndex(power, "proto+");
      if (i == -1) {
	instruct_noob();
      } else {
	string proto = llGetSubString(power, i + 6, -1);
	i = llSubStringIndex(proto, "+");
	if (i != -1) {
	  proto = llGetSubString(proto, 0, i - 1);
	}
	welcome(proto);
	state sitting;
      }
    }
  }
  timer() {
    ++count;
    switch(count) {
    case 5: {
      llSay(0, "That’s it, just a few more steps. There’s no need to drag your feet like a grumpy child. We haven't got all day, you know.");
      break;
    }
    case 10: {
      llSay(0, "Come along now! Don't you stand there gawking at me. It’s rude to keep people waiting when they’ve gone to such a lot of trouble for you.");
      break;
    }
    case 15: {
      llSay(0,llGetDisplayName(entrant) + "!  Are you listening to me? I said step this way! My goodness, sometimes I think you do these things just to vex me.");
      break;
    }
    case 20: {
      llSay(0, "You’re being a dirty bird, you know that? A stubborn, dirty bird! I am trying to be patient, but my patience is not a bottomless pit!");
      break;
    }
    case 30: {
      llSay(0, "Fine. You just sit there and stew in your own filth then! See if I care! The doctor and I offer you a miracle, and you treat it like total oodles of crap!");
      break;
    }
    case 45: {
      llSay(0, "I’m warning you... if you don't start moving those legs right this second, you are going to be very, very sorry. Don't you test me!");
      break;
    }
    case 55: {
      llSay(0, "Unbelievable. Just completely unbelievable. You appreciate absolutely nothing.");
      break;
    }
    case 60: {
      llSay(0, "Well, as lovely as it has been chatting with you, I can’t just stand here and dilly-dally all day long! I have a job to do, and I pride myself on being a professional.");
      llSetTimerEvent(0);
      state sitting;
      break;
    }
    default: break;
    }
    llSensor("", entrant, AGENT, 96, PI);
  }
  sensor(integer x) {
    vector pos = llDetectedPos(0);
    llRotLookAt( llRotBetween( <0.0,-1.0,0.0>, llVecNorm( pos  - llGetPos() ) ),
		 1.0, 0.4 );
    if (pos.x > 16.98 &&
	pos.x < 29.33 &&
	pos.y > 34 &&
	pos.y < 50.1) {
      if (pos.y > 44.9) {
	llSetTimerEvent(0);
	llSay(0, "Well, aren't you just the bravest little bird in the nest—let's just hope that fancy-schmancy machine doesn't scramble your special little DNA into total oodles of crap!");
	state sitting;
      }
    } else {
      llSay(0, "Oh, fine then! Just walk right on out, you ungrateful little dirty bird! See if I care if you stay exactly the way you are—just completely ordinary and boring!");
      llSetTimerEvent(0);
      state sitting;
    }
  }
  no_sensor() {
    state sitting;
  }

}
