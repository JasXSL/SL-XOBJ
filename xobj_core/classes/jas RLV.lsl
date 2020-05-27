/*
	
	Dependencies:
		- st Supportcube
	
	The RLV script will let you do various things, and lets you turn on/off tasks before you compile
	To fully utilize the RLV script, you obviously need RLV enabled in your viewer.
	You also need to install the supportcube. Here's how to get everything up and running.
	
	Add #define SupportcubeCfg$listenOverride channel
	to your core file with channel being a random integer
	this will be used to communicate faster with your supportcube
	
	Install the support cube
	1. Create a new box, it can be any size but I recommend a default 0.5x0.5x0.5 cube. Name it "SupportCube"
	2. Create a script in it, name the script "jas Supportcube"
	3. #define LISTEN_OVERRIDE SupportcubeCfg$listenOverride
	4. #include "xobj_core/classes/jas Supportcube.lsl"
	5. Include your project _core.lsl file
	6. #include "xobj_core/classes/packages/jas Supportcube.lsl"
	7. Save and pick up the object. Make sure its got copy permissions set.
	
	It's important that they are added in that order, #define LISTEN_OVERRIDE will NOT work if it gets added AFTER _core.lsl
	
	Install jas RLV
	1. Create a new script in your HUD (root prim recommended) and named it "jas RLV"
	2. Include your _core.lsl file
	3. #include "xobj_core/classes/packages/jas RLV.lsl"
	4. Optionally you can change some config settings, do that above the includes.
	5. Compile the script.
	6. Drop the supportcube you created into the same prim as the jas RLV script.
	
	
	
*/

// #define RLVcfg$USER_EVENTS <- Ex: #define RLVcfg$USER_EVENTS onUsrEvt to raise the onUserEvt function when an event is received
// #define RLVcfg$NO_RESTRICT <- Makes all RLV methods public. Otherwise they are limited to owner

#define RLVcfg$ATC_CHAN 0xBA7
#define RLV$reqAttach() llRegionSayTo(llGetOwner(), RLVcfg$ATC_CHAN, "GET")	 // Asks if you can request an attach. Calls back "GET" on the same channel if successful.

// Use the sprint limit system
#ifndef RLVcfg$USE_SPRINT
	#define RLVcfg$USE_SPRINT 1
	
	// Limit nr of seconds a player can sprint
	#ifndef RLVcfg$limitSprint
		#define RLVcfg$limitSprint 4        
	#endif 
	
	// Name of prim to show sprint bar on
	#ifndef RLVcfg$sprintName
		#define RLVcfg$sprintName "SPRINT"  // Prim to find for sprints
	#endif
	
	// Face of the object to draw the sprint bar on
	#ifndef RLVcfg$sprintFace
		#define RLVcfg$sprintFace 1
	#endif 
	
	// Rotation of the sprint bar
	#ifndef RLVcfg$sprintFaceRot
		#define RLVcfg$sprintFaceRot 0
	#endif
	
	#ifndef RLVcfg$sprintFadeOut
		#define RLVcfg$sprintFadeOut 1
	#endif
	
	#ifndef RLVCfg$sprintGracePeriod
		#define RLVCfg$sprintGracePeriod 3
	#endif
	
	// #define RLVCfg$sprintPrimConf - Use with an llSetPrimitiveParams array for SHOW settings. Does not work with fade out
	
#endif

// Use RLV keep-attached letting you auto-reattach RLV attached objects
#ifndef RLVcfg$USE_KEEPATTACH
	#define RLVcfg$USE_KEEPATTACH 1
#endif

// Use RLV windlight. You can use ton Footsteps to integrate the floor windlight settings. This requires at least 2 prims in the linkset to use LINK_ROOT
#ifndef RLVcfg$USE_WINDLIGHT
	#define RLVcfg$USE_WINDLIGHT 1
#endif

// Use RLV cam
#ifndef RLVcfg$USE_CAM
	#define RLVcfg$USE_CAM 1
#endif

#ifndef RLVcfg$USE_FOV
	#define RLVcfg$USE_FOV 1
#endif


// RLV commands to send upon initialization
#ifndef RLVcfg$onInit
	#define RLVcfg$onInit "setenv_daytime=-1"           // RLV to be run on HUD attach
#endif

// RLV commands to send a few sec after initialization
#ifndef RLVcfg$initDly
	#define RLVcfg$initDly "setenv=n"
#endif

// RLV commands to send upon HUD detach
#ifndef RLVcfg$onRemove
	#define RLVcfg$onRemove "clear,setenv_daytime=-1"     // RLV to be run on HUD detach
#endif

// Default clothing layers that can be set
#ifndef RLVcfg$CLOTHLAYERS
	#define RLVcfg$CLOTHLAYERS ["Clothes", "Undies", "Genitals"]
#endif

#include "xobj_core/classes/jas Supportcube.lsl" // Required

// Methods //

#define RLVMethod$cubeTask 2			// Task1, task2... - Sends supportcube tasks to the support cube, spawns one if not exists
#define RLVMethod$keepAttached 3		// (str)objName		- Forces an attachment and tries to keep it attached if detached
#define RLVMethod$remAttached 4			// (str)objName		- Removes an attachment
#define RLVMethod$setSprintPercent 5	// (float)perc 		- 0-1 Sets your current sprint energy
#define RLVMethod$cubeFlush 6			// void - Runs all cubetasks
#define RLVMethod$sprintFadeModifier 7	// (float)multiplier - Sets the multiplier of sprint fade 0.5 = 50% slower, 1.5 = 50% faster
#define RLVMethod$sprintRegenModifier 8	// (float)multiplier - Sets the multiplier of sprint regen 0.5 = 50% slower, 1.5 = 50% faster
#define RLVMethod$sitOn 9				// (key)uuid, (bool)prevent_unsit - Calls @sit on uuid
#define RLVMethod$unsit 10				// (bool)override_unsitblock - Unsits a user
#define RLVMethod$windlightPreset 11	// (str)preset, (int)override
#define RLVMethod$resetWindlight 12		// Removes override windlight

