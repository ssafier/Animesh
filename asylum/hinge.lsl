#define Abomination (key) "fd8154a7-d9fb-5435-bb31-dcf1545b41a5"
// The fraction of the door's width to slide (0.5 = half width).
// Use a negative number to slide left.
float SLIDE_FRACTION = 0.5; 

// How many frames the animation takes. Higher = smoother but slightly slower.
integer ANIMATION_STEPS = 15; 

// The speed of the animation. Time in seconds to pause between frames.
float STEP_DELAY = 0.02; 

// --- STATE VARIABLES ---
integer g_isOpen = FALSE;
integer g_isMoving = FALSE;
vector g_closedPos;
rotation g_closedRot;

// --- FUNCTIONS ---
animate_door(integer opening) {
  g_isMoving = TRUE;
    
  // Get the size of the prim to find the width.
  // Assuming the X-axis is the width of the door (left to right).
  vector size = llGetScale();
    
  // Calculate the total slide offset to the right (+X direction)
  vector slide_local_offset = <size.x * SLIDE_FRACTION, 0.0, 0.0>;
    
  float step_fraction = 1.0 / ANIMATION_STEPS;
  integer i;
    
  // Loop through the animation frames
  for (i = 1; i <= ANIMATION_STEPS; ++i)  {
    float current_fraction = step_fraction * i;
        
    // If closing, we reverse the interpolation direction
    if (!opening)  {
      current_fraction = 1.0 - current_fraction;
    }
        
    // Calculate the current offset frame
    vector current_offset = slide_local_offset * current_fraction;
        
    // Calculate the new position to keep the slide along the local axis
    vector new_pos = g_closedPos + (current_offset * g_closedRot);
        
    // Apply the new position simultaneously. (Rotation remains unchanged for a slider)
    llSetLinkPrimitiveParamsFast(LINK_THIS, [
					     PRIM_POS_LOCAL, new_pos
					     ]);
        
    // Small pause to make the animation visible to the viewer
    llSleep(STEP_DELAY);
  }
    
  g_isOpen = opening;
  g_isMoving = FALSE;
}

default {
  state_entry() {
    // Record the starting position and rotation
    g_closedPos = llGetLocalPos();
    g_closedRot = llGetLocalRot(); 
    llListen(0,"Emil Bronsky", (key) "fd8154a7-d9fb-5435-bb31-dcf1545b41a5", "");
  }

  touch_start(integer total_number) {
    // Prevent the door from being clicked multiple times while it's still swinging
    if (g_isMoving) return;
        
    animate_door(!g_isOpen);
  }

  listen(integer chan, string name, key xyzzy, string msg) {
    llSay(0,name+" "+(string)xyzzy);
    switch(msg) {
    case "open": {
      if (!g_isOpen) {
	animate_door(TRUE);
	llSetTimerEvent(30);
      }
      break;
    }
    case "close": {
      if (g_isOpen) {
	llSetTimerEvent(0);
	animate_door(FALSE);
      }
      break;
    }
    default:break;
    }
  }
  timer() {
    llSetTimerEvent(0);
    if (g_isOpen) {
      animate_door(FALSE);
    }
  }
}
