#include "../../xobj_toonie/classes/ton MeshAnim.lsl"
/*
	
	Mesh anim lets you cycle through object faces like frames ^.^
	cl MaskAnim does not store data hardcoded in the script, but is meant to be remoteloaded
	You need jxRemoteloader installed

	
	upon init you can add a new animation object
	I also recommend you make sure to rename any anims with the same name
	
	Ex:
	MaskAnim$add(
		"thrust",									// Name of animation
		0.01,										// Speed of animation
		MaskAnimFlag$LOOPING,						// Flags
		20,											// Priority
		llList2Json(JSON_ARRAY, [					// Array of prim_arrays
			llList2Json(JSON_ARRAY, [				// First prim name followed by frames
				"dPen_fck", "textureUUID", 0,1,2,3,4,5,6,7
			])
		])
	)
    MaskAnim$start("thrust");

*/

// Recommended standard frame events, but you can set them up any way you like
#ifndef FRAME_AUDIO
	#define FRAME_AUDIO "A"         // uuid;vol or 1 if vol unset
	#define FRAME_ANIM "B"          // (opt)(arr_rand)[(str)name], (bool)stop = FALSE
	#define FRAME_PARTICLES "C"    // (int)particle_id
#endif

// Remoteload the latest cl MaskAnim from HUD if st Attached is initialized
//#define MaskAnimConf$remoteloadOnAttachedIni		
//#define MaskAnimConf$animStartEvent
//#define MaskAnimConf$remoteloadOnRez

								
#define MaskAnimEvt$frame MeshAnimEvt$frame	// Raised when a non-integer frame is discovered
#define MaskAnimEvt$agentsInRange MeshAnimEvt$agentsInRange		// Player is within LOD range, start animating
#define MaskAnimEvt$agentsLost MeshAnimEvt$agentsLost		// Out of bounds, the animator will stop
#define MaskAnimEvt$onAnimStart MeshAnimEvt$onAnimStart		// (str)anim - Requires the MaskAnimConf
#define MaskAnimEvt$animInstalled 100						// (str)anim - Animation has been installed

                                // Methods //

#define MaskAnimMethod$start 0				// (str)animName, (bool)restart, (bool)override - Override will start a stopped anim
#define MaskAnimMethod$stop 1				// (str)animName
#define MaskAnimMethod$pause 2				// Stops the animation and prevents new animations from firing until resume is sent
#define MaskAnimMethod$emulateFrameEvent 3	// (var)data - Sends a frame event with data
#define MaskAnimMethod$resume 4				// Unpauses the animations
#define MaskAnimMethod$add 5				// name, speed, flags, priority, data
#define MaskAnimMethod$rem 6				// name
#define MaskAnimMethod$forceInRange 7		// (bool)on - Override in range for animations

#define MaskAnimFlag$LOOPING MeshAnimFlag$LOOPING
#define MaskAnimFlag$PLAYING MeshAnimFlag$PLAYING
#define MaskAnimFlag$DONT_HIDE_PREVIOUS MeshAnimFlag$DONT_HIDE_PREVIOUS
#define MaskAnimFlag$STOP_ON_END MeshAnimFlag$STOP_ON_END				// Stops all animations and prevents any new animations from playing until MaskAnim resume is called
#define MaskAnimFlag$HIDE_PREVIOUS_PRE 0x1000							// Hides previous before it starts a new one. Will cause an invisible frame but fixes subsequent animations using the same prims
#define MaskAnimFlag$USE_EMISSIVE 0x2000								// Use emissive instead of masking
#define MaskAnimFlag$USE_BLENDING 0x4000								// Use blending instead of masking

#ifndef MaskAnimConf$LIMIT_AGENT_RANGE
	#define MaskAnimConf$LIMIT_AGENT_RANGE 0
#endif

// Method hooks
#define MaskAnim$start(animName) runMethod((string)LINK_SET, "jas MaskAnim", MaskAnimMethod$start, [animName], TNN)
#define MaskAnim$restart(animName) runMethod((string)LINK_SET, "jas MaskAnim", MaskAnimMethod$start, [animName, true], TNN)
#define MaskAnim$restartOverride(animName) runMethod((string)LINK_SET, "jas MaskAnim", MaskAnimMethod$start, [animName, TRUE, TRUE], TNN)
#define MaskAnim$emulateFrameEvent(data) runMethod((string)LINK_SET, "jas MaskAnim", MaskAnimMethod$emulateFrameEvent, [data], TNN)


#define MaskAnim$stop(animName) runMethod((string)LINK_SET, "jas MaskAnim", MaskAnimMethod$stop, [animName], TNN)
#define MaskAnim$pause() runMethod((string)LINK_ROOT, "jas MaskAnim", MaskAnimMethod$pause, [], TNN)
#define MaskAnim$resume() runMethod((string)LINK_ROOT, "jas MaskAnim", MaskAnimMethod$resume, [], TNN)

#define MaskAnim$rem(anim) runMethod((string)LINK_SET, "jas MaskAnim", MaskAnimMethod$rem, [anim], TNN)
#define MaskAnim$add(anim, speed, flags, priority, frames) runMethod((string)LINK_SET, "jas MaskAnim", MaskAnimMethod$add, [anim, speed, flags, priority, frames], TNN)

#define MaskAnim$forceInRange(on) runMethod((string)LINK_SET, "jas MaskAnim", MaskAnimMethod$forceInRange, [on], TNN)




