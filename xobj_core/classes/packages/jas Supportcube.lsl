#include "xobj_core/classes/jas RLV.lsl"


integer BFL;
#define BFL_ON_SIT 1
#define BFL_KFM_ACTIVE 2

#define TIMER_NEXT "a"
#define TIMER_DIE "b"
#define TIMER_CHECK "c"

// Cache of tasks [(obj)task, (obj)task...]
// Tasks consist of {t:(int)task, p:(arr)params}
list tasks = [];



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
		
        integer t = (integer)jVal(task, ["t"]);
        list params = llJson2List(jVal(task, ["p"]));
        
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
			endKFM();
		}
		
		else if(t == Supportcube$tKFM){
			
			list dta = llJson2List(l2s(params,0));
			list conf = llJson2List(l2s(params,1));
			KFM(dta, conf);
			
		}
    }
} 

rotation NormRot(rotation Q)
{
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

default
{ 
    #ifdef SupportcubeCfg$listenOverride
	#define LISTEN_LIMIT_FREETEXT \
		if(chan == SupportcubeCfg$listenOverride && llGetOwnerKey(id) == llGetOwner()){ \
			onListenOverride(chan, id, message); \
			return; \
		}
	#endif
	
    #include "xobj_core/_LISTEN.lsl" 
    
    on_rez(integer mew){
        if(mew)llSetAlpha(0, ALL_SIDES);
        llSetObjectDesc((string)mew);
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
        /*
            Included in all these calls:
            METHOD - (int)method
            PARAMS - (var)parameters
            SENDER_SCRIPT - (var)parameters
            CB - The callback you specified when you sent a task
        */
        if(nr == METHOD_CALLBACK)return;
        if(method$byOwner){
            if(METHOD == SupportcubeMethod$execute){
                tasks+=PARAMS;
                runTask();
            }
            else if(METHOD == SupportcubeMethod$killall)
				kill();
        }
        
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
}
