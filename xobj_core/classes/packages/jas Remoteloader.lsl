// Conf
#include "xobj_core/classes/jas Remoteloader.lsl" 
#include "xobj_core/classes/jas Attached.lsl" 

#include "xobj_core/_CLASS_STATIC.lsl"

integer slave = 0;
 
list delayed_callbacks; // [name, script, callback, method]
integer dcs = 4;

default
{
    on_rez(integer start){
        llResetScript();
    }
    state_entry() 
    {
        memLim(1.5);
    } 
    
    object_rez(key id){
        list str = llList2ListStrided(delayed_callbacks, 0,-1, 3);
        integer pos = llListFindList(str, [llKey2Name(id)]);
        if(~pos){
             
            string script = llList2String(delayed_callbacks,pos*dcs+1);
            integer method = llList2Integer(delayed_callbacks,pos*dcs+3);
            string callback = llList2String(delayed_callbacks, pos*dcs+2);
            sendCallback((string)LINK_SET, script, method, id, callback);
            delayed_callbacks = llDeleteSubList(delayed_callbacks, pos*dcs, pos*dcs+dcs-1);
        }
    } 

    //timer(){multiTimer([]);}

    #include "xobj_core/_LM.lsl"
        /*
            Included in all these calls:
            METHOD - (int)method
            INDEX - (int)obj_index
            PARAMS - (var)parameters
            SENDER_SCRIPT - (var)parameters
            CB - The callback you specified when you sent a task
        */

        if(nr == METHOD_CALLBACK){ 
            return;
        }
            
        if(METHOD == RemoteloaderMethod$load){
            //llSay(0, "Script remoteloaded: "+(string)method_arg(0));
            slave++;

			list dta = llJson2List(PARAMS);
			if(id == "")id = llList2String(dta, -1);
			
			
			llMessageLinked(LINK_THIS, slave, llList2Json(JSON_ARRAY, [id, llList2String(dta, 0), llList2Integer(dta, 1), llList2Integer(dta, 2)]), "rm_slave");
            if(slave>=RemoteloaderConf$slaves)slave = 0;
        }
        else if(METHOD == RemoteloaderMethod$asset){
            llGiveInventory(id, method_arg(0));
        }else if(METHOD == RemoteloaderMethod$attach){
            //llOwnerSay("Rezzing: "+method_arg(0));
            llRezAtRoot(method_arg(0), llGetPos(), ZERO_VECTOR, ZERO_ROTATION, 1);
                
            if(CB != ""){
                delayed_callbacks += [method_arg(0), SENDER_SCRIPT, CB, METHOD];
				return;
			}
        }
		else if(METHOD == RemoteloaderMethod$detach){
			runOmniMethod("jas Attached", AttachedMethod$remove, [method_arg(0)], TNN);
		}
        else if(METHOD == RemoteloaderMethod$rez){
			llRezAtRoot(method_arg(0), (vector)method_arg(1), (vector)method_arg(2), (rotation)method_arg(3), (integer)method_arg(4));
        }
        

    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}
 


