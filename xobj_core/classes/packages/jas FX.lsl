#ifdef FXConf$useShared
	#define DB2$USE_SHARED [cls$name]
#endif
#define USE_EVENTS

#include "xobj_core/_ROOT.lsl"
#include "xobj_core/classes/jas FX.lsl"
//#include "situation/_lib_effects.lsl"


#define PSTRIDE 4
list PCS;
list NPCS;
list PACKAGES;     // (int)pid, (key)id, (arr)package, (int)stacks
list EVT_INDEX;     // [scriptname_evt, [pid, pid...]]
list TAG_CACHE;     // [(int)tag1...]
integer PID;

#define savePackages() db2$set([], llList2Json(JSON_ARRAY, PACKAGES))
#define runPackage(caster, package, stacks) string c = caster; if(c == "s"){c = llGetOwner();} raiseEvent(FXEvt$runEffect, llList2Json(JSON_ARRAY, [c, stacks, mkarr(package)]))
onEvt(string script, integer evt, string data){
    // Packages to work on
if(script != cls$name){
    list packages = [];
	
	// If internal event, run on a specific ID by data
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
				if(maxtargs == 0)maxtargs = -1;
				
                if(targ&TARG_VICTIM || (targ&TARG_CASTER && sender == "s")){FX$run(llGetOwner(), wrapper); maxtargs--;}
                if(targ&TARG_CASTER && maxtargs != 0){FX$send(sender, sender, wrapper); maxtargs--;}
                if(targ&TARG_PCS){
                    integer i;
                    for(i=0; i<llGetListLength(PCS) && maxtargs!=0; i++){FX$send(llList2String(PCS,i), llGetOwner(), wrapper); maxtargs--;}
                }
                if(targ&TARG_NPCS){
                    integer i;
                    for(i=0; i<llGetListLength(NPCS) && maxtargs != 0; i++){FX$send(llList2String(NPCS,i), llGetOwner(), wrapper); maxtargs--;}
                }
            }
        }
        
    }
}
    #ifdef FXConf$useEvtListener
    evtListener(script, evt, data);
    #endif
}


