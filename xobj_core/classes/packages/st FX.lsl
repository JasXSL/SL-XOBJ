#include "xobj_core/_ROOT.lsl"
#include "xobj_core/classes/st FX.lsl"

#define PSTRIDE 4
list PCS;
list NPCS;
list PACKAGES;     // (int)pid, (key)id, (arr)packages, (int)stacks
list EVT_INDEX;     // [scriptname_evt, [pid, pid...]]
integer PID;

#define savePackages() _save([], llList2Json(JSON_ARRAY, PACKAGES))

onEvt(string script, integer evt, string data){
    // Packages to work on
if(script != cls$name){
    list packages = [];
    if(script == "")packages = find([], [], [], [(integer)data]);
    else{
        integer pos = llListFindList(EVT_INDEX, [script+"_"+(string)evt]);
        if(~pos){
            packages = find([],[],[],llJson2List(llList2String(EVT_INDEX, pos)));
        }
    }
    
    while(llGetListLength(packages)){
        string id = llList2String(packages, 0);
        packages = llDeleteSubList(packages, 0, 0);
        string sender = llList2String(PACKAGES, (integer)id+1);
        if(sender == "s")sender = llGetOwner();
        
        list evts = llJson2List(jVal(llList2String(PACKAGES, (integer)id+2), [9]));

        while(llGetListLength(evts)){
            string evdata = llList2String(evts, 0);
            evts = llDeleteSubList(evts, 0, 0);
            
            if(script+"_"+(string)evt == jVal(evdata, [1])+"_"+jVal(evdata,[0])){
                string wrapper = jVal(evdata, [4]);
                integer targ = (integer)jVal(evdata, [2]);
                integer maxtargs = (integer)jVal(evdata, [3]);
                    
                if(targ&TARG_VICTIM || (targ&TARG_CASTER && sender == "s")){FX$run(llGetOwner(), wrapper);}
                if(targ&TARG_CASTER){FX$send(sender, sender, wrapper);}
                if(targ&TARG_PCS){
                    integer i;
                    for(i=0; i<llGetListLength(PCS); i++){FX$send(llList2String(PCS,i), llGetOwner(), wrapper);}
                }
                if(targ&TARG_NPCS){
                    integer i;
                    for(i=0; i<llGetListLength(NPCS); i++){FX$send(llList2String(NPCS,i), llGetOwner(), wrapper);}
                }
            }
        }
        
    }
}
    #ifdef FXConf$useEvtListener
    evtListener(script, evt, data);
    #endif
}

unwrap(key sender, string wrapper){
    list packages = llJson2List(wrapper);
    integer min_objs = llList2Integer(packages,1);
    integer max_objs = llList2Integer(packages,2);
    packages = llDeleteSubList(packages, 0, 2);
    
    
    list successful;
    integer i;
    for(i=0; i<llGetListLength(packages); i+=2){
        string p = llList2String(packages, i+1);
        list conds = llJson2List(jVal(p, [4]));
        integer add = TRUE;
        list_shift_each(conds, c, {
            integer t = llList2Integer(conds,1);
            key targ = llGetOwner();
            if(t == TARG_CASTER){targ = sender;}
            else if(t == TARG_PCS){targ = "PC";}
            else if(t == TARG_NPCS){targ = "NPC";}
            if(!checkCondition(sender, targ, llList2Integer(conds,0), llDeleteSubList(conds,0,1))){
                conds = [];
                add = FALSE;
            }
        })
        if(add)successful+=[llList2Integer(packages,i), p];
        if(llGetListLength(successful)>=max_objs)packages = [];
    }
    
    if(llGetListLength(successful)<min_objs){
        #ifdef DEBUG
        llOwnerSay("Debug: No objs passed fx filter"); 
        #endif
        return;
    }
    
    
    for(i=0; i<llGetListLength(successful); i+=2){
        addPackage(sender, llJson2List(llList2String(successful,i+1)), llList2Integer(successful,i));
    }
    
}

