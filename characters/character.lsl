default {
  on_rez(integer x) {
    if (x == 0) return;
    llLinksetDataWrite("strength",(string) ANIMESH_STRENGTH);
    llLinksetDataWrite("stand", STAND);
    llLinksetDataWrite("land", LAND);
    llLinksetDataWrite("walk", WALK);
#ifdef WALK_TIME
    llLinksetDataWrite("walk-loop", "0");
    llLinksetDataWrite("walk-time",(string) WALK_TIME);
#else
    llLinksetDataWrite("walk-loop", "1");
#endif
    list chat = WrestleWin;
    integer i = 0;
    integer len = llGetListLength(chat);
    llLinksetDataWrite("win-length", (string) len);
    while(i < len) {
      string s = (string) chat[i];
      ++i;
      llLinksetDataWrite("win-" + (string) i, s);
    }
    
    chat = WrestleDefeat;
    i = 0;
    len = llGetListLength(chat);
    llLinksetDataWrite("defeat-length", (string) len);
    while(i < len) {
      string s = (string) chat[i];
      ++i;
      llLinksetDataWrite("defeat-" + (string) i, s);
    }
    
    chat = GREETINGS;
    i = 0;
    len = llGetListLength(chat);
    llLinksetDataWrite("greet-length", (string) len);
    while(i < len) {
      string s = (string) chat[i];
      ++i;
      llLinksetDataWrite("hello-" + (string) i, s);
    }
    
    llMessageLinked(LINK_SET, 333,llGetStartString(),NULL_KEY);
    if (llGetInventoryType(".updater") == INVENTORY_SCRIPT) {
      llSetScriptState(".updater", FALSE);
      llRemoveInventory(".updater");
    }
  }
}
