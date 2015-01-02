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




#define Supportcube$tSetPos 1			// [(vec)pos]
#define Supportcube$tSetRot 2			// [(rot)rotation]
#define Supportcube$tForceSit 3			// [(bool)prevent_unsit, (bool)wait_for_sit]
#define Supportcube$tForceUnsit 4		// []
#define Supportcube$tDelay 5			// [(float)delay]
#define Supportcube$tRunMethod 6		// [(key)targ, (str)script, (int)method, (arr)data]

#define SupportcubeOverride$tSetPosAndRot 6		// Tunneled through override - (vec)pos, (rot)rotation

string SupportcubeBuildTask(integer task, list params){
	return llList2Json(JSON_OBJECT, ["t", task, "p", llList2Json(JSON_ARRAY, params)]);
}

#define SupportcubeBuildTeleport(pos) [SupportcubeBuildTask(Supportcube$tSetPos, [llGetPos()]), SupportcubeBuildTask(Supportcube$tDelay, [.1]), SupportcubeBuildTask(Supportcube$tForceSit, [FALSE, TRUE]), SupportcubeBuildTask(Supportcube$tSetPos, [pos]), SupportcubeBuildTask(Supportcube$tForceUnsit, [])]

// Listen override lets you send CSVs of TASK, DATA, DATA... to speed up calls
#ifndef SupportcubeCfg$listenOverride
	#define SupportcubeCfg$listenOverride 32986
#endif


