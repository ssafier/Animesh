#include "src/animesh/characters/asylum/conversation.h"

#define len 64

default {
  state_entry() {
    list l = WEAKER;
    integer stride = 4;
    string prefix = '"WEAKER-";
    integer count = 1;
    integer i;
    integer length = llGetListLength(l);
    llLinksetDataWrite(prefix+"COUNT",(string)length);
    for(i = 0; i <= length; i += stride) {
      llLinksetDataWrite(prefix+(string) count, (string)l[i]);
      llLinksetDataWrite(llGetSubString((string)l[i+1], 0, len), (string) l[i+2]);
      count++;
    }
  }
}
