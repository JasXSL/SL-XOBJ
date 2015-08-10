/*
	
	Mesh anim lets you cycle through object faces like frames ^.^
	cl MeshAnim does not store data hardcoded in the script, but is meant to be remoteloaded
	You need jxRemoteloader installed
	
	Usage:
	Start by looking for the MeshAnim ini event. If you're not remoteloading you can add the animation objects directly
	
	onEvt(string script, integer evt, string data){
		if(script == "toMeshAnim"){
			if(evt == evt$SCRIPT_INIT){
			
			}
		}
	}
	
	upon init you can add a new animation object
	I also recommend you make sure to rename any anims with the same name
	
	MeshAnim$rem(anim);
    MeshAnim$add(
        anim,
        llList2Json(JSON_OBJECT, ([
            "s",.01,
            "o", llList2Json(JSON_ARRAY, ([
                llList2Json(JSON_OBJECT, ([
                    "p","dPen_fck",
                    "f", llList2Json(JSON_ARRAY, ([
                        0,1,2,FRAME_AUDIO+";d2c42940-40cc-2255-737f-3b0456e3751f;.2",3
                        ,FRAME_ANIM+";[\"ctre_bridge1\",\"ctre_bridge2\",\"ctre_bridge3\"]"
                        ,4,5,6,7,8,9,
                        FRAME_AUDIO+";2b676f32-517c-61e4-042b-0345b5fe2366;.7",
                        FRAME_PARTICLES+";0",
                        10,11,12,13,14,15
                    ])) 
                ]))
            ]))
        ])),
        MeshAnimFlag$LOOPING,
        20
    ); 
    MeshAnim$startAnim("thrust");
	
	The anim object is an object with the following parameters:
	s: anim speed
	o: anim objects (array)
		Anim objects contain objects in sequence that should be animated. These objects consist of:
		p: (str)primName
		f: (array) frames & frame events
			If a frame is an integer, it's a face that will be shown
			Else it's a ; separated value, the first being an object which will be raised as a linkset event evt$MESH_ANIM_FRAME_EVENT
			
	
	
	-------------------------------------
	
	Suggested frame event handler
	Put inside onEvt if(script == "ton MeshAnim")
	
	if(evt == evt$MESH_ANIM_FRAME_EVENT){
            list split = llParseString2List(data, [";"], []);
            string task = llList2String(split,0);
            if(task == FRAME_AUDIO){
                string uuid = llList2String(split,1);
                float vol = llList2Float(split,2); 
                if(vol<=0)vol = 1;
                llTriggerSound(uuid, vol);
            }else if(task == FRAME_ANIM){
                string anim = llList2String(split,1);
                if(llJsonValueType(anim, []) == JSON_ARRAY){
                    list a = llJson2List(anim);
                    if(preanim){
                        integer p = llListFindList(a, [preanim]);
                        if(~p)a = llDeleteSubList(a, p, p);
                    }
                    anim = arrRand(a);
                    preanim = anim;
                }
                integer start = !llList2Integer(split,2);
                runMethod(llGetOwner(), "jas AnimHandler", AnimHandlerMethod$anim, [anim, start], TNN);
            }else if(task == FRAME_PARTICLES){
                if(llList2Integer(split,1) == 0){
                    lnParts("SPLAT", [  
                        PSYS_PART_FLAGS,
                            //PSYS_PART_EMISSIVE_MASK|
                            PSYS_PART_INTERP_COLOR_MASK|
                            PSYS_PART_INTERP_SCALE_MASK|
                            //PSYS_PART_BOUNCE_MASK|
                            //PSYS_PART_WIND_MASK|
                            //PSYS_PART_FOLLOW_SRC_MASK|
                            //PSYS_PART_TARGET_POS_MASK|
                            PSYS_PART_FOLLOW_VELOCITY_MASK
                            
                        ,
                        PSYS_PART_MAX_AGE, .5,
                        
                        PSYS_PART_START_COLOR, <.2,.2,.2>,
                        PSYS_PART_END_COLOR, <.1,.0,0>,
                        
                        PSYS_PART_START_SCALE,<0.0,.0,0>,
                        PSYS_PART_END_SCALE,<.1,.2,0>,  
                                        
                        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
                        
                        PSYS_SRC_BURST_RATE, 0.01,
                        
                        PSYS_SRC_ACCEL, <0,0,-1>,
                        
                        PSYS_SRC_BURST_PART_COUNT, 1,
                        
                        PSYS_SRC_BURST_RADIUS, 0.0,
                        
                        PSYS_SRC_BURST_SPEED_MIN, 0.5,
                        PSYS_SRC_BURST_SPEED_MAX, 1.,
                        
                        //PSYS_SRC_TARGET_KEY,"",
                        
                        PSYS_SRC_ANGLE_BEGIN,   0.2, 
                        PSYS_SRC_ANGLE_END,     0.2,
                        
                        PSYS_SRC_OMEGA, <0,0,0>,
                        
                        PSYS_SRC_MAX_AGE, 0.3,
                                        
                        PSYS_SRC_TEXTURE, "d53f241b-496e-6ada-936d-40d4c90541b8",
                        
                        PSYS_PART_START_ALPHA, .8,
                        PSYS_PART_END_ALPHA, 0,
                        
                        PSYS_PART_START_GLOW, 0,
                        PSYS_PART_END_GLOW, 0
                        
                    ]);
                }
            }
        }
	

*/

