/*

	xobj standard description definitions
	
	The description syntax is: Syntax: TASKID$VAR1$VAR2...$$TASKID$VAR1$VAR2...
	
	Example to show text Sit On and have RLV sit on it
	D$Sit on$$SO
	
	Note that if you want to make your own obj description params, prefix them with your logo. Like jsAN for jas animation.
	
	Install instructions:
	1. Create a script, name it exactly jas Interact
	2. Include your _core.lsl file
	3. Define any config overrides you want
	4. Create a new function: integer onInteract(key obj, string task, list params){} - Return TRUE if successful
	5. Create a new function: onDesc(key obj, string text, int flags)
	6. Create a new function: integer preInteract(key obj)
	7. Create a new function: onInit(){}
	8. #include "xobj_core/classes/packages/jas Interact.lsl"

	onInteract will be raised when a user interacts (default fly up) with an object
	onDesc will be raised when the aimed at description changes or is lost
	preInteract should return false if something is preventing the player from interacting
	
	You can also create an onInit(){} function which is run as the first code of state_entry
	
	Required header scripts:
	- jas RLV
	- jas Climb
	
*/

// #define USE_EVENT_OVERRIDE to expose an evt(string script, integer evt, string data) function that is run before onEvt

// #define InteractConf$USE_ROOT			// Uses root prim instead
// #define InteractConf$ALLOW_ML_LCLICK 	// Use ml lclick as well for E
//D$Climb$$CL$<0,.7,.7,0>$c_p$c_a$c_a$ $ $<-5,-.9,0>,<-5,-.9,0>,<5,-.9,0>,<5,-.9,0>
//D$Climb$$CL$<0,0,-.7,.7>$l_p$l_a$l_a$l_d$ $<0,.5,-.5>,<0,.5,-.5>,<0,.5,.8>,<0,-.2,1.5>
#define Interact$TASK_DESC "D"				// [(str)text,(int)flags] - Text that shows on your HUD
	#define Interact$TASK_DESC$NO_SENSOR 0x1			// Prevent use of sensor, allowing only raycast to detect this
	#define Interact$TASK_DESC$ALLOW_PHANTOM 0x2		// Allow phantom detection via sensor.
	#define Interact$TASK_DESC$NO_ACTION 0x4			// Not used internally but can be used in onDesc to mark that we should not use [E].
	
	
#define Interact$TASK_TELEPORT "P"			// [(vec)offset] - Teleports you
#define Interact$TASK_INTERACT "I"			// NULL - Sends an interact com to the object
#define Interact$TASK_TRIGGER_SOUND "T"		// [(key)uuid, (float)vol=1]
#define Interact$TASK_PLAY_SOUND "S"		// [(key)uuid, (float)vol=1]
#define Interact$TASK_SITON "SO"			// (bool)root - Calls RLV to sit on the prim (or root prim if root is true), does not use cube
#define Interact$TASK_CLIMB "CL"			// (rot)rotation_offset, (str)anim_passive, (str)anim_active, (str)anim_active_down, (str)anim_dismount_top, (str)anim_dismount_bottom, (CSV)nodes, (float)climbspeed
#define Interact$TASK_WATER "WT"			// (vec)stream, (float)cyclone, (float)swimspeed_modifier, (str)windlight_preset
#define Interact$TASK_SOUNDSPACE "SS"		// (str)name, (float)vol
#define Interact$TASK_WL_PRESET "WL"		// (str)preset
#define Interact$TASK_FOOTSTEPS "tFS"		// 


#define InteractEvt$TP 1					// NULL - Raised when a TP task is raised
#define InteractEvt$onInteract 2			// (key)targ OR custom - Not built in by default, you can raise this manually if you want or define InteractConf$raiseEvent
#define InteractEvt$custom 3				// ... - Can be manually raised by the user who implements this script, generally in onInteract

// * Implemented by default. Though you might need to install a module for it.

#define InteractMethod$override 1			// (str)text, (int)flags - Overrides the text. When the user interacts, sends a callback to that script with data being [(str)text]. Use "" as text to clear
	#define Interact$OF_AUTOREMOVE 0x1			// Auto removes the override if the object that called the override is not found
#define InteractMethod$onClick 2			// (str)id, $list_actions - id is a unique identifier for your event used in removing, $list_actions is a string same as the Interact$TASK you'd expect. Only passing id unbinds
#define InteractMethod$allowWhenSitting 3	// (bool)allow - Toggles whether interacts are allowed while sitting


// #define InteractConf$usePrimSwim			// Define to use the primswim "exit water" label. onInteract receives "_PRIMSWIM_CLIMB_" from this
// #define InteractConf$maxRate 0.5			// Seconds between allowed interact attempts
// #define InteractConf$ignoreUnsit			// Prevents default action of unsitting when E hit while seated
// #define InteractConf$allowWhenSitting 	// Allows interactions when player is sitting
// #define InteractConf$raiseEvent			// Raises the InteractEvt$onInteract on interact. Data is (key)id
// #define InteractConf$soundOnFail (str)sound // Triggers a sound if interact fails
// #define InteractConf$soundOnSuccess (str)sound // Triggers a sound if interact is successful
// #define InteractConf$soundPrim (int)linknr 		// Link number to play HUD sounds for interact. Default 1

// #define Interact$addKeys(keys) runMethod((string)LINK_ROOT, "jas Interact", InteractMethod$addKeys, keys, TNN)
#define Interact$override(targ, text, callback, flags) runMethod((string)targ, "jas Interact", InteractMethod$override, [text, flags], callback)
#define Interact$onClick(targ, id, list_actions) runMethod((string)targ, "jas Interact", InteractMethod$onClick, [id, list_actions], TNN)
#define Interact$offClick(targ, id) runMethod((string)targ, "jas Interact", InteractMethod$onClick, [id], TNN)


/*

Nice presets I've found:
- [EUPHORIA} air pollution - very dark
- Wastes Midnight - Brighter dark
- Silent hill - Foggy but bright 
- Places Urbania - Misty green, fairly bright
- Nacon's nighty fog - Good for underwater
- Nacon's Fog - Bright but very blue fog
- Doomed Spaceship - Red medium fog
- Ambient dark - Incredibly dark
- [TOR] SPECIAL - Rightvision - Very green
- [TOR] SPECIAL - Dreamwalker - Very bright white fog
- Orac - fog - Grey fog
- Orac - Black fog 1 - Brighter fog
- [TOR] Night - Nocturne - Default


*/


#define getDescTaskData(desc, var, task) list var;{list split=llParseString2List(desc, ["$$"], []); list_shift_each(split, val, {list s = llParseString2List(val, ["$"], []);if(llList2String(s, 0) == task){var=llDeleteSubList(s,0,0); }}})


