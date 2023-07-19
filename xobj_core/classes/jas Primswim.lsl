/*

	For primswim to work. You also need the following modules installed for full effect:
	- A #ROOT script with control permissions
	- jas RLV, (for windlight and sprint)
	- jas Animhandler
	- jas PrimswimAux

	You will also need 2 animations, swim and swim_idle
	1. Create a new script, name it "jas Primswim"
	2. Include your _core.lsl file
	3. Define any config options you want
	4. Create a function integer checkForceStop(){return FALSE;}
	5. Define DB4 table: #define PrimSwimCfg$table <your table char>
	6. #include "xobj_core/classes/packages/jas Primswim.lsl"
	7. Compile
	
	
	
	How to install st PrimswimAux:
	1. Create a new script, name it "jas PrimswimAux"
	2. Include your _core.lsl file
	3. 
		#define PrimSwimCfg$table <same as jas Primswim>
		#include "xobj_core/classes/packages/jas PrimswimAux.lsl"
	4. Compile.
	5. Create a new prim in world, leave it as a .5 x .5 x .5 cube.
	6. Create a new script in it, name it whatever you want.
	7. Name your prim exactly: partiCat
	8. Open the script and paste all content from xobj_core/libraries/partiCatCube.lsl
	9. Compile and pick up.
	10. Make sure it's got copy permissions set.
	11. Drop it in the prim inventory of the same prim you put st PrimswimAux in
	
	Now you'll need 2 swimming animation. Name them swim and swim_idle.
	Swim will be played while swimming in a direction, swim_idle will be while you're idle in the water
	
	Your #ROOT script can how handle permissions via events:
	onEvt(string script, integer evt, list data){
		if(script == "jas Primswim" && evt == PrimswimEvt$onWaterEnter){
			STATUS_CONTROLS = CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT|CONTROL_UP|CONTROL_DOWN; 
			takeControls();
		}
		else if(script == "jas Primswim" && evt == PrimswimEvt$onWaterExit){
			STATUS_CONTROLS = 0;
			takeControls();
		}
	}
		
	Hopefully everything should work now.
	
	
	
	Usage:
	Create a box (primswim only works with boxes)
	Name the box exactly: WATER
	Make the box phantom.
	You should now be able to swim when entering it.
	
	Helper functions:
	checkForceStop() Lets you return FALSE if something is else in the HUD is preventing the user from moving under water
	
*/


#define PrimSwimCfg$table$status db4$0					// (int) primswim status flags
#define PrimSwimCfg$table$surfaceZ db4$1				// (float) water surface in region coordinates


#define PrimSwimGet$status() ((int)db4$fget(PrimSwimCfg$table, PrimSwimCfg$table$status))
#define PrimSwimGet$surfaceZ() ((float)db4$fget(PrimSwimCfg$table, PrimSwimCfg$table$surfaceZ))


#define PrimswimStatus$IN_WATER 0x1
#define PrimswimStatus$SWIMMING 0x2
#define PrimswimStatus$CAM_UNDER_WATER 0x4
#define PrimswimStatus$FULLY_SUBMERGED 0x8
#define PrimswimStatus$FEET_SUBMERGED 0x10
#define PrimswimStatus$TIMER_FAST 0x20
#define PrimswimStatus$HAS_WET_FEET 0x40
#define PrimswimStatus$CONTROLS_TAKEN 0x80
#define PrimswimStatus$AT_SURFACE 0x100
#define PrimswimStatus$CLIMBING 0x200


#define PrimswimMethod$airpockets 1				// airpocket1, airpocket2...
#define PrimswimMethod$swimSpeedMultiplier 2	// (float)speed | Allows you to swim faster or slower. 1 is default, higher is faster.
#define PrimswimMethod$particleHelper 3			// (key)helper

// Use jas Interact instead of buttons to climb out. Makes it play nicer with jas Interact
#define PrimSwimCfg$useJasInteract

// Includes
#ifndef PrimswimCfg$USE_WINDLIGHT
	#define PrimswimCfg$USE_WINDLIGHT 1		// Use RLV windlight (requires jas RLV)
#endif

// Timer tick speed
#ifndef PrimswimCfg$maxSpeed
	// While you are close to water
	#define PrimswimCfg$maxSpeed 0.25
#endif
#ifndef PrimswimCfg$minSpeed
	// While you are not close to water
	#define PrimswimCfg$minSpeed 2
#endif



// Anim defaults
#ifndef PrimswimCfg$animIdle
	#define PrimswimCfg$animIdle "swim_idle"
#endif 
#ifndef PrimswimCfg$animActive
	#define PrimswimCfg$animActive "swim"
#endif 


#ifndef PrimswimCfg$pnAirpocket
	#define PrimswimConst$pnAirpocket "AIR"
#endif
#ifndef PrimswimCfg$pnWater
	#define PrimswimConst$pnWater "WATER"
#endif


#define Primswim$airpockets(airpockets) runMethod((string)LINK_ROOT, "jas Primswim", PrimswimMethod$airpockets, airpockets, TNN)
#define Primswim$swimSpeedMultiplier(targ, multiplier) runMethod((string)(targ), "jas Primswim", PrimswimMethod$swimSpeedMultiplier, (list)multiplier, TNN)
#define Primswim$particleHelper(helper) runMethod((string)LINK_THIS, "jas Primswim", PrimswimMethod$particleHelper, (list)helper, TNN);

// events raised
#define PrimswimEvt$onWaterEnter 1		// [(int)speed, (vec)position] - Speed is a value between 0 (slowly entered water) and 2 (very rapidly)
#define PrimswimEvt$onWaterExit 2
#define PrimswimEvt$atLedge 3			// [(bool)at_ledge] - Player is at a ledge and can climb out
#define PrimswimEvt$feetWet 4			// [(bool)wet] - Feet are now wet or not
//#define PrimswimEvt$status 5			// (int)status - Status changed
#define PrimswimEvt$submerge 6			// (bool)submerged, (vec)surface_pos, (rot)surface_rot
