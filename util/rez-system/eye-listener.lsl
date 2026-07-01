#include "include/animesh.h"
#include "include/controlstack.h"

#ifdef DEBUGGING
#define EyeOfEkron (key) "6456374b-8b39-f398-1233-e4ba1a4a7835"
#else
#define EyeOfEkron (key) "d7313cec-6f94-8ea0-6359-c2ad0b922f52"
#endif

#define PROCESS 2005

integer handle;
integer brain;

default {
  state_entry() {
    brain = 0x922f52 + 1;
    handle = llListen(brain, "", EyeOfEkron, "");
  }
  listen(integer chan, string name, key xyzzy, string msg) {
    llMessageLinked(LINK_THIS, PROCESS, msg + "|" + (string) (EyeOfEkron), xyzzy);
  }
  object_rez(key id) {
    llRegionSayTo(EyeOfEkron, brain, (string) id);
  }
}

