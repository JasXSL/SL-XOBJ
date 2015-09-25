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
		if(method$isCallback)return;
		
        if(method$byOwner){
            if(METHOD == AnimHandlerMethod$anim){
                list anims = [method_arg(0)];
				if(llJsonValueType((string)anims, []) == JSON_ARRAY)anims = llJson2List((string)anims);
				integer start = (integer)method_arg(1);
				float dly = (float)method_arg(2);
					
				list_shift_each(anims, anim, 
					if(~llGetPermissions()&PERMISSION_TRIGGER_ANIMATION){
						debugRare("Error: Anim permissions lacking, reattach  your HUD.");
						return;
					}
					if(llGetInventoryType(anim) != INVENTORY_ANIMATION && method_arg(0) != "sit"){
						debugRare("Error: Anim not found: "+method_arg(0));
						return;
					}

					if(dly)
						multiTimer([method_arg(0), start, dly, FALSE]);
					
					
					if(start)
						llStartAnimation(anim);
					
					else
						llStopAnimation(anim);
					
				)
            }
        }
        
        
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}
 
