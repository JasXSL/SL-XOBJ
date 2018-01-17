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
//#define AnimHandlerConf$automateMeshAnim - Makes the script automatically trigger animations and sound events received from ton MeshAnim or jas MaskAnim
//#define onAnim( anim, data ) handleAnim( string anim, list data ){} - Use with AnimHandlerConf$automateMeshAnim to get an event when anim is received


#define AnimHandlerMethod$anim 0			// (str)|(arr)anim, (int)start, (float)replicate_dly, (float)duration, (int)flags - Anim can be an array of multiple animations to start/stop
	#define jasAnimHandler$animFlag$stopOnMove 0x1			// Stops the animation when the avatar moves
	#define jasAnimHandler$animFlag$randomize 0x2			// Picks one random element from anim instead of playing all
	
#define AnimHandlerMethod$remInventory 1	// [(arr)anims]
#define AnimHandlerMethod$sound 2			// [(key)sound, (float)vol, (int)type, (float)duration] - sending a non-key sound stops. Type of 0 is trigger, 1 is play and 2 is loop. If duration is > 0 then it will llStopSound after that time.. Requires AnimHandlerConf$useAudio defined


// Preprocessor shortcuts
#define AnimHandler$anim(anim, start, repDly, duration, flags) runMethod((string)LINK_SET, "jas AnimHandler", AnimHandlerMethod$anim, ([anim, start, repDly, duration, flags]), TNN)
#define AnimHandler$targAnim(targ, anim, start) runMethod((string)targ, "jas AnimHandler", AnimHandlerMethod$anim, ([anim, start]), TNN)
#define AnimHandler$targAnimFull(targ, anim, start, repDly, duration, flags) runMethod((string)targ, "jas AnimHandler", AnimHandlerMethod$anim, ([anim, start, repDly, duration, flags]), TNN)

#define AnimHandler$remInventory(assets) runMethod((string)LINK_SET, "jas AnimHandler", AnimHandlerMethod$remInventory, [mkarr(assets)], TNN)
#define AnimHandler$startSound(sound, vol, type, duration) runMethod((str)LINK_SET, "jas AnimHandler", AnimHandlerMethod$sound, [sound, vol, type, duration], TNN)
#define AnimHandler$targStartSound(targ, sound, vol, type, duration) runMethod((str)(targ), "jas AnimHandler", AnimHandlerMethod$sound, [sound, vol, type, duration], TNN)
#define AnimHandler$stopSound() runMethod((str)LINK_SET, "jas AnimHandler", AnimHandlerMethod$sound, [], TNN)








