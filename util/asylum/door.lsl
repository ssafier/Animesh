#define PARTNER "1c62e572-0450-17f0-9b4d-80344a35c06b"

integer handle;
integer channel;

key entering;

check_entry(key a) {
  list l = llGetObjectDetails(a, [OBJECT_POS]);
  vector p = (vector) l[0];
  if (p.y > 46.5) { // enter
    //    llSay(0, "enter");
    llListenControl(handle, TRUE);
    entering = a;
    llShout(321, "502+999|"+(string) a+"|" + (string) llGetKey() + "|" + (string) channel);
  } // else { // exit
  // llSay(0, "exit");
  //}
}

default {
  state_entry() {
    channel = (integer) ("0x" + llGetSubString((string) llGetLinkKey(LINK_THIS), -4, -1));
    handle = llListen(channel, "", NULL_KEY, "");
    llListenControl(handle, FALSE);
  }
			 
  touch_start(integer g) {
    check_entry(llDetectedKey(0));
  }
  collision_start(integer g) {
    check_entry(llDetectedKey(0));
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan == -100) check_entry(xyzzy);
  }
  listen(integer chan, string name, key xyzzy, string msg) {
    llListenControl(handle, FALSE);
    integer i = llSubStringIndex(msg, "|");
    if (i == -1) return;
    string mpg_val = llGetSubString(msg, i + 1, -1);
    i = llSubStringIndex(mpg_val, "+");
    if (i == -1) {
      llRegionSayTo((key) PARTNER, 2, (string) entering + "|-1");
    } else {
      i = llSubStringIndex(mpg_val, "|");
      if (i != -1) mpg_val = llGetSubString(mpg_val,0,i-1);
      llRegionSayTo((key) PARTNER, 2, (string) entering + "|" + mpg_val);
    }
  }
}
