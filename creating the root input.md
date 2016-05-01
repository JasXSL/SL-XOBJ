The root input file is used to accept inputs and forward them to the right scripts.
You can create it any way you want, but here's my recommended one:

```
#define SCRIPT_IS_ROOT
#include "myFirstProject/_core.lsl"

default 
{
    on_rez(integer mew){
        llResetScript();
    }
    
    state_entry()
    {
        initiateListen();
        if(llGetAttached())
            llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
        
        // Optional DB3 table creation  
        /*
            list tables = ["#ROOT", "got Bridge"];
            db3$addTables(tables);
        */
        // If you don't use DB3 you can reset the other scripts or initialize them here.
        // Otherwise you'll want to wait for a callback further down before initializing, as the schema has to be built before they can utilize DB3
        resetAllOthers();
    }

    
    touch_start(integer total){
        if(llDetectedKey(0) != llGetOwner())return;
        raiseEvent(evt$TOUCH_START, llList2Json(JSON_ARRAY, [llDetectedLinkNumber(0), llDetectedKey(0)]));
    }
    touch_end(integer total){ 
        if(llDetectedKey(0) != llGetOwner())return;
        raiseEvent(evt$TOUCH_END, llList2Json(JSON_ARRAY, [llDetectedLinkNumber(0), llDetectedKey(0)]));
    }
    run_time_permissions(integer perm){
        if(perm&PERMISSION_TAKE_CONTROLS){
            llTakeControls(CONTROL_ML_LBUTTON|CONTROL_UP, TRUE, FALSE);
        }
    }
    
    changed(integer change){
        if(change&CHANGED_INVENTORY){
            llSleep(1);
            resetAll();
        }
    }
    
    control(key id, integer level, integer edge){
        if(level&edge)raiseEvent(evt$BUTTON_PRESS, (string)(level&edge));
        if(~level&edge)raiseEvent(evt$BUTTON_RELEASE, (string)(~level&edge));
    }

    #include "xobj_core/_LISTEN.lsl"
    
    // This is the standard input, it captures link_message
    #include "xobj_core/_LM.lsl" 
    /*
        Included in all these calls:
        METHOD - (int)method - The method ran
        PARAMS - (var)parameters - A JSON array of arguments, you can use method_arg(0), method_arg(1) etc to get these as strings
        SENDER_SCRIPT - (str)script - Script that ran the method
        CB - (Callback only) The callback you specified when you sent a task
    */ 
    // Here's where you receive callbacks from running methods
    if(method$isCallback){
        // If using DB3, you'll want to initialize the linkset from here
        /*
		if(SENDER_SCRIPT == "#ROOT" && METHOD == stdMethod$setShared){
			//qd("Tables created: "+PARAMS);
			resetAllOthers();
		}
		*/
        return;
    }
    
    // Internal means the method was sent from within the linkset
    if(method$internal){
	}
	
	// Either internal or the method was sent by the owner
	if(method$byOwner){
	}
    
    // Code available to any sender
	
	
    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
```



