#include "include/controlstack.h"
#include "include/mat.h"

#ifndef debug
#define debug(x)
#endif

#define sequenceName(n) (string) sequences[n]
#define sequenceLength(n) (integer) sequences[n+1]
#define sequenceCount(n) (((integer) sequences[n+1] - 2) / 2)
#define sequenceAnimation(n,m) (string) sequences[n+2+(m*2)]
#define sequenceTime(n,m) (float) sequences[n+3+(m*2)]
list sequences;
integer sequence_count;

// for sequencing
integer sequence_index;
integer in_sequence_index;
string control_states;
key controlling_avi;

// ------------------------------------------
integer findSequence(string s) {
  integer x = 0;
  integer index = 0;
  while (x < sequence_count) {
    debug(sequenceName(index));
    if (sequenceName(index) == s) return index;
    ++x;
    index += sequenceLength(index);
  }
  return -1;
}
// ------------------------------------------
default {
  state_entry() {
    sequences = [];
    sequence_count = 0;
  }
  
  link_message(integer from, integer chan, string msg, key xyzzy) {
    switch(chan) {
    case registerSequence: {
      debug("register "+msg);
      list s = llParseString2List(msg,["|"],[]);
      integer l = llGetListLength(s);
      sequences = sequences + [(string) s[0], l * 2];
      ++sequence_count;
      integer x;
      for (x = 1; x < l; ++x) {
	string a = (string) s[x];
	integer colon = llSubStringIndex(a, ":");
	if (colon != -1) {
	  sequences = sequences +
	    [llGetSubString(a, 0, colon - 1),
	     (float) llGetSubString(a, colon + 1, -1)];
	} else {
	  llOwnerSay("missing time for "+a);
	}
      }
      break;
    }
    case stopSequence: {
      llSetTimerEvent(0);
      break;
    }
    case runSequence: {
      GET_CONTROL;
      string name;
      POP(name);
      sequence_index = findSequence(name);
      in_sequence_index = 0;
      if (sequence_index == -1) {
	llOwnerSay("Cannot find sequence "+name);
	return;
      }
      UPDATE_NEXT(getLeaf);
      control_states = rest;
      debug("rest "+rest);
      controlling_avi = xyzzy;
      debug("Animation "+sequenceAnimation(sequence_index, in_sequence_index));
      PUSH("SEQUENCE");
      PUSH(sequenceAnimation(sequence_index, in_sequence_index));
      debug(sequenceTime(sequence_index, in_sequence_index));
      llSetTimerEvent(sequenceTime(sequence_index, in_sequence_index));
      NEXT_STATE;
      break;
    }
    default: break;
    }
  }
  timer() {
    debug("timer "+(string) in_sequence_index);
    llSetTimerEvent(0);
    ++in_sequence_index;
    if (in_sequence_index >= sequenceCount(sequence_index)) in_sequence_index = 0;
    debug("timer "+(string) in_sequence_index + " " + (string) sequenceCount(sequence_index) + " " + (string) sequenceLength(sequence_index));
    debug(sequenceAnimation(sequence_index, in_sequence_index));
    debug("control states "+control_states);
    llMessageLinked(LINK_THIS, getLeaf,
		    control_states + "|" + sequenceAnimation(sequence_index, in_sequence_index) + "|SEQUENCE",
		    controlling_avi);
    debug(sequenceTime(sequence_index, in_sequence_index));
    llSetTimerEvent(sequenceTime(sequence_index, in_sequence_index));
  }

  changed(integer flag) {
    if (flag & CHANGED_INVENTORY) {
      sequences = [];
      sequence_count = 0;
    }
  }
}