list find(list names, list senders, list tags, list pids){
    list out; integer i;
    for(i=0; i<llGetListLength(PACKAGES); i+=PSTRIDE){
        integer add = FALSE; string p = llList2String(PACKAGES,  i+2);
        string n = jVal(p, [4]);
        string u = llList2String(PACKAGES, i+1);
        if(~llListFindList(names, [n]))add = TRUE;
        if(!add){
            if(llListFindList(senders, [u]))add = TRUE;
        }
        if(!add){
            if(llListFindList(pids, [llList2Integer(PACKAGES, i)]))add = TRUE;
        }
        if(!add){
            integer x; list t = llJson2List(jVal(p, [10]));
            for(x = 0; x<llGetListLength(tags) && !add; x++){
                if(~llListFindList(tags, llList2List(t, x, x)))add = TRUE;
            }
        }
        if(add)out+=i;
    }
    return out;
}

addPackage(string sender, list package, integer stacks){
    if(sender == llGetOwner() || sender == "")sender = "s";
    float dur = llList2Float(package, 0);
    
    if(stacks==0)stacks = 1;
    if(dur == 0){
        runPackage(sender, package, stacks);
        return;
    }
    
    
    integer flags = llList2Integer(package, 2);
    float tick = llList2Float(package, 1);
    integer mstacks = llList2Integer(package, 3); 
    integer CS = 1;
    
    // Remove if unique flag is set
    if(mstacks){
        list exists = find([llList2String(package,4)], [sender], [], []);
        if(exists){
            integer idx = llList2Integer(exists,0);
            CS = llList2Integer(PACKAGES, idx+3)+stacks;
            if(CS>mstacks)CS = mstacks;
            PACKAGES = llListReplaceList(PACKAGES, [CS], idx+3, idx+3);
            multiTimer(["F_"+(string)PID, "", dur, FALSE]);
            raiseEvent(FXEvt$effectStacksChanged, 
                mkarr(([
                    sender, 
                    stacks, 
                    mkarr(package)
                ]))
            );
            
            #ifdef FXConf$useShared
            savePackages();
            #endif
            return;
        }
    }
    
    PID++;
    
    
    // Create indexing function here for events
    if(flags&PF_UNIQUE)remove(FALSE, llList2String(package, 4), 0, "!"+(string)sender, 0);
    
    list evts = llJson2List(llList2String(package, 9));
    while(llGetListLength(evts)){
        string val = llList2String(evts,0);
        evts = llDeleteSubList(evts, 0, 0);
        
        string find = jVal(val, [1])+"_"+jVal(val,[0]);
        integer pos = llListFindList(EVT_INDEX, [find]);
        list pids = llJson2List(llList2String(EVT_INDEX, pos+1));
        integer exists = llListFindList(pids, [PID]);
        if(exists==-1){
            if(~pos){
                EVT_INDEX = llListReplaceList(EVT_INDEX, [mkarr(pids)], pos+1, pos+1);
            }else{
                EVT_INDEX+=[find, mkarr(pids)];
            }
        }
    } 
    // Remove conditions
    package = llListReplaceList(package, [""], 8,8);
    PACKAGES += [PID, sender, mkarr(package), 1];
    
    
    // Set timers
    multiTimer(["F_"+(string)PID, "", dur, FALSE]);
    if(tick>0)
        multiTimer(["T_"+(string)PID, "", tick, TRUE]);
    raiseEvent(FXEvt$effectAdded, mkarr(([sender, stacks, mkarr(package)])));
    //runPackage(sender, package, CS);
    onEvt("", INTEVENT_ONADD, (string)PID);
    
    #ifdef FXConf$useShared
    savePackages();
    #endif
}

runPackage(key caster, list package, integer stacks){
    if(caster == "s")caster = llGetOwner();
    raiseEvent(FXEvt$runEffect, llList2Json(JSON_ARRAY, [caster, stacks, mkarr(package)]));
}

