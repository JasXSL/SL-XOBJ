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
	5. #include "xobj_core/classes/packages/st Primswim.lsl"
	6. Compile
	
	
	
	How to install st PrimswimAux:
	1. Create a new script, name it "jas PrimswimAux"
	2. Include your _core.lsl file
	3. #include "xobj_core/classes/packages/jas PrimswimAux.lsl"
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

#define PrimswimMethod$airpockets 1				// airpocket1, airpocket2...
#define PrimswimMethod$swimSpeedMultiplier 2	// (float)speed | Allows you to swim faster or slower. 1 is default, higher is faster.
#define PrimswimMethod$particleHelper 3			// (key)helper

// Includes
#ifndef PrimswimCfg$USE_WINDLIGHT
	#define PrimswimCfg$USE_WINDLIGHT 1		// Use RLV windlight (requires jas RLV)
#endif

// Timer tick speed
#ifndef PrimswimCfg$maxSpeed
	// While you are close to water
	#define PrimswimCfg$maxSpeed .1
#endif
#ifndef PrimswimCfg$minSpeed
	// While you are not close to water
	#define PrimswimCfg$minSpeed 5
#endif

// Sound defaults
#ifndef PrimswimCfg$splashBig
	#define PrimswimCfg$splashBig "cb50db39-8fb7-acd2-21e7-ef37cc2e0030"
#endif 
#ifndef PrimswimCfg$splashMed
	#define PrimswimCfg$splashMed "58bab621-cbec-175a-2b55-fc2810e96d7c"
#endif
#ifndef PrimswimCfg$splashSmall
	#define PrimswimCfg$splashSmall "0eccd45f-8a31-1263-c4c2-cbe80a27696b"
#endif

#ifndef PrimswimCfg$soundExit
	#define PrimswimCfg$soundExit "2ade5961-3b75-f8cf-ca78-7f64cd804572"
#endif
#ifndef PrimswimCfg$soundStroke
	#define PrimswimCfg$soundStroke "975f7f5d-320c-94a7-e31f-1cc5547081e8"
#endif
#ifndef PrimswimCfg$soundSubmerge
	#define PrimswimCfg$soundSubmerge "c72c63dc-7ca2-fde7-41d8-6f63b3360820"
#endif

#ifndef PrimswimCfg$soundFootstepsShallow
	#define PrimswimCfg$soundFootstepsShallow ["d2a62376-8569-274d-3378-b33028915845", "88179970-4fb8-9fe8-c1c0-c6c8a112ede8", "200548aa-c2c7-c32c-77fc-6ad9acef65a9"]
#endif
#ifndef PrimswimCfg$soundFootstepsMed
	#define PrimswimCfg$soundFootstepsMed ["6ff37e21-b76e-45c5-bb17-0f40af500b50", "d7e3be48-bdeb-6e7e-644e-6cfaee33effc", "d69f45ec-346b-bd5c-2b62-0de4fc60a5c0", "53bbd8c6-4e49-88e0-006c-7ce6987db83c"]
#endif
#ifndef PrimswimCfg$soundFootstepsDeep
	#define PrimswimCfg$soundFootstepsDeep ["21f9d648-dab6-e8aa-fc96-20f516061852", "0c21ae4c-f542-4e44-baa5-7f3d9b9600e3", "3b8f13f2-727b-e80c-7d25-28c9601bf651", "a5048f46-2b7f-8ba4-db08-e962e6c0f9c8"]
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

