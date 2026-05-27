#define Abomination (key) "fd8154a7-d9fb-5435-bb31-dcf1545b41a5"
check_entry(key a) {
  list l = llGetObjectDetails(a, [OBJECT_POS]);
  vector p = (vector) l[0];
  if (p.y > 46.5) { // enter
    llSay(0, "enter");
  } else { // exit
    llSay(0, "exit");
  }
}

default {
  touch_start(integer g) {
    check_entry(llDetectedKey(0));
  }
  collision_start(integer g) {
    check_entry(llDetectedKey(0));
  }
  link_message(integer from, integer chan, string msg, key xyzzy) {
    if (chan == -100) check_entry(xyzzy);
  }
}
