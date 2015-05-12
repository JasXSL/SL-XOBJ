#include "xobj_core/classes/st RLV.lsl"


integer BFL;
#define BFL_ON_SIT 1


#define TIMER_NEXT "a"
#define TIMER_DIE "b"
#define TIMER_CHECK "c"

list tasks = [];

runTask(){  
    while(llGetListLength(tasks)){
        string task = llList2String(tasks,0);
        tasks = llDeleteSubList(tasks,0,0); 
        integer t = (integer)jVal(task, ["t"]);
        list params = llJson2List(jVal(task, ["p"]));
        
        if(t == Supportcube$tSetPos)llSetRegionPos((vector)llList2String(params,0));
        else if(t == Supportcube$tSetRot)llSetRot((rotation)llList2String(params,0));
        else if(t == Supportcube$tForceSit){
            if(llAvatarOnSitTarget() != llGetOwner()){
                string add = ",unsit=y";
                if(llList2Integer(params,0))add = ",unsit=n";
                llOwnerSay("@sit:"+(string)llGetKey()+"=force"+add);
                if(llList2Integer(params,1)){
                    BFL = BFL|BFL_ON_SIT;
                    return;
                }
                
            }
        }else if(t == Supportcube$tForceUnsit){
            llOwnerSay("@unsit=y");
            if(llAvatarOnSitTarget() == llGetOwner())llUnSit(llGetOwner());
        }else if(t == Supportcube$tDelay){
            multiTimer([TIMER_NEXT, "", llList2Float(params,0), FALSE]);
            return;
        }else if(t == Supportcube$tRunMethod){
            runMethod((key)llList2String(params,0), llList2String(params,1), llList2Integer(params,2), llJson2List(llList2String(params,3)), TNN);
        }
		else if(t == Supportcube$tTranslateTo){
			translateTo((vector)llList2String(params,0), (rotation)llList2String(params,1), llList2Float(params,2), llList2Integer(params,3));
		}else if(t == Supportcube$tTranslateStop)translateStop();
    }
} 

timerEvent(string id, string data){
    if(id == TIMER_NEXT){
        runTask();
    }else if(id == TIMER_DIE && llAvatarOnSitTarget() == "")llDie();
	else if(id == TIMER_CHECK && llKey2Name(llGetOwner()) == "")llDie();
}

onListenOverride(integer chan, key id, string message){
    list split = llCSV2List(message);
    integer task = llList2Integer(split,0);
    if(task == SupportcubeOverride$tSetPosAndRot){
        llSetRegionPos((vector)llList2String(split,1));
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_ROTATION, (rotation)llList2String(split,2)]);
    }
}

default
{ 
    
    #include "xobj_core/_LISTEN.lsl" 
    
    on_rez(integer mew){
        if(mew)llSetAlpha(0, ALL_SIDES);
        llSetObjectDesc((string)mew);
        llResetScript(); 
    }
    
    state_entry(){
        llSitTarget(<0,0,.01>,ZERO_ROTATION);
		debugCommon("Running killall");
        runOmniMethod(llGetScriptName(), SupportcubeMethod$killall, [], TNN);
        if((float)llGetObjectDesc()){
			debug("Setting death timer");
            runMethod(llGetOwner(), "st RLV", RLVMethod$cubeFlush, [], TNN);
            multiTimer([TIMER_DIE, "", (float)llGetObjectDesc(), TRUE]);
        }
		multiTimer([TIMER_CHECK, "", 10, TRUE]);
        initiateListen();
    }
    
    timer(){multiTimer([]);}
    
    changed(integer change){
        if(change&CHANGED_LINK){
            if(llAvatarOnSitTarget() == llGetOwner()){
                llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
                if(BFL&BFL_ON_SIT){
                    BFL = BFL&~BFL_ON_SIT;
                    runTask();
                }
            }
        }
    }
    
    run_time_permissions(integer perm){
        if(perm&PERMISSION_TRIGGER_ANIMATION){
            llStopAnimation("sit");
            llSleep(.2);
            llStopAnimation("sit"); 
        }
    } 
      
    
    
    #include "xobj_core/_LM.lsl" 
        /*
            Included in all these calls:
            METHOD - (int)method
            INDEX - (int)obj_index
            PARAMS - (var)parameters
            SENDER_SCRIPT - (var)parameters
            CB - The callback you specified when you sent a task
        */
        if(nr == METHOD_CALLBACK)return;
        if(method$byOwner){
            if(METHOD == SupportcubeMethod$execute){
                tasks+=llJson2List(PARAMS);
                runTask();
            }
            else if(METHOD == SupportcubeMethod$killall)llDie();
        }
        
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
}
