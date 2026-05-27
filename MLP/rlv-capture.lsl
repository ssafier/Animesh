// ~capture Script V1.01
// drop into a ball
//
// constants
#define DEBUG FALSE;
 
float TIMER_TIMEOUT     = 60.0;
float TIMER_LOCKED      = 900.0;
integer RANGE_CAPTURE   = 20;
 
#define RELAY_CHANNEL   = -1812221819;
 
// texts
string MSG_NO_SENSOR   = "No avatars in sensor range.";
string MSG_MENU_IN_USE = " is using the menu. Please try again in a while.";
string MSG_CHOOSE_AV   = "Choose avatar:";
string MSG_TIMEOUT     = "Dialog timeout. Please touch again to retry.";
 
// internal use
integer dialog_handle;
integer dialog_channel;
key avatar_victim = NULL_KEY;
integer channel;
 
list sensor_keys;
list sensor_names;
key avatar_menu;
 
// write a log message in DEBUG mode
log(string message)
{
  if (DEBUG) llOwnerSay("MENU: " + message);
}
 
// out a message to the user
out(string message)
{
  llSay(0, message);
}
 
capture(key avatar)
{
  relay(avatar, "@sit:" + (string)llGetKey() + "=force");
}
 
lock(key avatar)
{
  relay(avatar, "@unsit=n");
}
 
release(key avatar)
{
  relay(avatar, "@unsit=y");
  relay(avatar, "!release");
}
 
// write a message to the RLV Relay
relay(key avatar, string message)
{
  if (avatar != NULL_KEY)
    {
      llSay(RELAY_CHANNEL, llGetObjectName() + "," + (string) avatar + "," + message);
      log("RLV: " + llGetObjectName() + "," + (string) avatar + "," + message);
    }
}
 
init()
{
  dialog_channel= -(integer)(llFrand(100000 - 10000) + 10000);
  dialog_handle = llListen(dialog_channel, "", NULL_KEY, "");
  llListenControl(dialog_handle, FALSE);
  avatar_menu = NULL_KEY;
}
 
// default state
default
{
  // on state entry: show dialog
  state_entry()
    {
      init();
    }
 
  on_rez(integer start_param)
    {
      channel = start_param;
      init();
    }
 
  // av touched me
  touch_start(integer total_number)
    {
      key id = llDetectedKey(0);
 
      // check if menu is in use
      if (avatar_menu != NULL_KEY && id != avatar_menu)
	{
	  out(llKey2Name(avatar_menu) + MSG_MENU_IN_USE);
	  return;
	}
 
      avatar_menu = id;
      llSensor("", NULL_KEY, AGENT, RANGE_CAPTURE, PI);
    }
 
  // no av in sensor range
  no_sensor()
    {
      out(MSG_NO_SENSOR);
    }
 
  // some av in sensor range
  sensor(integer total_number)
    {
      sensor_keys = [];
      sensor_names = [];
      integer i;
      for(i=0; i < total_number; i++)
	{
	  key id = llDetectedKey(i);
	  string name = llKey2Name(id);
	  if (llStringLength(name) > 24)
	    {
	      name = llGetSubString(name, 0, 23);
	    }
	  sensor_keys += [id];
	  sensor_names += [name];
	  log("found: " + name);
	}
 
      // show dialog if list contains names
      if (llGetListLength(sensor_names) > 0)
	{
	  llListenControl(dialog_handle, TRUE);
	  llSetTimerEvent(TIMER_TIMEOUT);
	  llDialog(avatar_menu, MSG_CHOOSE_AV, sensor_names, dialog_channel);
	}
    }
 
  // menu selected
  listen(integer channel, string name, key id, string message)
    {
      llListenControl(dialog_handle, FALSE);
      integer index = llListFindList(sensor_names, [message]);
      if (index != -1)
	{
	  key selected = llList2Key(sensor_keys, index);
	  log ("capture " + llKey2Name(selected));
	  capture(selected);
	}
      avatar_menu = NULL_KEY;
    }
 
  // dialog timeout
  timer()
    {
      if (avatar_menu != NULL_KEY)
	{
	  out(MSG_TIMEOUT);
	  avatar_menu = NULL_KEY;
	  llListenControl(dialog_handle, FALSE);
	}
 
      llSetTimerEvent(0);
    }
 
  changed(integer change) {
    if(change & CHANGED_LINK)
      {
	key id = llAvatarOnSitTarget();
	if (id != NULL_KEY)
	  {
	    avatar_victim = id;
	    lock(avatar_victim);
	    log ("sitting: " + llKey2Name(avatar_victim));
	    state locked;
	  }
      }
  }
}
 
state locked
  {
    state_entry()
      {
	llListen(channel, "", NULL_KEY, "DIE");
	llSetTimerEvent(TIMER_LOCKED);
      }
 
    listen(integer channel, string name, key id, string message)
      {
	if (message == "DIE")
	  {
	    log ("DIE");
	    release(avatar_victim);
	  }
      }
 
    changed(integer change) {
      if(change & CHANGED_LINK)
	{
	  key id = llAvatarOnSitTarget();
	  if (id == NULL_KEY)
	    {
	      log ("unsitting " + llKey2Name(avatar_victim));
	      release(avatar_victim);
	      avatar_victim = id;
	      state default;
	    }
	}
    }
 
    timer()
      {
	release(avatar_victim);
      }
  }
