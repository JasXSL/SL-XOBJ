#define USE_EVENTS
#include "xobj_core/classes/jas Interact.lsl"
#include "xobj_core/classes/jas RLV.lsl"
#include "xobj_core/classes/jas Climb.lsl"

// TWEAKABLE VALUES  
// List of additional (string)keys to allow
list additionalAllow;
integer ALLOW_ALL_AGENTS;				// Makes all agents use a CUSTOM type interact, regardless of additionalAllow

integer BFL;


#define BFL_RECENT_CLICK 1      		// Recently interacted
#define BFL_OVERRIDE_DISPLAYED 0x2		// Override has been shown
#define BFL_PRIMSWIM_LEDGE 0x4			// Requires InteractConf$usePrimSwim set. Shows a message if you're at a ledge you can climb out from
#define BFL_ALLOW_SITTING 0x8			// Allow when sitting


#define TIMER_RECENT_CLICK "c"

integer pInteract;

string targDesc;
key targ;
key real_key;						// If ROOT is used, then this is the sublink. You can use this global in onInteract
integer held;

list OVERRIDE;						// [(str)Override_text, (key)sender, (str)senderScript, (str)CB, (int)flags]
list ON_INTERACT = [];				// (str)id, (str)datastring - Stuff to be run on interact


list NEARBY;

onEvt(string script, integer evt, list data){ 
	#ifdef USE_EVENT_OVERRIDE
	evt(script, evt, data);
	#endif
    if( script == "#ROOT" ){
	
		if(
			evt == evt$BUTTON_RELEASE && 
			llList2Integer(data,0)&(CONTROL_UP
			#ifdef InteractConf$ALLOW_ML_LCLICK
				| CONTROL_ML_LBUTTON
			#endif
			)
		){
			if( BFL&BFL_RECENT_CLICK )
				return;
			
			if( !preInteract(targ) )
				return;
			
			while(ON_INTERACT){
				list split = llParseString2List(llList2String(ON_INTERACT, 1), ["$$"], []);
				ON_INTERACT = llDeleteSubList(ON_INTERACT, 0, 1);
				list_shift_each(split, val,
					list spl = explode("$", val);
					onInteract("", l2s(spl,0), llDeleteSubList(spl, 0, 0));
				)
			}
			
			#ifndef InteractConf$ignoreUnsit
			integer ainfo = llGetAgentInfo(llGetOwner());
			if(ainfo&AGENT_SITTING){
				if(ainfo&AGENT_SITTING){
					RLV$unsit(FALSE);
				}
				return;
			}
			#endif
			
			
			
			BFL = BFL|BFL_RECENT_CLICK;
			multiTimer([TIMER_RECENT_CLICK, "", 
			#ifdef InteractConf$maxRate
			InteractConf$maxRate
			#else
			1
			#endif
			, FALSE]);
			
			
			if(OVERRIDE){
				
				onInteract("", llList2String(OVERRIDE, 0), []);						// Always run this before
				sendCallback(llList2Key(OVERRIDE, 1), llList2String(OVERRIDE, 2), InteractMethod$override, mkarr([llList2String(OVERRIDE, 0)]), llList2String(OVERRIDE, 3));
				return;
			}
			
			
			
			list actions = llParseString2List(targDesc, ["$$"], []);
			
			#ifdef InteractConf$usePrimSwim
			// Add a dummy action if at ledge
			if( BFL&BFL_PRIMSWIM_LEDGE )
				actions = ["CUSTOM"];
			#endif
			
			if( !llGetListLength(actions) ){
				return 
				#ifdef InteractConf$soundOnFail
					llPlaySound(InteractConf$soundOnFail, .25)
				#endif
				;
			}
			
			integer successes;
			while( llGetListLength(actions) ){
				string val = llList2String(actions,0);
				actions = llDeleteSubList(actions,0,0);
				list split = llParseString2List(val, ["$"], []);
				string task = llList2String(split, 0); 
				integer success = TRUE;
				
				
				if(task == Interact$TASK_TELEPORT){
					vector to = (vector)llList2String(split,1); 
					to+=prPos(targ);
					RLV$cubeTask(SupportcubeBuildTeleport(to));
					raiseEvent(InteractEvt$TP, "");
				} 
				else if( task == Interact$TASK_PLAY_SOUND || task == Interact$TASK_TRIGGER_SOUND ){
					
					key sound = llList2String(split,1);
					float vol = llList2Float(split,2);
					if( vol <= 0 )vol = 1;
					if( task == Interact$TASK_TRIGGER_SOUND )
						llTriggerSound(sound, vol);
					else 
						llPlaySound(sound, vol);
						
				}
				else if(task == Interact$TASK_SITON){
					RLV$sitOn(targ, FALSE); 
				} 
				else if(task == Interact$TASK_CLIMB){ 
					Climb$start(targ, 
						(rotation)llList2String(split,1), // Rot offset 
						llList2String(split,2), // Anim passive
						llList2String(split,3), // Anim active
						llList2String(split,4), // anim_active_down, 
						llList2String(split,5), // anim_dismount_top, 
						llList2String(split,6), // anim_dismount_bottom, 
						llList2String(split,7), // nodes, 
						llList2String(split,8), // Climbspeed
						llList2String(split,9), // onStart
						llList2String(split,10) // onEnd
					);
				}		
				else
					success = onInteract(targ, task, llList2List(split,1,-1));
				
				
				// Custom should always be a success
				success += (task == "CUSTOM");
				successes+= (success>0);
				
			}

			// Raise interact event
			#ifdef InteractConf$raiseEvent
				raiseEvent(InteractEvt$onInteract, targ );
			#endif
			
			#ifdef InteractConf$soundOnFail
			if( !successes )
				llPlaySound(InteractConf$soundOnFail, .25);
			#endif
			#ifdef InteractConf$soundOnSuccess
			if( successes )
				llPlaySound(InteractConf$soundOnSuccess, .25);
			#endif
			
			
		}else if(evt == evt$BUTTON_HELD_SEC){
			integer btn = llList2Integer(data, 0);
			if(btn == CONTROL_UP)held = llList2Integer(data, 1);
		}else if(evt == evt$BUTTON_PRESS && llList2Integer(data,0)&CONTROL_UP)held = 0;
    }
	
	#ifdef InteractConf$usePrimSwim
	else if( script == "jas Primswim" && evt == PrimswimEvt$atLedge ){
	
		if( llList2Integer(data,0) )
			BFL = BFL|BFL_PRIMSWIM_LEDGE;
		else 
			BFL = BFL&~BFL_PRIMSWIM_LEDGE;
			
	}
	#endif
	
}

