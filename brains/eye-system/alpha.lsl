#include "include/controlstack.h"
#include "src/animesh/include/gym.h"

#define noAgents  2

string chatString(string s, string name) {
  integer idx = llSubStringIndex(s, "%s");
  if (idx == -1) return s;
  if (idx == 0) {
    return name + llGetSubString(s, 2, -1);
  } else if (idx == llStringLength(s)) {
    return llGetSubString(s,0,-3) +name;
  }
  return llGetSubString(s,0,idx-1) + name +  llGetSubString(s, idx + 2, -1);
}

string getPower(integer s, string name) {
  list quotes;
  if (s  < 300) {
    quotes = [
	      "A flickering candle enters my gaze; how pathetic, %s." ,
	      "You are barely a tremor in the silence, %s." ,
	      "Do not waste my time with such fragility, %s." ,
	      "Your insignificance is blinding, %s." ,
	      "Eye have seen insects with more resolve, %s."];
  } else if (s < 1000) {	
    quotes = [ "Still crawling in the dust, %s? How tedious." ,
	       "You possess the strength of a falling leaf, %s." ,
	       "Your potential is a rounding error, %s." ,
	       "Try not to break under the weight of your own weakness, %s." ,
	       "The Eye finds your presence... unremarkable, %s."];
  } else if (s < 2500) {	
    quotes = [ "You are improving, yet still utterly beneath me, %s." ,
	       "A minor spark in the dark; it will be snuffed out quickly, %s." ,
	       "Your struggle is cute, but ultimately meaningless, %s." ,
	       "Is this the pinnacle of your efforts, %s?" ,
	       "Eye have seen shadows with more substance than you, %s."];
  } else if (s < 5000) {	
    quotes = [ "You rise above the vermin, %s, but you are not yet a threat." ,
	       "A slight shift in the power dynamic, %s. Keep laboring." ,
	       "Eye am watching your clumsy ascent, %s." ,
	       "You show a glimmer of ambition, %s. Do not let it deceive you." ,
	       "You are barely worth the energy required to observe, %s."];
  } else if (s < 7500) {	
    quotes = [ "You are finally showing signs of life, %s. How quaint." ,
	       "Halfway to adequacy—do not falter now, %s." ,
	       "The Eye acknowledges your progress, though it remains unimpressed, %s." ,
	       "Your strength is a ripple, not a wave, %s." ,
	       "You are becoming a slightly more interesting specimen, %s."];
  } else if (s < 10000) {	
    quotes = [ "Your trajectory is measurable, %s. Do not mistake that for mastery." ,
	       "You reach for greatness, %s, but your grip is weak." ,
	       "A decent performance, %s. See that you don't stall." ,
	       "You have surpassed the rabble, %s. Now, attempt to matter." ,
	       "Eye have seen many climb this high only to shatter, %s."];
  } else if (s < 12500) {	
    quotes = [ "You are nearing the threshold, %s. Perhaps you aren't completely hopeless." ,
	       "Your power hums, %s. It is almost audible to the Eye." ,
	       "A respectable effort, %s. Eye am finally paying attention." ,
	       "You are no longer a child, %s. Prove you are an adult." ,
	       "Don't get complacent, %s. The view only gets colder from here."];
  } else if (s < 15000) {	
    quotes = [ "You stand at the precipice of my approval, %s." ,
	       "Finally, a combatant who might justify a glance, %s." ,
	       "Your potential is almost sufficient, %s." ,
	       "You have earned a modicum of respect, %s. Do not squander it." ,
	       "The Eye watches you with expectation now, %s." ];
  } else if (s < 16500) {
    quotes = ["Acceptable, %s. You have surpassed the common herd." ,
	      "You are now within the circle of the capable, %s." ,
	      "Eye see your strength, %s. It is... adequate." ,
	      "You have finally achieved something resembling true power, %s." ,
	      "Eye find your current state satisfactory, %s."];
  } else {
    quotes = ["A rare specimen indeed, %s. You exceed my demands." ,
	      "Your power resonates through this place, %s." ,
	      "An anomaly in the data, %s. The Eye respects your might." ,
	      "You are a storm in my domain, %s. A welcome force." ,
	      "Finally, someone worthy of being watched, %s."];
  }
  return chatString((string) quotes[(integer) llFrand(llGetListLength(quotes))], name);
}

