// Conf
#include "xobj_core/classes/jas Remoteloader.lsl" 
#include "xobj_core/classes/jas Attached.lsl" 

#include "xobj_core/_CLASS_STATIC.lsl"

integer slave = 0;
list slaves;			// [(float)time]
 
list delayed_callbacks; // [name, script, callback, method]
integer dcs = 4;

integer BFL;
#define BFL_QUE 0x1

list queue;				// [(key)id, (str)script, (int)pin, (int)startparam]
#define QSTRIDE 4


next(){
	if(BFL&BFL_QUE || queue == []){
		if(queue == []){
			multiTimer(["C", "", 4, FALSE]);	// Load finish timer
		}
		return;
	}
	integer i;
	for(i=0; i<=RemoteloaderConf$slaves && queue != []; i++){
		// Oldest slave is still cooling down, wait
		if(llList2Float(slaves, slave)+3.1 >= llGetTime()){
			BFL = BFL|BFL_QUE;
			multiTimer(["A", "", llCeil(llList2Float(slaves, slave)+3-llGetTime()), FALSE]);
			multiTimer(["C"]);		// Clear load finish timer
			return;
		}
	
		//qd("Loading "+llKey2Name(llList2String(queue,0))+" :: "+llList2String(queue, 1)+" with slave "+(string)slave);
		slaves = llListReplaceList(slaves, [llGetTime()], slave, slave);
		llMessageLinked(LINK_THIS, slave, llList2Json(JSON_ARRAY, [llList2Key(queue,0), llList2String(queue, 1), llList2Integer(queue, 2), llList2Integer(queue, 3)]), "rm_slave");
		queue = llDeleteSubList(queue, 0, QSTRIDE-1);
		slave++;
		if(slave>=RemoteloaderConf$slaves) slave = 0;
		multiTimer(["C", "", 4, FALSE]);	// load finish timer
	}
}


timerEvent(string id, string data){
	if(id == "A"){
		BFL = BFL&~BFL_QUE;
		next();
	}
	else if(id == "C"){
		#ifdef onLoadFinish
		onLoadFinish;
		#endif
	}
}


default
{
    on_rez(integer start){
        llResetScript();
    }
    
    object_rez(key id){
        list s = llList2ListStrided(delayed_callbacks, 0,-1, 3);
        integer pos = llListFindList(s, [llKey2Name(id)]);
        if(~pos){
             
            string script = llList2String(delayed_callbacks,pos*dcs+1);
            integer method = llList2Integer(delayed_callbacks,pos*dcs+3);
            string callback = llList2String(delayed_callbacks, pos*dcs+2);
            sendCallback((string)LINK_SET, script, method, id, callback);
            delayed_callbacks = llDeleteSubList(delayed_callbacks, pos*dcs, pos*dcs+dcs-1);
        }
    } 
	
	state_entry(){
		// qd("state_entry");
		slaves=[];
		integer i;
		for(i=0; i<=RemoteloaderConf$slaves; i++){
			slaves+=[-3.0];
		}
		
		#ifdef stateEntry
		stateEntry;
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

        if(nr == METHOD_CALLBACK){ 
            return;
        }
            
        if(METHOD == RemoteloaderMethod$load){
			list dta = PARAMS;
			if(id == "")id = llList2String(dta, -1);		// Lets you override the ID to send to
			
			string s = llList2String(dta, 0);
			list scripts = [s];
			if(llJsonValueType(s, []) == JSON_ARRAY){		// Load multiple
				scripts = llJson2List(s);
			}
			
			list_shift_each(scripts, val,
				queue+= ([id, val])+llList2List(dta, 1, 2);
			)
			next();
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
 