timerEvent(string id, string data){

    if(id == TIMER_RECENT_CLICK)
        BFL = BFL&~BFL_RECENT_CLICK;
    

}


// Loads targ and targDesc into the global
fetchFromCamera(){

	targ = "";
	targDesc = "";

	if( llGetPermissions() & PERMISSION_TRACK_CAMERA ){
	
		integer ainfo = llGetAgentInfo(llGetOwner());
		if(~ainfo&AGENT_SITTING || BFL&BFL_ALLOW_SITTING){

			vector start;
			vector fwd = llRot2Fwd(llGetCameraRot())*3;
			
			if( ainfo&AGENT_MOUSELOOK )
				start = llGetCameraPos();
				
			else{
			
				vector apos = prPos(llGetOwner());
				rotation arot = prRot(llGetOwner());
				vector cpos = llGetCameraPos();
				rotation crot = llGetCameraRot();
				vector cV = llRot2Euler(crot);
				vector aV = llRot2Euler(arot);
				
				// Prevents picking up items behind you
				if( llFabs(cV.z-aV.z) > PI_BY_TWO )
					return;
				
				// We can use cpos if camera is in front of avatar
				start = cpos;
				
				// If camera is behind the avatar. Then we must calculate where the avatar is and cast the ray from there
				vector temp = (cpos-apos)/arot; 
				if(llFabs(llAtan2(temp.y,temp.x))>PI_BY_TWO){
				
					// Owner Position
					vector C = apos;
					// Owner Fwd (Z rotation only) ( aV = llRot2Euler( arot ); )
					vector B = llRot2Fwd(llEuler2Rot(<0,0,aV.z>));
					// Camera position
					vector A = cpos;
					// Camera fwd
					vector av = llRot2Fwd(crot);
					
					// Prevent division by 0
					if(B == av)
						return;
						
					// Calculation
					float div = (av*B);
					if( div == 0 )
						return;
					start = (C-A)*B / div * av + A;
					
				}
				
				//start = llGetRootPosition()+<0,0,ascale.z*.25>;
			}
			
			list ray = llCastRay(start, start+fwd, []);

			if( llList2Integer(ray,-1) > 0 && llVecDist(llGetRootPosition(), l2v(ray, 1)) < 2.5 ){
				
				key k = llList2Key(ray,0);
				
				if( 
					~llListFindList(additionalAllow, [(string)k]) || 
					(llGetAgentSize(k) != ZERO_VECTOR && ALLOW_ALL_AGENTS) 
				){
				
					targ = llList2Key(ray,0);
					targDesc = "CUSTOM";
					return;
					
				}
					
				string td = prDesc(k);
				key real = k;
				#ifdef InteractConf$USE_ROOT
				k = prRoot(k);
				#else
				if(td == "ROOT"){
					k = prRoot(k);
					td = prDesc(k);
				}
				#endif

				if(prRoot(llGetOwner()) != prRoot(k)){

					list descparse = llParseString2List(td, ["$$"], []);
	
					list_shift_each(descparse, val, {
					
						list parse = llParseString2List(val, ["$"], []);
						if(llList2String(parse,0) == Interact$TASK_DESC){
							targDesc = td;
							targ = k;
							real_key = real;
							return;
						}
						
					})
					
				} 
				
			}

		}

	}
	
}

