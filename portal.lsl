#define Abomination (key) "17791a8e-427b-6e02-9724-7029842645ef"
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
  if (smart > 3) return "abomDumb";
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
    llSay(0, (string) agent + " " + (string) llDetectedVel(0));
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
      llRegionSayTo(agent, 321, "504|" + (string) agent);
    } else {
      cmd = "abomNew";
    }
    llRegionSayTo(Abomination, 0, cmd);
  }
}
