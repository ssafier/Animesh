#define Abomination (key) "fd8154a7-d9fb-5435-bb31-dcf1545b41a5"
integer channel;
integer handle;
key agent;

integer getMPG(list character_rp, string attr) {
  integer i = llListFindStrided(character_rp, [attr], 0, -1, 2);
  if (i == -1) return -1;
  return (integer) character_rp[i + 1] - 1;
}

string fight(integer str, integer power, integer combat, integer smarts, integer speed) {
  if (str == 7) return "abomWeak";
  if (str == 6) return "abomSame";
  if (power > 3) return "abomPow";
  if (combat > 3) return "abomDefeat";
  if (smarts > 3) return "abomDumb";
  return "abomPlease";
}

default {
  state_entry() {
    llVolumeDetect(TRUE);
    channel = (integer)("0x"+llGetSubString((string) llGetKey(), -4, -1));
    handle = llListen(channel, "ORAC", NULL_KEY, "");
    llListenControl(handle,FALSE);
  }
  collision_start(integer g) {
    agent = llDetectedKey(0);
    if (agent == Abomination) return;
    llListenControl(handle,TRUE);
    llSay(321,"502+999|"+
	  (string) agent + "|" + (string) llGetKey() + "|" + (string) channel);
  }
  listen(integer chan, string name, key xyzzy, string msg) {
    llListenControl(handle, FALSE);
    list l = llParseString2List(msg,["|"],[]);
    string cmd;
    if ((string) l[1] != "-1") {
      list rp = llParseString2List((string) l[1], ["+"], []);
      integer strength = getMPG(rp, "strength");
      integer speed = getMPG(rp, "speed");
      integer smarts = getMPG(rp, "intelligence");
      integer combat = getMPG(rp, "combat");
      integer power = getMPG(rp, "power");
      integer invul = getMPG(rp ,"durability");
      cmd = fight(strength, power, combat, smarts, speed);
    } else {
      cmd = "abomNew";
    }
    llRegionSayTo(Abomination, 0, cmd);
  }
}
