#include "xobj_core/classes/jas RLV.lsl"


integer BFL;
#define BFL_ON_SIT 1
#define BFL_KFM_ACTIVE 2

#define TIMER_NEXT "a"
#define TIMER_DIE "b"
#define TIMER_CHECK "c"
#define TIMER_PATH "d"

// Cache of tasks [(obj)task, (obj)task...]
// Tasks consist of {t:(int)task, p:(arr)params, s:(key)sender, ss:(str)sender_script}
list tasks = [];

vector PATHING_TARG;
str PATHING_ANIM;
str PATHING_CALLBACK;
key PATHING_SENDER;
float PATHING_SPEED;
int PATHING_FLAGS;
string PATHING_SENDER_SCRIPT;

endKFM(){
	if(~BFL&BFL_KFM_ACTIVE)
		return;
	
	BFL = BFL&~BFL_KFM_ACTIVE;
	llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
	llSleep(.1);
}


// This function cycles all received commands
runTask(){  

    while(llGetListLength(tasks)){
        string task = llList2String(tasks,0);
        tasks = llDeleteSubList(tasks,0,0); 
		
        integer t = (integer)j(task, "t");
        list params = llJson2List(j(task, "p"));
        key sender = j(task, "s");
		str sender_script = j(task, "ss");
		// Change region position of supportcube. This will end any active KFMs
        if(t == Supportcube$tSetPos){
			endKFM();
			llSetRegionPos((vector)l2s(params,0));
        }
		
		// Change global rotation
		else if(t == Supportcube$tSetRot){
			endKFM();
			llSetRot((rotation)l2s(params,0));
		}
		
		// Force sit owner
        else if(t == Supportcube$tForceSit && llAvatarOnSitTarget() != llGetOwner()){
			
			integer preventUnsit = l2i(params, 0);
			integer waitUntilSeated = l2i(params, 1);
		
			// Make larger when requesting a seat, to make sure the owner can see it
			llSetLinkPrimitiveParams(LINK_THIS, [PRIM_SIZE, <2,2,2>]);
            
			// Check if we can unsit
			string add = ",unsit=y";
            if(preventUnsit)
				add = ",unsit=n";
            
			// Seat the agent
			llOwnerSay("@sit:"+(string)llGetKey()+"=force"+add);
            
			// Wait until seated before executing more commands
			if(waitUntilSeated){
				
				// Give a HOLD 5 sec
				multiTimer(["ST", 0, 5, FALSE]);
                BFL = BFL|BFL_ON_SIT;
                return;
				
            }
			
        }
		
		// Unsit the owner if seated, and clear sit lock
		else if(t == Supportcube$tForceUnsit){
            llOwnerSay("@unsit=y");
            if(llAvatarOnSitTarget() == llGetOwner())
				llUnSit(llGetOwner());
        }
		
		// Wait until taking more actions
		else if(t == Supportcube$tDelay){
            multiTimer([TIMER_NEXT, "", llList2Float(params,0), FALSE]);
            return;
        }
		
		// Make the supportcube run a custom method
		else if(t == Supportcube$tRunMethod){
            runMethod((key)llList2String(params,0), llList2String(params,1), llList2Integer(params,2), llJson2List(llList2String(params,3)), TNN);
        }
		
		else if(t == Supportcube$tKFMEnd){
			stopPathing(FALSE);
			endKFM();
		}
		
		else if(t == Supportcube$tKFM){
			stopPathing(FALSE);
			list dta = llJson2List(l2s(params,0));
			list conf = llJson2List(l2s(params,1));
			KFM(dta, conf);
			
		}
		
		else if( t == Supportcube$tPathToCoordinates ){
			
			stopPathing(false);
			vector startPos = (vector)l2s(params, 0);
			rotation startRot= (rotation)l2s(params, 1);
			PATHING_TARG = (vector)l2s(params, 2);
			if( startPos != ZERO_VECTOR ){
				PATHING_ANIM = l2s(params, 3);
				if( PATHING_ANIM )
					AnimHandler$targAnim(llGetOwner(), PATHING_ANIM, TRUE);
				PATHING_SENDER = sender;
				PATHING_SENDER_SCRIPT = sender_script;
				
				if( l2k(params, 7) )
					PATHING_SENDER = l2k(params, 7);
				if( l2s(params, 8) )
					PATHING_SENDER_SCRIPT = l2s(params, 8);
				
				qd("SENDER = "+llKey2Name(PATHING_SENDER));
				qd("SCRIPT = "+PATHING_SENDER_SCRIPT);
				
				PATHING_CALLBACK = l2s(params, 4);
				PATHING_SPEED = l2f(params, 5);
				if( PATHING_SPEED <= 0 )
					PATHING_SPEED = 1.0;
				PATHING_FLAGS = l2i(params, 6);
				multiTimer([TIMER_PATH, 0, 0.25, TRUE]);
				llSetRegionPos(startPos);
				llSetRot(startRot);
			}
		}
    }
}

