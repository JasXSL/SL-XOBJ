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
//#define AnimHandlerConf$useAudio - Adds the AnimHandlerMethod$sound method
//#define AnimHandlerConf$suppressErrors - Suppresses errors
//#define AnimHandlerConf$allowAll - Allow from any user, not only owner


#define AnimHandlerMethod$anim 0			// (str)|(arr)anim, (int)start, (float)replicate_dly, (float)duration - Anim can be an array of multiple animations to start/stop
#define AnimHandlerMethod$remInventory 1	// [(arr)anims]
#define AnimHandlerMethod$sound 2			// [(key)sound, (float)vol, (int)type, (float)duration] - sending a non-key sound stops. Type of 0 is trigger, 1 is play and 2 is loop. If duration is > 0 then it will llStopSound after that time.. Requires AnimHandlerConf$useAudio defined


// Preprocessor shortcuts
#define AnimHandler$anim(anim, start, repDly, duration) runMethod((string)LINK_SET, "jas AnimHandler", AnimHandlerMethod$anim, ([anim, start, repDly, duration]), TNN)
#define AnimHandler$targAnim(targ, anim, start) runMethod((string)targ, "jas AnimHandler", AnimHandlerMethod$anim, ([anim, start]), TNN)
#define AnimHandler$targAnimFull(targ, anim, start, repDly, duration) runMethod((string)targ, "jas AnimHandler", AnimHandlerMethod$anim, ([anim, start, repDly, duration]), TNN)

#define AnimHandler$remInventory(assets) runMethod((string)LINK_SET, "jas AnimHandler", AnimHandlerMethod$remInventory, [mkarr(assets)], TNN)
#define AnimHandler$startSound(sound, vol, type, duration) runMethod((str)LINK_SET, "jas AnimHandler", AnimHandlerMethod$sound, [sound, vol, type, duration], TNN)
#define AnimHandler$stopSound() runMethod((str)LINK_SET, "jas AnimHandler", AnimHandlerMethod$sound, [], TNN)