#define DEPARTED "Now that "+oldName+" departs, the Eye will seek out the powerful.  "+power
#define NEWdeparted oldName+" is gone so you shall have my attention."

#define ARRIVAL oldName + ", you not strong enough to hold my attention.  "
#define ARRIVALold "I am only interested in the powerful and "+name+" is now the strongest here."
#define ARRIVALnew "I am watching you."
#define PUBLICwelcome "My attention is cast toward "+ name

#define UpdateAlpha updateAlpha

#ifndef ARRIVAL_RLV
#define ARRIVAL_RLV
#endif

key alpha;
string name;

key oldAlpha;
string oldName;

#ifndef UpdateAlpha
#define UpdateAlpha 0
#endif

#ifndef debug
#define debug(x) 
#endif

integer find(list l, key t) {
  integer i;
  integer len = llGetListLength(l);
  for (i = 0; i < len; ++i)
    if (((key) l[i]) == t) return TRUE; 
  return FALSE;
}

checkDeparted(list departed) {
  if (alpha == NULL_KEY) return;
  if (find(departed, alpha)) {
    oldName = name;
    oldAlpha = alpha;
  }
}


setAlpha(list strengths, list newbies) {
  if (llGetListLength(strengths) < 2) {
    alpha = NULL_KEY;
    return;
  }
  if (alpha == NULL_KEY ||
      alpha != (key) strengths[1]) {
    integer departed = (oldName != "");
    oldName = name;
    oldAlpha = alpha;
    debug("alpha "+(string)alpha + " " + name + " " + (string) strengths[1]);
    name = llGetDisplayName(alpha = (key) strengths[1]);

    llMessageLinked(LINK_THIS, UpdateAlpha, name, alpha);

    if (oldAlpha == NULL_KEY) {
      integer i = 0;
      ARRIVAL_RLV;
    }

    string power = getPower((integer) llJsonGetValue((string) strengths[0], ["sml"]), name);
    integer i = 3;
    integer rank = 2;
    if (departed) {
      power = DEPARTED +power;
      llRegionSayTo(alpha, 0, NEWdeparted);
    } else if (oldAlpha != NULL_KEY) {
      power = ARRIVAL +power;
      llRegionSayTo(oldAlpha, 0, ARRIVALold);
      llRegionSayTo(alpha, 0, ARRIVALnew);
    } else {
      i = 1;
      rank = 1;
    }

    llShout(areaChannel, "ALPHA:"+ (string) alpha);
    llShout(0, PUBLICwelcome);
    llRegionSayTo(alpha,0,power);
    integer len = llGetListLength(strengths);
    while (i < len) {
      if (i > 1) {
	power = "  Your rank is " + (string) rank + ".";
	llRegionSayTo((key) strengths[i], 0, power);
      }
      rank++;
      i = i + 2;
    }

  } else {
    integer len = llGetListLength(newbies);
    if (len == 0) return;
    integer j;
    for (j = 1; j < len; ++j) {
      integer i = llListFindList(strengths, [(string) newbies[j]]);
      if (i == -1) llOwnerSay("not in current");
      string power = getPower((integer) llJsonGetValue((string) strengths[i -1], ["sml"]),
			      llGetDisplayName((key) newbies[j]));
      llRegionSayTo((key) newbies[i], 0, power);
      ARRIVAL_RLV;
    }
  }
}

default {
  state_entry() {
    alpha = NULL_KEY;
    name = "";
  }

  link_message(integer from, integer chan, string msg, key xyzzy) {
    switch (chan) {
    case checkAlpha: {
      string current;
      string newbies;
      string departed;

      GET_CONTROL;
      NEXT_STATE;
      
      POP(current);
      POP(newbies);
      POP(departed);

      oldName = "";
      oldAlpha = NULL_KEY;

      debug("current " + current + " new " + newbies + " departed " + departed);
      
      checkDeparted(llParseString2List(departed,["+"],[]));
      setAlpha(llParseString2List(current,["+"],[]),
         llParseString2List(newbies,["+"],[]));
      break;
    }
    case noAgents: {
      oldAlpha = alpha = NULL_KEY;
      oldName = name = "";
      llShout(areaChannel, "ALPHA:");
      break;
    }
    default: break;
    }
  }
}

