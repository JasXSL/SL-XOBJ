// Preprocessor shortcuts
#include "xobj_core/classes/jas Remoteloader.lsl" 


// DEfaults
#ifndef onAnim
	#define onAnim( a, b )
#endif

#define TIMER_CHECK_ATTACH "a"



#ifdef Attached$automateMeshAnim
#define USE_EVENTS
integer anim_step;
integer P_SPLAT;
onEvt(string script, integer evt, list data){

	if( 
		(script == "ton MeshAnim" || script == "jas MaskAnim") && 
		evt == MeshAnimEvt$frame 
	){
		
		list split = llParseString2List(llList2String(data,0), [";"], []);
		string type = llList2String(split, 0);
		if( type == FRAME_AUDIO ){
		
			list sounds = ["e47ba69b-2b81-1ead-a354-fe8bb1b7f554", "9f81c0cb-43fc-6a56-e41e-7f932ceff1dc"];
			float vol = .5+llFrand(.5);
			if(llList2String(split, 1) != "*"){
				if(llJsonValueType(llList2String(split, 1), []) == JSON_ARRAY)sounds = llJson2List(llList2String(split, 1));
				else sounds = [llList2String(split, 1)];
			}
			if(llList2Float(split, 2)>0)vol = llList2Float(split, 2);
			key sound = randElem(sounds);
			if(sound)
				llTriggerSound(sound, vol);
				
		}
		
		else if( type == FRAME_ANIM ){
		
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
			
			
			string anim;
			integer start = true;
			
			if( llList2String(split, 1) == "*" ){
			
				if( localConfAnims != [] && llGetPermissions()&PERMISSION_TRIGGER_ANIMATION ){
				
					anim = llList2String(localConfAnims, anim_step);
					anim_step++;
					if(anim_step>=llGetListLength(localConfAnims))
						anim_step = 0;
					
				}
				
			}
			
			else{
			
				if( llGetPermissions()& PERMISSION_TRIGGER_ANIMATION ){
				
					anim = llList2String(split, 1);
					if( !llList2Integer(split, 2) && llGetListLength(split) >= 3 )
						start = false;

				}
				
			}
			
			if( anim == "" ) 
				return;
				
			if( start )
				llStartAnimation(anim);
			else
				llStopAnimation(anim);
				
			onAnim( anim, llDeleteSubList(split, 0, 0) );
			
		}
		
	}
}
#endif


timerEvent(string id, string data){
    if(id == TIMER_CHECK_ATTACH){
        if(llGetAttached()){
            multiTimer([id]);
        }else{
            //
			RLV$reqAttach();
			multiTimer([id, "", 25, FALSE]);	// Can't do it too often
        }
    }
	#ifdef Attached$removeIfSpawnerNotFound
	if(id == "SC"){
		key spawner = l2k(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0);
		if(llKey2Name(spawner) == ""){
			if(llGetAttached()){
			
				if(llGetPermissions()& PERMISSION_ATTACH)
					llDetachFromAvatar();
				else
					llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
					
			}
			else
				llDie();
		}
	}
	#endif
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
		debugCommon("Stopping because kill");
		llStopAnimation(localConfIdle);
		llSleep(.1);
	}
#endif
	llDie();
	DIE = TRUE;
    if( llGetAttached() )
		llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
}

default{
 
    on_rez(integer start){

	
		llSetStatus(STATUS_PHANTOM, TRUE);
        if( start == 1 ){
		
			llSleep(.25);
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEMP_ON_REZ, TRUE]);
			#ifndef Attached$useExtUpdate
			#ifdef Attached$remoteLoadConditions
			if( Attached$remoteLoadConditions() ){
			#endif
				integer pin = floor(llFrand(0xFFFFFFF));
				llSetRemoteScriptAccessPin(pin);
				
					#ifdef Attached$remoteloadCommand
					Attached$remoteloadCommand;
					#else
					runMethod(llGetOwner(), "jas Remoteloader", RemoteloaderMethod$load, [cls$name, pin, 2], TNN);
					#endif
			#ifdef Attached$remoteLoadConditions
			}
			#endif
			#endif
			
		}
		else{
			llResetScript();
		}
		
    }
    
    state_entry(){
	
		llSetStatus(STATUS_PHANTOM, TRUE);
        memLim(1.5);
		
		// Version checking. attaches set at v1 or later will send the message on rez
		llRegionSayTo(mySpawner(), jasAttached$INI_CHAN, "INI");
		
		if(llGetStartParameter() == 2){
            llOwnerSay("@acceptpermission=add");
            runOmniMethod(cls$name, AttachedMethod$remove, [llGetObjectName()], "");
            raiseEvent(evt$SCRIPT_INIT, "1");
            multiTimer([TIMER_CHECK_ATTACH, "", 1, TRUE]);
			#ifdef Attached$onSpawn
			Attached$onSpawn;
			#endif
		
        }
		
		
		#ifdef Attached$automateMeshAnim
		localConfCacheAnims()
		if( llGetAttached() )
			llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
			
		links_each(nr, name, 
            if(name == "SPLAT"){
                P_SPLAT = nr;
            }
        )
		#endif
		
		#ifdef Attached$removeIfSpawnerNotFound
		multiTimer(["SC", "", 5, TRUE]);
		#endif
		
		llListen(RLVcfg$ATC_CHAN, "", "", "GET");
		
		#ifdef Attached$onStateEntry
			Attached$onStateEntry
		#endif
		
		// Raise init with non-live if not live
		if( !llGetStartParameter() )
			raiseEvent(evt$SCRIPT_INIT, "0");
		
    }
	#ifdef Attached$automateMeshAnim
	attach(key id){
		if(id == llGetOwner()){
			llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
		}
	}
	#endif 
	
	
	#define LISTEN_IGNORE_EVENT
	listen(integer chan, string name, key id, string message){

		if( chan == RLVcfg$ATC_CHAN){
			idOwnerCheck
			
			if( llGetAttached() )
				return;
		
			llRequestPermissions(llGetOwner(), PERMISSION_ATTACH); \
			return;
		}
		
	#ifdef SCRIPT_IS_ROOT
	#include "xobj_core/_LISTEN.lsl"
	#endif
	}

	
    run_time_permissions(integer perm){
        
		if( perm & PERMISSION_ATTACH ){

			if( DIE )
				llDetachFromAvatar();
            else 
				llAttachToAvatarTemp(0);
				
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
		if(method$isCallback)return;
		
		if(method$byOwner && METHOD == AttachedMethod$remove){

			if(method_arg(0) == llGetObjectName() || id == "" || method_arg(0) == "*")
				kill();
		
		}
		
		if( METHOD == AttachedMethod$raiseCustomEvent )
			raiseEvent(AttachedEvt$custom, mkarr((list)id + PARAMS));
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}
 