stopPathing( int success ){
	if( PATHING_SENDER == "" )
		return;
		
	if( Supportcube$PTCFlag$WARP_ON_FAIL && !success && llAvatarOnSitTarget() == llGetOwner() ){
		// Warp 
		llSetKeyframedMotion([], (list)KFM_COMMAND+(list)KFM_CMD_STOP);
		llSleep(.1);
		vector pos = PATHING_TARG;
		list ray = llCastRay(pos, pos-<0,0,5>, (list)RC_REJECT_TYPES + (RC_REJECT_AGENTS|RC_REJECT_PHYSICAL));
		if( l2i(ray, -1) == 1 ){
			vector as = llGetAgentSize(llGetOwner());
			pos = l2v(ray, 1)+<0,0,as.z/2>;
			llSetRegionPos(pos);
			llSleep(.1);
		}
		success = TRUE;
	}
	sendCallback(PATHING_SENDER, PATHING_SENDER_SCRIPT, SupportcubeMethod$execute, mkarr((list)
		Supportcube$tPathToCoordinates +
		success
	), PATHING_CALLBACK);
	PATHING_SENDER = "";
	if( PATHING_FLAGS & Supportcube$PTCFlag$UNSIT_AT_END ){
		llOwnerSay("@unsit=y");
        if(llAvatarOnSitTarget() == llGetOwner())
			llUnSit(llGetOwner());
	}
	if( PATHING_ANIM )
		AnimHandler$targAnim(llGetOwner(), PATHING_ANIM, FALSE);
	PATHING_FLAGS = 0;
	multiTimer([TIMER_PATH]);
	llSetKeyframedMotion([], (list)KFM_COMMAND+(list)KFM_CMD_STOP);
	llSleep(.1);
	
}

rotation NormRot(rotation Q){
    float MagQ = llSqrt(Q.x*Q.x + Q.y*Q.y +Q.z*Q.z + Q.s*Q.s);
    return
        <Q.x/MagQ, Q.y/MagQ, Q.z/MagQ, Q.s/MagQ>;
}


KFM(list dta, list conf){


	integer i;
			
	// Contains rewritten dta if dta is set
	list out;
	
	if(dta){
		
		// Check if KFM_DATA is set and in that case cache it
		integer kfm_data = KFM_TRANSLATION|KFM_ROTATION;
		for(i=0; i<count(conf); i+=2){
			if(l2i(conf, i) == KFM_DATA)
				kfm_data = l2i(conf, i+1);
		}
				
		integer stride = 3;
		if(~kfm_data & (KFM_TRANSLATION|KFM_ROTATION))
			stride = 2;

		// Rewrite to vector/rotation
		while(dta){
		
			if(kfm_data & KFM_TRANSLATION){
				out+= (vector)l2s(dta, 0);
				dta = llDeleteSubList(dta, 0, 0);
			}
			if(kfm_data & KFM_ROTATION){
				out+= NormRot((rotation)l2s(dta, 0));
				dta = llDeleteSubList(dta, 0,0);
			}
			// Delta
			out += l2f(dta, 0);
			dta = llDeleteSubList(dta, 0, 0);
					
		}
				
		BFL = BFL|BFL_KFM_ACTIVE;
	}

	llSetKeyframedMotion(out, conf);
	
}

timerEvent(string id, string data){
    if(id == TIMER_NEXT){
        runTask();
    }
	
	else if(id == TIMER_DIE && llAvatarOnSitTarget() == "")
		kill();
		
	else if(id == TIMER_CHECK && llKey2Name(llGetOwner()) == "")
		kill();
		
	else if( id == "ST" ){
	
		BFL = BFL&~BFL_ON_SIT;
		runTask();
		
	}
	
	else if( id == TIMER_PATH ){
	
		list raySettings = (list)RC_REJECT_TYPES+(RC_REJECT_AGENTS|RC_REJECT_PHYSICAL);
		vector mPos = llGetPos();
		vector ascale = llGetAgentSize(llGetOwner());
		ascale = <0,0,ascale.z/2>;
		vector drop = <0,0,-2>-ascale;	// We can drop 2m beneath our feet
		list ray = llCastRay(mPos, mPos+drop, raySettings);
		if( l2i(ray, -1) != 1 ){
			return stopPathing(false);
		}		
		float moveDist = 0.5*PATHING_SPEED;
		
		
		// This is our technical current position now
		mPos = l2v(ray, 1)+ascale;
		float dist = llVecDist(<mPos.x, mPos.y, 0>, <PATHING_TARG.x, PATHING_TARG.y, 0>);
		
		// X/Y coordinates only here
		vector move = llVecNorm(<PATHING_TARG.x, PATHING_TARG.y, 0>-<mPos.x, mPos.y, 0>);
		if( dist < moveDist ){
			return stopPathing(true);	// At target
		}
		else
			move *= moveDist;
		// Move is now an offset in X Y coordinates of where we need to go this step
		
		// See if there's an obstacle
		ray = llCastRay(mPos, mPos+move, raySettings);
		if( l2i(ray, -1) != 0 ){
			return stopPathing(false);
		}
		// See if there's ground
		ray = llCastRay(mPos+move, mPos+move+drop, raySettings);
		if( l2i(ray, -1) != 1 ){
			return stopPathing(false);
		}
		// Got the ground, set an offset
		mPos = mPos+move;
		vector v = l2v(ray, 1);
		mPos.z = v.z+ascale.z;
		vector rotLookAt = mPos-llGetPos();
		rotation r = llRotBetween(<1,0,0>, llVecNorm(<rotLookAt.x, rotLookAt.y, 0>));

		// mPos is now where we need to path to
		llSetKeyframedMotion((list)
			(mPos-llGetPos())+
			NormRot(r/llGetRot())+
			0.3,
			[]
		);
		
	}
		
}

