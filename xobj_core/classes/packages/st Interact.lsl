#include "xobj_core/_CLASS_STATIC.lsl"
#include "xobj_core/classes/st Interact.lsl"
#include "xobj_core/classes/st RLV.lsl"
#include "xobj_core/classes/st Climb.lsl"
  
integer BFL;
#define BFL_RECENT_CLICK 1      // Recently interacted

#define TIMER_SEEK "a"
#define TIMER_RECENT_CLICK "c"

integer pInteract;

string targDesc;
key targ;


onEvt(string script, integer evt, string data){ 
    if(script == "st RLV" && evt == evt$SCRIPT_INIT){
        init();
    }
    else if(script == "#ROOT" && evt == evt$BUTTON_RELEASE && (integer)data&CONTROL_UP){
        if(BFL&BFL_RECENT_CLICK)return;
        
		if(!preInteract(targ))return;
        
        
        integer ainfo = llGetAgentInfo(llGetOwner());
        if(ainfo&AGENT_SITTING){
            if(ainfo&AGENT_SITTING){
                RLV$unsit(FALSE);
            }
            return;
        }
        
        
        BFL = BFL|BFL_RECENT_CLICK;
        multiTimer([TIMER_RECENT_CLICK, "", 1, FALSE]);
        llPlaySound("ca561a13-c867-53f6-ee73-3e70fa37312e", .5);
        
        
        list actions = llParseString2List(targDesc, ["$$"], []);
        if(llGetListLength(actions)>1){
            multiTimer([TIMER_RECENT_CLICK, "", 2, FALSE]);
        }
        
        while(llGetListLength(actions)){
            string val = llList2String(actions,0);
            actions = llDeleteSubList(actions,0,0);
            list split = llParseString2List(val, ["$"], []);
            string task = llList2String(split, 0); 
            if(task == Interact$TASK_TELEPORT){
				vector to = (vector)llList2String(split,1); 
				to+=prPos(targ);
				RLV$cubeTask(SupportcubeBuildTeleport(to));
				raiseEvent(InteractEvt$TP, "");
			} 
			else if(task == Interact$TASK_PLAY_SOUND || task == Interact$TASK_TRIGGER_SOUND){
				key sound = llList2String(split,1);
				float vol = llList2Float(split,2);
				if(vol<=0)vol = 1;
				if(task == Interact$TASK_TRIGGER_SOUND)llTriggerSound(sound, vol);
				else llPlaySound(sound, vol);
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
					llList2String(split,8) // Climbspeed
				);
			}else onInteract(targ, task, llList2List(split,1,-1));
        }
    }
}

init(){
    multiTimer([TIMER_SEEK, "", 0.25, TRUE]);
    if(llGetAttached())llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
}

timerEvent(string id, string data){
    if(id == TIMER_SEEK){

        if( llGetPermissions()&PERMISSION_TRACK_CAMERA){
            integer ainfo = llGetAgentInfo(llGetOwner());
            if(~ainfo&AGENT_SITTING){
                vector start;
                vector fwd = llRot2Fwd(llGetCameraRot())*3;
                if(ainfo&AGENT_MOUSELOOK){
                    start = llGetCameraPos();
                }else{
                    vector ascale = llGetAgentSize(llGetOwner());
                    start = llGetPos()+<0,0,ascale.z*.25>;
                }
                list ray = llCastRay(start, start+fwd, [RC_REJECT_TYPES, RC_REJECT_AGENTS]);
    
                if(llList2Integer(ray,-1) > 0){
                    if(prRoot(llGetOwner()) != prRoot(llList2Key(ray,0))){
                        string td = prDesc(llList2Key(ray,0));
                        list descparse = llParseString2List(td, ["$$"], []);
        
                        list_shift_each(descparse, val, {
                            list parse = llParseString2List(val, ["$"], []);
                            if(llList2String(parse,0) == Interact$TASK_DESC){
                                targDesc = td;
                                targ = llList2Key(ray,0);
                                onDesc(targ, llList2String(parse, 1));
                                return;
                            }
                        })
                    } 
                }
            }
            targ = "";
            targDesc = "";
            onDesc(targ, "");
        }
    }

    else if(id == TIMER_RECENT_CLICK){
        BFL = BFL&~BFL_RECENT_CLICK;
    }
}



default
{
    on_rez(integer mew){
        llResetScript();
    }
    
    state_entry()
    {
        onInit();
		llSetMemoryLimit(llGetUsedMemory()*2);
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


