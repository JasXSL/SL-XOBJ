/*
	
	The supportcube is a rezzed out prim that will let you force sit, position or rotate a player.
	It works together with st RLV
	See st RLV for setup instructions
	
	st RLV handles all commands to the supportcube, so there's no need to do so manually
	with one exception:
	
	Some times you might want to set the cube's pos and rotation very frequently (like in st Climb)
	For this you can use the listenOverride feature
	You can do this by calling llRegionSayTo(supportcube, llList2CSV([SupportcubeCfg$listenOverride, (vec)pos, (rot)rotation]));
	
*/

#define SupportcubeMethod$execute 1			// (arr)task_objs_in_order
// Obj: {"t":(int)type, "p":[params]}
#define SupportcubeMethod$killall 2			// NULL - kills support cubes


#ifndef Supportcube$confWaitForSit		// Wait for an avatar to sit or unsit before performing next action
	#define Supportcube$confWaitForSit 1	
#endif




// Tasks that support callbacks callback with : METHOD = SupportcubeMethod$execute, cb_data : [task, arg1, arg2...], and supplied callback string
#define Supportcube$tSetPos 1			// [(vec)pos]
#define Supportcube$tSetRot 2			// [(rot)rotation]
#define Supportcube$tForceSit 3			// [(bool)prevent_unsit, (bool)wait_for_sit]
#define Supportcube$tForceUnsit 4		// []
#define Supportcube$tDelay 5			// [(float)delay]
#define Supportcube$tRunMethod 6		// [(key)targ, (str)script, (int)method, (arr)data]
// DEPRECATED
//#define Supportcube$tTranslateTo 7		// [(vec)pos, (rot)rot, (float)time, (int)mode] - Mode defaults to FWD
//#define Supportcube$tTranslateStop 8	// 
#define Supportcube$tKFM 9				// (arr)coordinates, (arr)command - Same data as llSetKeyframedMotion
#define Supportcube$tKFMEnd 10			// void - Calls KFM_CMD_STOP and clears the buffer, making sure global position updates will be instant
#define Supportcube$tPathToCoordinates 11	// [(vec)start_pos, (rot)start_rot, (vec)end_pos, (str)anim, (str)callback, (float)speed=1, (int)flags] - Runs asynchronously. Use <0,0,0> to turn off. Tries to walk the player towards a location. Only X/Y are used.
	#define Supportcube$PTCFlag$STOP_ON_UNSIT 0x1		// Stops the walk if the player unsits
	#define Supportcube$PTCFlag$UNSIT_AT_END 0x2		// Unsits the player when the end has been reached
	#define Supportcube$PTCFlag$WARP_ON_FAIL 0x4		// Warps if it failed and the player is still seated. This will cause it to always callback true

#define SupportcubeOverride$tKFMEnd 5			// Tunneled through override - (arr)data, (arr)conf
#define SupportcubeOverride$tKFM 5				// Tunneled through override - (vec)localOffset, (rot)localOffset, (float)time
#define SupportcubeOverride$tSetPosAndRot 6		// Tunneled through override - (vec)pos, (rot)rotation


#define SupportcubeBuildTask(task, params) llList2Json(JSON_OBJECT, (["t", task, "p", llList2Json(JSON_ARRAY, params)]))

#define SupportcubeBuildTeleport(pos) [SupportcubeBuildTask(Supportcube$tSetPos, [llGetRootPosition()]), SupportcubeBuildTask(Supportcube$tDelay, [.1]), SupportcubeBuildTask(Supportcube$tForceSit, ([FALSE, TRUE])), SupportcubeBuildTask(Supportcube$tSetPos, [pos]), SupportcubeBuildTask(Supportcube$tForceUnsit, [])]

// Listen override lets you send CSVs of TASK, DATA, DATA... to speed up calls
#ifndef SupportcubeCfg$listenOverride
	#define SupportcubeCfg$listenOverride 32986
#endif


