

// Preprocessor shortcuts
#include "xobj_core/classes/jas Remoteloader.lsl" 


#define TIMER_CHECK_ATTACH "a"



#ifdef Attached$automateMeshAnim
#define USE_EVENTS
integer anim_step;
integer P_SPLAT;
onEvt(string script, integer evt, list data){
	if(script == "ton MeshAnim" && evt == MeshAnimEvt$frame){
		
		list split = llParseString2List(llList2String(data,0), [";"], []);
		string type = llList2String(split, 0);
		if(type == FRAME_AUDIO){
			list sounds = ["e47ba69b-2b81-1ead-a354-fe8bb1b7f554", "9f81c0cb-43fc-6a56-e41e-7f932ceff1dc"];
			float vol = .5+llFrand(.5);
			if(llList2String(split, 1) != "*"){
				if(llJsonValueType(llList2String(split, 1), []) == JSON_ARRAY)sounds = llJson2List(llList2String(split, 1));
				else sounds = [llList2String(split, 1)];
			}
			if(llList2Float(split, 2)>0)vol = llList2Float(split, 2);
			llTriggerSound(randElem(sounds), vol);
		}
		else if(type == FRAME_ANIM){
			llLinkParticleSystem(P_SPLAT, [
                PSYS_PART_MAX_AGE,.4, // max age
                PSYS_PART_FLAGS, 
                    PSYS_PART_EMISSIVE_MASK|
                    PSYS_PART_INTERP_COLOR_MASK|
                    PSYS_PART_INTERP_SCALE_MASK|
                    //PSYS_PART_RIBBON_MASK|
                    PSYS_PART_FOLLOW_VELOCITY_MASK
                    , // flags, glow etc
                PSYS_PART_START_COLOR, <1, 1, 1.>, // startcolor
                PSYS_PART_END_COLOR, <1, 1, 1.>, // endcolor
                PSYS_PART_START_SCALE, <0., 0., 0>, // startsize
                PSYS_PART_END_SCALE, <0.08, 0.3, 0>, // endsize
                PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE, // pattern
                PSYS_SRC_BURST_RATE, 0.01, // rate
                PSYS_SRC_ACCEL, <0,0,-1>,  // push
                PSYS_SRC_BURST_PART_COUNT, 3, // count
                PSYS_SRC_BURST_RADIUS, 0.03, // radius
                PSYS_SRC_BURST_SPEED_MIN, .0, // minSpeed
                PSYS_SRC_BURST_SPEED_MAX, .5, // maxSpeed
                // PSYS_SRC_TARGET_KEY, NULL_KEY, // target
                PSYS_SRC_OMEGA, <0., 0., 0.>, // omega
                PSYS_SRC_MAX_AGE, 0.25, // life
                PSYS_SRC_TEXTURE, "dcab6cc4-172f-e30d-b1d0-f558446f20d4", // texture
                
                PSYS_PART_START_ALPHA, .3, // startAlpha
                PSYS_PART_END_ALPHA, 0.0, // endAlpha
                PSYS_PART_START_GLOW, 0.05,
                PSYS_PART_END_GLOW, 0.0,
                
                PSYS_SRC_ANGLE_BEGIN, PI_BY_TWO-.5, // angleBegin
                PSYS_SRC_ANGLE_END, PI_BY_TWO-.5 // angleend

            ]);
			if(llList2String(split, 1) == "*"){
				if(localConfAnims != [] && llGetPermissions()&PERMISSION_TRIGGER_ANIMATION){
					llStartAnimation(llList2String(localConfAnims, anim_step));
					anim_step++;
					if(anim_step>=llGetListLength(localConfAnims))anim_step = 0;
				}
			}
			else{
				if(llGetPermissions()& PERMISSION_TRIGGER_ANIMATION){
					if(llList2Integer(split, 2) || llGetListLength(split)<3)llStartAnimation(llList2String(split, 1));
					else llStopAnimation(llList2String(split, 1));
				}
			}
		}
	}
}
#endif


timerEvent(string id, string data){
    if(id == TIMER_CHECK_ATTACH){
        if(llGetAttached()){
            multiTimer([id]);
        }else{
            llOwnerSay("@acceptpermission=add");
            llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
        }
    }
}

#ifdef Attached$useOverride
onListenOverride(integer chan, key id, string message){
	#ifdef Attached$detachHash
	if(message == Attached$detachHash){
		kill();
	}
	#endif
} 
#endif

integer DIE;

kill(){
#ifdef Attached$automateMeshAnim
	if(localConfIdle != "" && llGetPermissions() & PERMISSION_TRIGGER_ANIMATION){
		llStopAnimation(localConfIdle);
		llSleep(.1);
	}
#endif
	llDie();
	DIE = TRUE;
    if(llGetAttached())llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
}

default
{ 
    on_rez(integer start){
		llSetStatus(STATUS_PHANTOM, TRUE);
        if(start == 1){
			llSleep(.25);
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEMP_ON_REZ, TRUE]);
			#ifndef Attached$useExtUpdate
            integer pin = llFloor(llFrand(0xFFFFFFF));
			llSetRemoteScriptAccessPin(pin);
			
				#ifdef Attached$remoteloadCommand
				Attached$remoteloadCommand;
				#else
				runMethod(llGetOwner(), "jas Remoteloader", RemoteloaderMethod$load, [cls$name, pin, 2], TNN);
				#endif
			#endif
		}	 
    }
    
    state_entry()
    {
		initiateListen();
		llSetStatus(STATUS_PHANTOM, TRUE);
        memLim(1.5);
		
		if(llGetStartParameter() == 2){
            llOwnerSay("@acceptpermission=add");
            runOmniMethod(cls$name, AttachedMethod$remove, [llGetObjectName()], "");
            raiseEvent(evt$SCRIPT_INIT, "");
            multiTimer([TIMER_CHECK_ATTACH, "", 1, TRUE]);
			#ifdef Attached$onSpawn
			Attached$onSpawn;
			#endif
		
        }
		
		
		#ifdef Attached$automateMeshAnim
		localConfCacheAnims()
		if(llGetAttached())llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
		links_each(nr, name, 
            if(name == "SPLAT"){
                P_SPLAT = nr;
            }
        )
		
		#endif
    }
	#ifdef Attached$automateMeshAnim
	attach(key id){
		if(id == llGetOwner()){
			llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
		}
	}
	#endif 
	
	#include "xobj_core/_LISTEN.lsl"
    
    run_time_permissions(integer perm){
        if(perm & PERMISSION_ATTACH){
			if(DIE)llDetachFromAvatar();
            else llAttachToAvatarTemp(0);
        }
		#ifdef Attached$automateMeshAnim
		if(perm & PERMISSION_TRIGGER_ANIMATION){
			if(localConfIdle)
				llStartAnimation(localConfIdle);
		}
		#endif
    }

    timer(){multiTimer([]);}

    #include "xobj_core/_LM.lsl"
        /*
            Included in all these calls:
            METHOD - (int)method
            INDEX - (int)obj_index
            PARAMS - (var)parameters
            SENDER_SCRIPT - (var)parameters
            CB - The callback you specified when you sent a task
        */
		if(method$byOwner){
			if(METHOD == AttachedMethod$remove){
				if(method_arg(0) == llGetObjectName() || id == "" || method_arg(0) == "*"){
					kill();
				}
            }
		}
        
        if(nr == METHOD_CALLBACK){ 
            
        }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}
 







