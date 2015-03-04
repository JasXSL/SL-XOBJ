/*
	Install
	1. Create a script in it's own prim of your HUD named st AnimHandler
	2. Include your project _core.lsl file
	3. #include "xobj_core/classes/packages/st Animhandler.lsl"
	4. Drop animations into the same prim as the script.
	
	Use AnimHandler$anim((string)anim, (int)start, (float)repeat_delay)
	
	Anim = Name of an anim in the prim's inventory
	Start = TRUE starts and FALSE stops an anim
	Repeat_delay = Trigger the animation again in x seconds, recommended 0 to disable

*/
#define AnimHandlerMethod$anim 0			// (str)anim, (int)start, (float)replicate_dly




// Preprocessor shortcuts
#define AnimHandler$anim(anim, start, repDly) runMethod((string)LINK_SET, "st AnimHandler", AnimHandlerMethod$anim, ([anim, start, repDly]), TNN)









