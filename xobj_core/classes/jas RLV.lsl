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

// There are lots of configs you can set up, if so, define them above the st RLV.lsl include line
// Use the RLV folder system
#ifndef RLVcfg$USE_FOLDERS
	#define RLVcfg$USE_FOLDERS 1
	
	// Root folder of clothing
	#ifndef RLVcfg$FOLDER_ROOT
		#define RLVcfg$FOLDER_ROOT "Tentacle Moon"
	#endif
	
	
#endif

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
	
#endif

// Use RLV keep-attached letting you auto-reattach RLV attached objects
#ifndef RLVcfg$USE_KEEPATTACH
	#define RLVcfg$USE_KEEPATTACH 1
#endif

// Use RLV windlight
#ifndef RLVcfg$USE_WINDLIGHT
	#define RLVcfg$USE_WINDLIGHT 1
#endif






// RLV commands to send upon initialization
#ifndef RLVcfg$onInit
	#define RLVcfg$onInit "fly=n,camdistmax:10=y,tploc=n,tplure=n,setenv_preset:[TOR] NIGHT - Nocturne=force"           // RLV to be run on HUD attach
#endif

// RLV commands to send a few sec after initialization
#ifndef RLVcfg$initDly
	#define RLVcfg$initDly "setenv=n"
#endif

// RLV commands to send upon HUD detach
#ifndef RLVcfg$onRemove
	#define RLVcfg$onRemove "clear"     // RLV to be run on HUD detach
#endif

// Default windlight setting
#ifndef RLVcfg$defaultWindlight
	#define RLVcfg$defaultWindlight "[TOR] NIGHT - Nocturne"
#endif

// Default clothing layers that can be set
#ifndef RLVcfg$CLOTHLAYERS
	#define RLVcfg$CLOTHLAYERS ["Clothes", "Undies", "Genitals"]
#endif


// Shared vars
#define RLVShared$supportcube "sc"   	// Supportcube key 
#define RLVShared$windlight "wl"		// [TOR] NIGHT - Nocturne - Stores the current windlight setting




#include "xobj_core/classes/jas Supportcube.lsl" // Required

// Methods //
#define RLVMethod$setFolder 0			// str folder		Current top level folder ex #RLV/BARE/Lynx/<folder>
#define RLVMethod$setSubFolder 1		// str Subfolder	Current mid level folder ex #RLV/BARE/<subFolder>/Clothes
#define RLVMethod$cubeTask 2			// Task1, task2... - Sends supportcube tasks to the support cube, spawns one if not exists
#define RLVMethod$keepAttached 3		// (str)objName		- Forces an attachment and tries to keep it attached if detached
#define RLVMethod$remAttached 4			// (str)objName		- Removes an attachment
#define RLVMethod$setSprintPercent 5	// (float)perc 		- 0-1 Sets your current sprint energy
#define RLVMethod$cubeFlush 6			// void - Runs all cubetasks
#define RLVMethod$sprintFadeModifier 7	// (float)multiplier - Sets the multiplier of sprint fade 0.5 = 50% slower, 1.5 = 50% faster
#define RLVMethod$sprintRegenModifier 8	// (float)multiplier - Sets the multiplier of sprint regen 0.5 = 50% slower, 1.5 = 50% faster
#define RLVMethod$sitOn 9				// (key)uuid, (bool)prevent_unsit - Calls @sit on uuid
#define RLVMethod$unsit 10				// (bool)override_unsitblock - Unsits a user
#define RLVMethod$windlightPreset 11	// (str)preset
#define RLVMethod$resetWindlight 12		// Resets to config default

#define RLVMethod$limitCamDist 13		// (float)dist <0 = clear, 0 = force mouselook
#define RLVMethod$preventTP 14			// (bool)prevent
#define RLVMethod$preventFly 15			// (bool)Prevent
#define RLVMethod$addSprint 16			// (float)perc
#define RLVMethod$turnTowards 17		// (vec)region_pos - Faces the avatar towards a location

// Events
#define RLVevt$supportcubeSpawn 1			// (key)id


// Shortcuts
#define RLV$setFolder(folder) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$setFolder, [folder], TNN)
#define RLV$setSubFolder(folder) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$setSubFolder, [folder], TNN)
#define RLV$cubeTask(tasks) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$cubeTask, tasks, TNN)
#define RLV$keepAttached(item) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$keepAttached, [item], TNN)
#define RLV$remAttached(item) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$remAttached, [item], TNN)
#define RLV$sprintFadeModifier(multiplier) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$sprintFadeModifier, [multiplier], TNN)
#define RLV$sprintRegenModifier(multiplier) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$sprintRegenModifier, [multiplier], TNN)
#define RLV$sitOn(uuid, prevent_unsit) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$sitOn, [uuid, prevent_unsit], TNN)
#define RLV$unsit(override) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$unsit, [override], TNN)
#define RLV$windlightPreset(preset) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$windlightPreset, [preset], TNN)
#define RLV$resetWindlight() runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$resetWindlight, [], TNN)
#define RLV$turnTowards(pos) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$turnTowards, [pos], TNN)

#define RLV$limitCamDist(limit) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$limitCamDist, [limit], TNN)
#define RLV$preventTP(prevent) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$preventTP, [prevent], TNN)
#define RLV$preventFly(prevent) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$preventFly, [prevent], TNN)
#define RLV$addSprint(perc) runMethod((string)LINK_ROOT, "jas RLV", RLVMethod$addSprint, [perc], TNN)


