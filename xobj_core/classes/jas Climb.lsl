/*

	Requires the RLV module installed with the supportcube
	Requires the animhandler module installed
	
	Install.
	1. Create a new script in the root prim of your project. Name it exactly jas Climb
	2. Include your _core.lsl file
	3. Set up any config vars you want
	4. #include "xobj_core/classes/packages/jas Climb.lsl"

	See jas Interact for instructions on how to set up a prim's description to make it climbable.
	
*/

#define ClimbMethod$start 1		// [(key)ladder, (rot)rotation_offset, (str)anim_passive, (str)anim_active, (str)anim_active_down, (str)anim_dismount_top, (str)anim_dismount_bottom, (arr)nodes, (float)climbspeed, (str)evtOnStartData, (str)evtOnEndData]
#define ClimbMethod$stop 2		// void - Stops climbing



#define Climb$start(ladder, rot_offset, anim_passive, anim_active, anim_active_down, anim_dismount_top, anim_dismount_bottom, nodes, climbspeed, onStart, onEnd) runMethod((string)LINK_SET, "jas Climb", ClimbMethod$start, ([ladder, rot_offset, anim_passive, anim_active, anim_active_down, anim_dismount_top, anim_dismount_bottom, nodes, climbspeed, onStart, onEnd]), TNN)
//#define Climb$start(data) runMethod((string)LINK_ROOT, "jas Climb", ClimbMethod$start, data, TNN)
#define Climb$stop(targ) runMethod(targ, "jas Climb", ClimbMethod$stop, [], TNN)

#define ClimbEvt$start 1		// [(key)ladder, (var)onStartData]
#define ClimbEvt$end 2			// [(key)ladder, (var)onEndData]

#ifndef ClimbCfg$defaultSpeed
	#define ClimbCfg$defaultSpeed .65
#endif

// Optional function bindings
//#define ClimbCfg$onClimbStart		// Define a function that should be called when the climb data has been parsed
