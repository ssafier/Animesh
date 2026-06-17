#define CONTROLLER_CHAN -88888
#define CONTROLLER_KEY NULL_KEY

// animation flags
#define afStopAll 1
#define afCache 2
#define afReplace 4
#define afLoop 8 // loop

// Command Prefixes
#define CMD_ACTION 1
#define CMD_ERROR  2
#define CMD_STATUS 3

// Atomic Actions
#define ACT_IDLE 0
#define ACT_SIT  1
#define ACT_WALK 2
#define ACT_TALK 3
#define ACT_WANDER 4
#define ACT_POSE 5
#define ACT_WRESTLE 6
#define ACT_GREET 7


// Error Types
#define ERR_COLLISION 1
#define ERR_STUCK     2

// Object Types (for collisions)
#define TYPE_OBJECT 1
#define TYPE_AVATAR 2
#define TYPE_ACTIVE 3

#define STOP 99
#define WANDER 100
#define WanderForTime 101
#define ResetWanderTimers 102
#define WanderDone 103
#define BUMP 104
#define GOTO 105
#define COLLISION 106
#define PATH 107
#define PathDone 108
#define MoveDone 109
#define CALL 110
#define ARRIVED 111
#define SIT 112
#define SitChannel 113
#define UnSit 114
#define LOOP_WALK 115

#define DETECTED 120
#define SCAN 121
#define CANCEL_SCAN 122

#define DEFAULT_SIT_CHANNEL -91170

// UTILS
#define GET_STRENGTH 1000
#define RETURN_MAX_STRENGTH 1001

#define ProbabilityWin(avistr, astr) (1.0/(1.0 + llPow(25.0, ((avistr) - (astr))/10000.0)))

// Brain Stuff
#define PING 2026
#define PING_BACK 2027

// Config and Menu
#define doMenu 2
#define sitAvatar 3
#define getLeaf 4
#define returnLeaf 5
#define MENU_FAIL 6
#define doAnimations 10
#define registerSequence 11
#define runSequence 12
#define stopSequence 13
#define resetAnimationState 15

#define avatarSeated 49
#define WRESTLE 50
