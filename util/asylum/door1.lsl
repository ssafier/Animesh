default {
  touch_start(integer g) {
    llMessageLinked(LINK_ALL_OTHERS, -100, "", llDetectedKey(0));
  }
  collision_start(integer g) {
    llMessageLinked(LINK_ALL_OTHERS, -100, "", llDetectedKey(0));
  }
}