#define RLVMethod$limitCamDist 13		// (float)dist <0 = clear, 0 = force mouselook
#define RLVMethod$preventTP 14			// (bool)prevent
#define RLVMethod$preventFly 15			// (bool)Prevent
#define RLVMethod$addSprint 16			// (float)perc
#define RLVMethod$turnTowards 17		// (vec)region_pos - Faces the avatar towards a location
#define RLVMethod$staticCamera 18		// (vec)region_pos, (rot)rotation - Forces camera to position and rot. If region_pos is 0 it clears
#define RLVMethod$reset 19				// void - Resets the script, internal only

#define RLVMethod$setWindlight 20		// (obj)settings. Sets windlight settings. Accepts the following parameters:
/*
	
	ambient 		(vec)Ambient
	bluedensity		(vec)BlueDen
	bluehorizon		(vec)BlueHrz
	cloudcolor		(vec)CldColr
	cloudcoverage	(float)Cld Cove
	cloudoffset 	(vec)Cloud XY/Density
	clouddetail		(vec)Cloud Detail (XY/Density)
	cloudscale		(float)Cld Scale
	cloudscroll		(vec)Cloud Scroll X/Cloud Scroll Y
	fogdensity		(float)DenMult
	fogdistance		(float)DistMult
	hazedensity		(float)HazDen
	hazehorizon		(float)HazHoz
	maxaltitude		(int)MaxAlt
	scenegamma		(float)Gamma
	starbrightness	(float)Str.Brite
	sunglowfocus	(float)SG.Foc
	sunglowsize		(float)SG.Size
	sunmooncolor	(vec)S/M Colr
	sunmoonposition	(float)Est Ang 0.25 is midday

*/
#define RLVMethod$setFov 21					// float fov. Use 0 to reset

// Events
#define RLVevt$supportcubeSpawn 1			// (key)id
#define RLVevt$cam_set 2					// (vec)pos - Raised when camera is set
#define RLVevt$cam_unset 3					// void - Camera unset
#define RLVevt$windlight_override 4			// (str)sender_script - Raised when a windlight override is received
#define RLVevt$windlight_reset 5			// (str)sender_script - Raised when a windlight override is reset


// Shortcuts
#define RLV$setFov(fov) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$setFov, (list)fov, TNN)
#define RLV$cubeTask(tasks) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$cubeTask, tasks, TNN)
#define RLV$cubeTaskOn(targ, tasks) runMethod((string)targ, "jas RLV", RLVMethod$cubeTask, tasks, TNN)
#define RLV$keepAttached(item) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$keepAttached, [item], TNN)
#define RLV$remAttached(item) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$remAttached, [item], TNN)
#define RLV$sprintFadeModifier(multiplier) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$sprintFadeModifier, [multiplier], TNN)
#define RLV$sprintRegenModifier(multiplier) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$sprintRegenModifier, [multiplier], TNN)
#define RLV$sitOn(uuid, prevent_unsit) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$sitOn, [uuid, prevent_unsit], TNN)
#define RLV$unsit(override) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$unsit, [override], TNN)
#define RLV$windlightPreset(targ, preset, override) runMethod((string)targ, "jas RLV", RLVMethod$windlightPreset, [preset, override], TNN)
#define RLV$resetWindlight(targ) runMethod((string)targ, "jas RLV", RLVMethod$resetWindlight, [], TNN)
#define RLV$turnTowards(pos) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$turnTowards, [pos], TNN)
#define RLV$targSitOn(targ, uuid, prevent_unsit) runMethod(targ, "jas RLV", RLVMethod$sitOn, [uuid, prevent_unsit], TNN)
#define RLV$targUnsit(targ, override) runMethod(targ, "jas RLV", RLVMethod$unsit, [override], TNN)
#define RLV$setCamera(targ, pos, rot) runMethod((string)targ, "jas RLV", RLVMethod$staticCamera, [pos, rot], TNN)
#define RLV$clearCamera(targ) runMethod(targ, "jas RLV", RLVMethod$staticCamera, [], TNN)
#define RLV$setWindlight(targ, settings) runMethod(targ, "jas RLV", RLVMethod$setWindlight, [settings], TNN)

#define RLV$limitCamDist(limit) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$limitCamDist, [limit], TNN)
#define RLV$preventTP(prevent) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$preventTP, [prevent], TNN)
#define RLV$preventFly(prevent) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$preventFly, [prevent], TNN)
#define RLV$addSprint(perc) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$addSprint, [perc], TNN)

#define RLV$sitTargOn(targ, uuid, prevent_unsit) runMethod((string)targ, "jas RLV", RLVMethod$sitOn, [uuid, prevent_unsit], TNN)
#define RLV$unsitTarg(targ, override) runMethod((string)targ, "jas RLV", RLVMethod$unsit, [override], TNN)
#define RLV$setSprintPercent(targ, perc) runMethod((str)targ, "jas RLV", RLVMethod$setSprintPercent, [perc], TNN)

#define RLV$reset() runMethod((str)LINK_ROOT, "jas RLV", RLVMethod$reset, [], TNN)