// Recommended standard frame events, but you can set them up any way you like
#define FRAME_AUDIO "A"         // uuid;vol or 1 if vol unset
#define FRAME_ANIM "B"          // (opt)(arr_rand)[(str)name], (bool)stop = FALSE
#define FRAME_PARTICLES "C"    // (int)particle_id


// Remoteload the latest cl MeshAnim from HUD if st Attached is initialized
//#define MeshAnimConf$remoteloadOnAttachedIni		
//#define MeshAnimConf$animStartEvent
//#define MeshAnimConf$remoteloadOnRez

								
#define MeshAnimEvt$frame 0	// Raised when a non-integer frame is discovered
#define MeshAnimEvt$agentsInRange 1		// Player is within LOD range, start animating
#define MeshAnimEvt$agentsLost 2		// Out of bounds, the animator will stop
#define MeshAnimEvt$onAnimStart 3		// (str)anim - Requires the MeshAnimConf

                                // Methods //

#define MeshAnimMethod$startAnim 0		// (str)animName
#define MeshAnimMethod$stopAnim 1		// (str)animName
#define MeshAnimMethod$stopAll 2
#define MeshAnimMethod$emulateFrameEvent 3	// (var)data
#define MeshAnimMethod$resume 4				// 
#define MeshAnimMethod$add 5				// name, data, flags, priority
#define MeshAnimMethod$rem 6				// name

                                // Obj Member Vars //
#define MeshAnimVal$name "A"
#define MeshAnimVal$frames "B"
#define MeshAnimVal$flags "C"
#define MeshAnimVal$priority "D"


#define MeshAnimFlag$LOOPING 1
#define MeshAnimFlag$PLAYING 2
#define MeshAnimFlag$DONT_HIDE_PREVIOUS 4


#ifndef MeshAnimConf$LIMIT_AGENT_RANGE
#define MeshAnimConf$LIMIT_AGENT_RANGE 0
#endif

// Method hooks
#define MeshAnim$startAnim(animName) runMethod((string)LINK_SET, "ton MeshAnim", MeshAnimMethod$startAnim, [animName], TNN)
#define MeshAnim$restartAnim(animName) runMethod((string)LINK_SET, "ton MeshAnim", MeshAnimMethod$startAnim, [animName, true], TNN)

#define MeshAnim$stopAnim(animName) runMethod((string)LINK_SET, "ton MeshAnim", MeshAnimMethod$stopAnim, [animName], TNN)
#define MeshAnim$stopAll() runMethod((string)LINK_ROOT, "ton MeshAnim", MeshAnimMethod$stopAll, [], TNN)
#define MeshAnim$resume() runMethod((string)LINK_ROOT, "ton MeshAnim", MeshAnimMethod$resume, [], TNN)

#define MeshAnim$rem(anim) runMethod((string)LINK_SET, "ton MeshAnim", MeshAnimMethod$rem, [anim], TNN)
#define MeshAnim$add(anim, data, flags, priority) runMethod((string)LINK_SET, "ton MeshAnim", MeshAnimMethod$add, [anim, data, flags, priority], TNN)