onListenOverride(integer chan, key id, string message){

    list split = llCSV2List(message);
    integer task = llList2Integer(split,0);
	
	
    if(task == SupportcubeOverride$tSetPosAndRot){
		endKFM();
        llSetRegionPos((vector)llList2String(split,1));
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_ROTATION, (rotation)llList2String(split,2)]);
    }
	
	else if(task == SupportcubeOverride$tKFM){
		BFL = BFL|BFL_KFM_ACTIVE;
		KFM(llDeleteSubList(split, 0,0), []);
	}
	
	else if(task == SupportcubeOverride$tKFMEnd){
		endKFM();
	}
	
	
	
}

kill(){
	
	if(llGetNumberOfPrims()>2){
		return;
	}

	llDie();
	
}

default{
 
    #ifdef SupportcubeCfg$listenOverride
	#define LISTEN_LIMIT_FREETEXT \
		if(chan == SupportcubeCfg$listenOverride && llGetOwnerKey(id) == llGetOwner()){ \
			onListenOverride(chan, id, message); \
			return; \
		}
	#endif
	
    #include "xobj_core/_LISTEN.lsl" 
    
    on_rez(integer mew){
	
        if( mew )
			llSetAlpha(0, ALL_SIDES);
        llSetObjectDesc((string)mew);
		llRegionSayTo(mySpawner(), SUPPORTCUBE_INIT_CHAN, "INIT");
        llResetScript(); 
		
    }
    
    state_entry(){
	
		llSetStatus(STATUS_PHANTOM, TRUE);
        llSitTarget(<0,0,.01>,ZERO_ROTATION);
		debugCommon("Running killall");
        runOmniMethod(llGetScriptName(), SupportcubeMethod$killall, [], TNN);
        if((float)llGetObjectDesc()){
			debugUncommon("Setting death timer");
            runMethod(llGetOwner(), "jas RLV", RLVMethod$cubeFlush, [], TNN);
            multiTimer([TIMER_DIE, "", (float)llGetObjectDesc(), TRUE]);
        }
		multiTimer([TIMER_CHECK, "", 10, TRUE]);
        initiateListen();
		#ifdef SupportcubeCfg$listenOverride
		llListen(SupportcubeCfg$listenOverride, "", "", "");
		#endif
		
    }
    
    timer(){multiTimer([]);}
    
    changed(integer change){
	
        if(change&CHANGED_LINK){
            
			key ast = llAvatarOnSitTarget();
			
			// Owner seated
			if( ast == llGetOwner() ){
			
                llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
				if(BFL&BFL_ON_SIT){
				
                    BFL = BFL&~BFL_ON_SIT;
                    runTask();
					
                }
				
            }
			
			// Unsits or other person seated
			else{
				
				if( llAvatarOnSitTarget() == NULL_KEY && PATHING_FLAGS & Supportcube$PTCFlag$STOP_ON_UNSIT )
					stopPathing(FALSE);
				
				// Make smaller
				llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_SIZE, <.5,.5,.5>]);
				
				if(ast != llGetOwner() && ast != NULL_KEY)
					llUnSit(ast);
				
				else if(llGetNumberOfPrims() > 1){
					qd("WARNING! You have linked the supportcube! This is probably unintentional, so I'm going to grow to 10x10x10 so you can remove me.");
					llSetLinkPrimitiveParamsFast(LINK_THIS, [
						PRIM_SIZE, <10,10,10>,
						PRIM_COLOR, ALL_SIDES, <1,.5,0>, 1,
						PRIM_FULLBRIGHT, ALL_SIDES, TRUE,
						PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_NONE
					]);
				}
			}
			
			
        }
		
    }
    
    run_time_permissions(integer perm){
        if(perm&PERMISSION_TRIGGER_ANIMATION){
            llStopAnimation("sit");
            llSleep(.2);
            llStopAnimation("sit"); 
			llStartAnimation("stand");
        }
    } 
      
    
    
    #include "xobj_core/_LM.lsl" 
        if(nr == METHOD_CALLBACK)return;
        if(method$byOwner){
            if(METHOD == SupportcubeMethod$execute){
				integer i;
				for(; i<count(PARAMS); ++i ){
					str json = llJsonSetValue(l2s(PARAMS, i), (list)"s", id);
					json = llJsonSetValue(json, (list)"ss", SENDER_SCRIPT);
					PARAMS = llListReplaceList(PARAMS, (list)json, i, i);
				}
                tasks+=PARAMS;
                runTask();
            }
            else if(METHOD == SupportcubeMethod$killall)
				kill();
        }
        
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
}
