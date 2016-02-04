#include "xobj_core/classes/jas Animhandler.lsl" 


timerEvent(string id, string data){
	string pre = llGetSubString(id, 0, 1);
	if(pre == "e_" || pre == "r_"){
		integer start = FALSE;
		if(pre == "r_")start = (integer)data;
		

		list anims = llJson2List(llGetSubString(id, 2, -1));
		list_shift_each(anims, anim, 		
			if(start){
				llStartAnimation(anim);
			}
			else{
				llStopAnimation(anim);
			}
		)
	}
	#ifdef AnimHandlerConf$useAudio
	if(id == "STOP_SOUND")llStopSound();
	#endif
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
		
		if(method$internal){
			if(METHOD == AnimHandlerMethod$remInventory){
				list assets = llJson2List(method_arg(0));
				list_shift_each(assets, val,
					if(llGetInventoryType(val) == INVENTORY_ANIMATION){
						llRemoveInventory(val);
					}
				)
			}
		}
		
        if(method$byOwner){
            if(METHOD == AnimHandlerMethod$anim){
                list anims = [method_arg(0)];
				if(llJsonValueType((string)anims, []) == JSON_ARRAY)anims = llJson2List((string)anims);
				integer start = (integer)method_arg(1);
				float dly = (float)method_arg(2);
				float end = (float)method_arg(3);
				
				
				integer i;
				for(i=0; i<llGetListLength(anims); i++){
					string anim = llList2String(anims, i);
					if(~llGetPermissions()&PERMISSION_TRIGGER_ANIMATION){
						debugRare("Error: Anim permissions lacking, reattach  your HUD.");
						return;
					}
					if(llGetInventoryType(anim) != INVENTORY_ANIMATION && method_arg(0) != "sit"){
						debugRare("Error: Anim not found: "+method_arg(0));
						return;
					}

					if(start)
						llStartAnimation(anim);
					
					else
						llStopAnimation(anim);
				}
				
				if(dly)
					multiTimer(["r_"+mkarr(anims), start, dly, FALSE]);
				if(end)
					multiTimer(["e_"+mkarr(anims), "", end, FALSE]);
            }
			#ifdef AnimHandlerConf$useAudio
			if(METHOD == AnimHandlerMethod$sound){
				llStopSound();
				if((key)method_arg(0)){
					key uuid = method_arg(0);
					float vol = (float)method_arg(1);
					integer type = (int)method_arg(2);
					float timeout = (float)method_arg(3);
					if(type == 0)return llTriggerSound(uuid, vol);
					
					if(type == 1)llPlaySound(uuid, vol);
					else if(type == 2)llLoopSound(uuid, vol);
					if(timeout>0){
						multiTimer(["STOP_SOUND", "", timeout, FALSE]);
					}
				}
			}
			#endif
        }
        
        
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}
 