seek( list sensed ){
	
	

	// override is set, use the override text instead
	if( OVERRIDE ){
	
		if( ~BFL&BFL_OVERRIDE_DISPLAYED ){
			
			BFL = BFL|BFL_OVERRIDE_DISPLAYED;
			onDesc(llGetOwner(), llList2String(OVERRIDE, 0));
			
		}
		
		if( l2i(OVERRIDE, 4)&Interact$OF_AUTOREMOVE && llKey2Name(l2k(OVERRIDE, 1)) == "" )
			OVERRIDE = [];
			
		return;

	}
	
	sensed += additionalAllow;	// Add additionalAllow to sensed
	
	// Try raycast in camera direction first
	fetchFromCamera();
	
	

	// Fail
	if( !count(sensed) && targ == "" ){
		
		#ifdef PrimswimEvt$atLedge
		if( BFL&BFL_PRIMSWIM_LEDGE )
			targ = "_PRIMSWIM_CLIMB_";
		#endif
	
	}
	// No camera available but sensor picked up some
	else if( count(sensed) && targ == "" ){
	
		// ALGORITHMS!
		list scales;
		vector as = llGetAgentSize(llGetOwner());
		vector gp = llGetRootPosition();
		integer i;
		for( ; i<count(sensed); ++i ){
			
			vector pp = prPos(l2k(sensed, i));
			float dist = llVecDist(gp, pp);
			list ray = llCastRay(gp+<0,0,as.z*0.5>, pp, [RC_DATA_FLAGS, RC_GET_ROOT_KEY]);
			prAngX(l2k(sensed,i), ang)
			ang = llFabs(ang);
			if( (!l2i(ray, -1) || l2k(ray, 0) == l2k(sensed,i)) && (ang < PI/4 || dist < 1) && dist < 2 )
				scales += (list)(ang+dist) + l2k(sensed, i);
			
		}
		
		scales = llListSort(scales, 2, TRUE);
		targ = l2k(scales, 1);
		targDesc = prDesc(l2k(scales, 1));
		if( ~llListFindList(additionalAllow, (list)((string)targ)) )
			targDesc = "CUSTOM";
		
	}
	
	
		
	// Send description
	list d = explode("$$",targDesc);
	string dout = targDesc;
	list_shift_each(d, val, 
		list spl = explode("$",val);
		if( l2s(spl, 0) == "D" ){
			dout = l2s(spl, 1);
			d = [];
		}	
	)
	
	onDesc(targ, dout);
	
	

}



default{

    state_entry(){
		
		#ifdef InteractConf$allowWhenSitting
			BFL = BFL | BFL_ALLOW_SITTING;
		#endif
	
        onInit();
		llSetMemoryLimit(llGetUsedMemory()*2);
		if( llGetAttached() )
			llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
		llSensorRepeat("","",ACTIVE|PASSIVE,2.5,PI,0.25);
		//llSensor("","",ACTIVE|PASSIVE,3,PI);
		
    }
	
	sensor( integer total ){
		
		integer i;
		list near = [];
		for( ; i<total; ++i ){
			
			key id = llDetectedKey(i);
			if( startsWith(prDesc(id), "D$") && !l2i(llGetObjectDetails(id, (list)OBJECT_PHANTOM), 0) )
				near += id;				
		}
		
		seek(near);
		
	}
	
	no_sensor(){
		seek([]);
	}
    
    timer(){multiTimer([]);}
    
    #include "xobj_core/_LM.lsl" 
    /* 
        Included in all these calls:
        METHOD - (int)method
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task
        CB_DATA - Array of params to return in a callback
    */
    
    if(method$isCallback){
        return;
    }
        
	if(METHOD == InteractMethod$override){
	// Clear override displayed
		BFL = BFL&~BFL_OVERRIDE_DISPLAYED;
			
		if(method_arg(0) == "")
			OVERRIDE = [];
		else{
			OVERRIDE = [method_arg(0), id, SENDER_SCRIPT, CB, l2i(PARAMS, 1)];
		}
		
		return;
	}
	else if( METHOD == InteractMethod$allowWhenSitting ){
		if( l2i(PARAMS, 0) )
			BFL = BFL|BFL_ALLOW_SITTING;
		else
			BFL = BFL&~BFL_ALLOW_SITTING;
	}
	
	else if(METHOD == InteractMethod$onClick){
		string evt = method_arg(0);
		string data = method_arg(1);
		integer pos = llListFindList(llList2ListStrided(ON_INTERACT, 0, -1, 2), [evt]);
		if(~pos)ON_INTERACT = llDeleteSubList(ON_INTERACT, pos*2, pos*2);
		if(data){
			ON_INTERACT += [evt, data];
		}
	}
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
    
}