timerEvent(string id, string data){
    integer pid = (integer)llGetSubString(id, 2, -1);
    if(llGetSubString(id, 0, 1) == "F_"){
        remove(TRUE, "", 0, "", pid);
    }
    else if(llGetSubString(id, 0, 1) == "T_"){
        integer i;
        for(i=0; i<llGetListLength(PACKAGES); i+=PSTRIDE){
            if(llList2Integer(PACKAGES, i) == pid)return runPackage(llList2String(PACKAGES, i+1), llJson2List(llList2String(PACKAGES, i+2)), llList2Integer(PACKAGES, i+3));
        }
    }
} 

remove(integer raiseEvent, string name, integer tag, string sender, integer pid){
    if((string)sender == llGetOwner())sender = "s";
    
    #ifdef FXConf$useShared
    integer nrRemoved;
    #endif
    
    
    integer i; 
    for(i=0; i<llGetListLength(PACKAGES) && llGetListLength(PACKAGES); i+=PSTRIDE){
        string p = llList2String(PACKAGES, i+2);
        list tags = [];
        if(tag)tags = llJson2List(jVal(p, [10]));
            
        if(
            (name=="" || name == jVal(p, [4])) &&
            (!tag || llListFindList(tags, [tag])) && 
            (sender=="" || (sender == llList2String(PACKAGES, i+1) || (llGetSubString(sender,0,0) == "!" && llList2String(PACKAGES, i+1) != llGetSubString(sender,1,-1)))) &&
            (!pid || llList2Integer(PACKAGES, i) == pid)
        ){
            
            string pid_rem = llList2String(PACKAGES, i);
            if(raiseEvent)onEvt("", INTEVENT_ONREMOVE, (string)i);
            raiseEvent(FXEvt$effectRemoved, mkarr(([llList2String(PACKAGES, i+1), llList2Integer(PACKAGES, i+3), p])));
            
            list evts = llJson2List(jVal(p, [9]));
            list_shift_each(evts, val, {
                string find = jVal(val, [1])+"_"+jVal(val, [0]);
                integer pos = llListFindList(EVT_INDEX, [find]);
                if(~pos){
                    list dta = llJson2List(llList2String(EVT_INDEX, pos+1));
                    integer ppos = llListFindList(dta, [(integer)pid_rem]);
                    if(~ppos){
                        dta = llDeleteSubList(dta, ppos, ppos);
                        if(dta == []){
                            EVT_INDEX = llDeleteSubList(EVT_INDEX, pos, pos+1);
                        }else{
                            EVT_INDEX = llListReplaceList(EVT_INDEX, [mkarr(dta)], pos+1, pos+1);
                        }
                    }
                }
            })
            
            
            multiTimer(["F_"+pid_rem]);
            multiTimer(["T_"+pid_rem]);
            PACKAGES = llDeleteSubList(PACKAGES, i, i+PSTRIDE-1);
            
            
            // REMOVE FROM INDEX HERE
                    
            i-=PSTRIDE;
            #ifdef FXConf$useShared
            nrRemoved++;
            #endif
        }
                
    }
    #ifdef FXConf$useShared
    savePackages();
    #endif
}

default
{
    on_rez(integer start){
        llResetScript();
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

        if(METHOD == FXMethod$run)unwrap(method_arg(0), method_arg(1));
        if(METHOD == FXMethod$rem){
            remove(
                (integer)method_arg(0), // raiseEvent
                method_arg(1),          // Name
                (integer)method_arg(2), // Tag
                method_arg(3),          // Sender
                (integer)method_arg(4)  // PID
            );
        }
        if(METHOD == FXMethod$setPCs)PCS = llJson2List(method_arg(0));
        if(METHOD == FXMethod$setNPCs)NPCS = llJson2List(method_arg(0));
        
        
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 

}