integer preCheck(key sender, string package){
    list conds = llJson2List(jVal(package, [FX_CONDS]));
    integer min = (integer)jVal(package, [FX_MIN_CONDITIONS]);
    integer all = llGetListLength(conds);
    if(min == 0)min = all;
    integer successes;
    integer add = TRUE;
    integer parsed;
	integer flags = (integer)jVal(package, [FX_FLAGS]);
	
	if(~flags&PF_ALLOW_WHEN_DEAD){
		if(isDead())return FALSE;
	}
    // loop through all conditions
    list_shift_each(conds, cond, {
        list condl = llJson2List(cond);

		integer c = llList2Integer(condl,0);
        list dta = llDeleteSubList(condl,0,0);
		
		
        integer inverse;
        if(c<0)inverse = TRUE;
        c = llAbs(c);
        
        // Built in things
        if(c == fx$COND_HAS_PACKAGE_NAME || c == fx$COND_HAS_PACKAGE_TAG){
            integer found;
            if(c == fx$COND_HAS_PACKAGE_NAME){
                integer i;
                for(i=0; i<llGetListLength(PACKAGES) && !found; i+=PSTRIDE){
                    string pdata = llList2String(PACKAGES, i+2);
                    if(~llListFindList(dta, [jVal(pdata, [FX_NAME])]))found = TRUE;
                }
            }else{
				
                list_shift_each(dta, t, {
                    if(~llListFindList(TAG_CACHE, [(integer)t])){
                        found = TRUE;
                        dta = [];
                    }
                })
            }
            // Not found and required
            if(!found){
				add = FALSE;
				if(!inverse)debugUncommon("Package failed cause required fx name/tag not found.");
			}            
            else if(inverse)// Found and required not to be
                debugUncommon("Package failed cause required NOT fx name/tag found.");
        }
        else add = checkCondition(sender, c, dta);
		
        if(inverse)add = !add;

        successes+=add;
        if(successes>=min)return TRUE;
        parsed++;
        if(successes+(min-parsed)<min)return FALSE;   // No way this can generate enough successes now
    })
    return successes>=min;
}
list find(list names, list senders, list tags, list pids){
    list out; integer i;
    for(i=0; i<llGetListLength(PACKAGES); i+=PSTRIDE){
        integer add = FALSE; string p = llList2String(PACKAGES,  i+2);
        string n = jVal(p, [4]);
        string u = llList2String(PACKAGES, i+1);
        if(~llListFindList(names, [n])){
			add = TRUE;
		}
        if(!add){
            if(~llListFindList(senders, [u])){
				add = TRUE;
				debugUncommon("Sender exists: "+u+" in "+mkarr(senders));
			}
        }
        if(!add){
            if(~llListFindList(pids, [llList2Integer(PACKAGES, i)])){
				add = TRUE;
				debugUncommon("PID exists: "+llList2String(PACKAGES, i));
			}
        }
		
		// Scan tags
        if(!add){
            integer x; list t = llJson2List(jVal(p, [10]));
            for(x = 0; x<llGetListLength(tags) && !add; x++){
                if(~llListFindList(tags, llList2List(t, x, x))){
					add = TRUE;
					debugUncommon("Tag exists "+llList2String(t, x));
				}
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
    
    
    // Remove if unique
    if(flags&PF_UNIQUE){
		list find = find([llList2String(package, 4)], [], [], []);
		
		integer i;
		for(i=0; i<llGetListLength(find); i++){
			FX$rem(flags&PF_EVENT_ON_OVERWRITE, "", 0, "", llList2Integer(PACKAGES, llList2Integer(find, i)));
		}
		//FX$rem(FALSE, llList2String(package, 4), 0, "!"+(string)sender, 0);
	}
    
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
    TAG_CACHE+= llJson2List(llList2String(package, FX_TAGS));
    
    
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




timerEvent(string id, string data){
    integer pid = (integer)llGetSubString(id, 2, -1);
    if(llGetSubString(id, 0, 1) == "F_"){
        FX$rem(TRUE, "", 0, "", pid);
    }
    else if(llGetSubString(id, 0, 1) == "T_"){
        integer i;
        for(i=0; i<llGetListLength(PACKAGES); i+=PSTRIDE){
            if(llList2Integer(PACKAGES, i) == pid){
                runPackage(llList2String(PACKAGES, i+1), llJson2List(llList2String(PACKAGES, i+2)), llList2Integer(PACKAGES, i+3));
                return;
            }
        }
    }
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

        if(METHOD == FXMethod$run){

            key sender = method_arg(0);
            string wrapper = method_arg(1);
            list packages = llJson2List(wrapper);
            integer min_objs = llList2Integer(packages,0);
            integer max_objs = llList2Integer(packages,1);
			packages = llDeleteSubList(packages, 0, 1);
			
            list successful;
            integer i;
            for(i=0; i<llGetListLength(packages); i+=2){
                string p = llList2String(packages, i+1);
                if(preCheck(sender, p))successful+=[llList2Integer(packages,i), p];
                if(llGetListLength(successful)>=max_objs && max_objs != 0)packages = [];
            }
            
            if(llGetListLength(successful)<min_objs){
                CB_DATA = [FALSE];
            }
            else{
				CB_DATA = [llGetListLength(successful)/2];
				for(i=0; i<llGetListLength(successful); i+=2){
					addPackage(sender, llJson2List(llList2String(successful,i+1)), llList2Integer(successful,i));
				}
			}
        }
        else if(METHOD == FXMethod$rem){
            integer raiseEvent = (integer)method_arg(0); 
            string name = method_arg(1);
            integer tag = (integer)method_arg(2);
            string sender = method_arg(3);
            integer pid = (integer)method_arg(4);

            
            if((string)sender == llGetOwner())sender = "s";
            
            #ifdef FXConf$useShared
            integer nrRemoved;
            #endif
            
            
            integer i; 
            for(i=0; i<llGetListLength(PACKAGES) && llGetListLength(PACKAGES); i+=PSTRIDE){
				//key caster = llList2String(PACKAGES, i+1);
                string p = llList2String(PACKAGES, i+2);
				string n = jVal(p, [4]);
				
                list tags = [];
                if(tag)tags = llJson2List(jVal(p, [10]));
                    
                if(
                    (name=="" || name == n) &&
                    (!tag || llListFindList(tags, [tag])) && 
                    (sender=="" || (sender == llList2String(PACKAGES, i+1) || (llGetSubString(sender,0,0) == "!" && llList2String(PACKAGES, i+1) != llGetSubString(sender,1,-1)))) &&
                    (!pid || llList2Integer(PACKAGES, i) == pid)
                ){
                    
                    string pid_rem = llList2String(PACKAGES, i);
                    if(raiseEvent)onEvt("", INTEVENT_ONREMOVE, (string)pid_rem);
		
					
                    raiseEvent(FXEvt$effectRemoved, mkarr(([llList2String(PACKAGES, i+1), llList2Integer(PACKAGES, i+3), p])));
                    
					// Remove from evt cache
                    list evts = llJson2List(jVal(p, [FX_EVTS]));
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
                    
                    // Remove from tag cache
                    list tags = llJson2List(jVal(p, [FX_TAGS]));
                    list_shift_each(tags, t, {
                        integer pos = llListFindList(TAG_CACHE, [(integer)t]);
                        if(~pos)TAG_CACHE=llDeleteSubList(TAG_CACHE, pos, pos);
                    })
                    /*
                    debug("EVT: "+llList2CSV(EVT_INDEX));
                    debug("TAGS: "+llList2CSV(TAG_CACHE));
                    */
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
        if(METHOD == FXMethod$setPCs)PCS = llJson2List(method_arg(0));
        if(METHOD == FXMethod$setNPCs)NPCS = llJson2List(method_arg(0));
        
        
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 

}
