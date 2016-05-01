#define USE_EVENTS
#include "../ton Footsteps.lsl"
#include "xobj_core/classes/jas Interact.lsl"
#include "xobj_core/classes/jas RLV.lsl"
#include "xobj_core/classes/jas Primswim.lsl"



  
string CURRENT_WALKABLE = ""; 
key CURRENT_PRIM = "";
float CURRENT_VOL = -1;
list SOUND_CACHE;
key previousSound;

integer BFL;
#define BFL_IN_AIR 1
#define BFL_SWIMMING 2

#define TIMER_STEP "a"
#define TIMER_RECHECK "b"

integer pInteract; 

string targDesc;
string WL;
key targ;



onEvt(string script, integer evt, string data){ 
    if(script == "jas Primswim"){
        
        if(evt == PrimswimEvt$onWaterEnter)BFL = BFL|BFL_SWIMMING;
        else if(evt == PrimswimEvt$onWaterExit)BFL = BFL&~BFL_SWIMMING;

    }
} 

timerEvent(string id, string data){
    if(id == TIMER_STEP){ 
        integer status = llGetAgentInfo(llGetOwner());
        if(status&AGENT_IN_AIR){BFL=BFL|BFL_IN_AIR; return;}
        BFL = BFL&~BFL_IN_AIR;
        if(~status&AGENT_WALKING)return;
        if(SOUND_CACHE == [])return;
        if(BFL&BFL_SWIMMING)return;
        float vol = CURRENT_VOL;
        if(vol == -1){ 
            vol = FootstepsCfg$WALK_VOL;
            if(status&AGENT_ALWAYS_RUN)vol = FootstepsCfg$RUN_VOL;
            if(status&AGENT_CROUCHING)vol = FootstepsCfg$CROUCH_VOL;
        }
        if(vol<=0)return;
        list snd = SOUND_CACHE;
        if(llGetListLength(snd) >1){
            remByVal(snd, previousSound);
        }
        llTriggerSound(randElem(snd), vol);
    }else if(id == TIMER_RECHECK){
        list ray = llCastRay(llGetPos(), llGetPos()-<0,0,4>, [RC_REJECT_TYPES, RC_REJECT_AGENTS]);
        if(llList2Integer(ray, -1) <=0)CURRENT_PRIM = "";
        else{ 
            if(CURRENT_PRIM == llList2Key(ray, 0))return;
            CURRENT_PRIM = llList2Key(ray, 0);
            list split = llParseString2List(prDesc(llList2Key(ray,0)), ["$$"], []);
            integer found = FALSE;
            integer i;
            list_shift_each(split, val, {
                list p = llParseString2List(val, ["$"], []);
                string task = llList2String(p,0);
                if(task == Interact$TASK_FOOTSTEPS){
                    setWalkable(llList2String(p,1));
                    if(llGetListLength(p)>=3){CURRENT_VOL = llList2Float(p,1);}
                    else{CURRENT_VOL = -1;}
                    found = TRUE;
                }  
                else if(task == Interact$TASK_WL_PRESET){
                    if(llList2String(p,1) != WL){
                        WL = llList2String(p,1);
                        RLV$windlightPreset(WL, FALSE);
                    }
                }
            })
            
            if(found)return;
            CURRENT_VOL = -1;
            setWalkable("DEFAULT");
        }
    }
}

// Use "" to just init
setWalkable(string walkable){
    if(walkable == CURRENT_WALKABLE || walkable == "")return;
    CURRENT_WALKABLE = walkable;
    
    SOUND_CACHE = [];
    integer i; integer pushing;
    for(i=0; i<llGetListLength(SOUNDS); i++){ 
        integer type = llGetListEntryType(SOUNDS, i);
        if(type != TYPE_KEY){ 
            if(llList2String(SOUNDS, i) == CURRENT_WALKABLE){
                pushing = TRUE;
            }
            else if(pushing)return;
        }
        else if(pushing){
            SOUND_CACHE += llList2Key(SOUNDS, i);
        }
    }
} 


default
{
    on_rez(integer mew){
        llResetScript();
    }
    
    state_entry()
    {
        init();
        setWalkable("DEFAULT");
        multiTimer([TIMER_STEP, "", FootstepsCfg$SPEED, TRUE]);
        multiTimer([TIMER_RECHECK, "", .25, TRUE]);
    }
    
    collision_start(integer total){
        if(~BFL&BFL_IN_AIR)return;
        BFL = BFL&~BFL_IN_AIR;
        vector vel = llGetVel();
        if(vel.z<-4){ 
            integer i;
            list available; integer parsing;
            for(i=0; i<llGetListLength(COLS); i++){
                integer type = llGetListEntryType(COLS, i);
                if(type != TYPE_KEY){ 
                    if(llList2String(COLS, i) == CURRENT_WALKABLE){
                        parsing = TRUE;
                    }
                    else if(parsing)i = llGetListLength(COLS);
                } 
                else if(parsing){
                    available += llList2Key(COLS, i);
                }
            }
            if(available != []){
                llTriggerSound(randElem(available), 1);
                float range = llFabs(vel.z);
				onThud(range);
            }
        }
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
        CB_DATA - Array of params to return in a callback
    */
    
    if(method$byOwner){ 
        if(method$isCallback){
                
            return;
        }
        
        
        
    }
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
    
}

