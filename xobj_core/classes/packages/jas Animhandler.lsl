#include "xobj_core/classes/jas Animhandler.lsl" 


timerEvent(string id, string data){
    if((integer)data){
        //llOwnerSay("DLY starting");
        llStartAnimation(id);
    }
    else llStopAnimation(id);
}

default
{
    on_rez(integer start){
        llResetScript();
    }
    state_entry()
    {
        memLim(1.5);
        if(llGetAttached())llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
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
        if(method$byOwner){
            if(METHOD == AnimHandlerMethod$anim){
                if(~llGetPermissions()&PERMISSION_TRIGGER_ANIMATION){
                    debugRare("Error: Anim permissions lacking, reattach  your HUD.");
                    return;
                }
                if(llGetInventoryType(method_arg(0)) != INVENTORY_ANIMATION && method_arg(0) != "sit"){
                    debugRare("Error: Anim not found: "+method_arg(0));
                    return;
                }
                integer start = (integer)method_arg(1);
                float dly = (float)method_arg(2);
                if(dly){
                    multiTimer([method_arg(0), start, dly, FALSE]);
                }
                
                if(start){
                    llStartAnimation(method_arg(0));
                    //llOwnerSay("Starting: "+method_arg(0));
                }
                else{
                    //llOwnerSay("Stopping: "+method_arg(0));
                    llStopAnimation(method_arg(0));
                }
            }
            if(nr == METHOD_CALLBACK){ 
                
            }
        }
        
        
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}
 
