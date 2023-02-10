#include "xobj_core/classes/jas Animhandler.lsl" 

toggleAnim( string anim, integer on, float dur, int flags, float pre ){
	
	if( llGetInventoryType(anim) != INVENTORY_ANIMATION && anim != "sit" ){
		
		#ifndef AnimHandlerConf$suppressErrors
		qd("Error: Anim not found: "+anim);
		#endif
		return;
		
	}
	
	#ifdef AnimHandlerConf$beforeAnim
	if( !beforeAnim( anim ) )
		return;
	#endif
	
	
	if( on && flags&(jasAnimHandler$animFlag$stopOnMove|jasAnimHandler$animFlag$stopOnUnsit) )
		multiTimer(["m_"+anim, flags, 0.25, TRUE]);
	else
		multiTimer(["m_"+anim]);
		
	if( on && dur > 0 )
		multiTimer(["e_"+anim, "", dur, FALSE]);
	else
		multiTimer(["e_"+anim]);
		
	if( on && pre > 0 ){
		multiTimer(["p_"+anim, mkarr((list)anim+on+dur+flags), pre, FALSE]);
	}
	else{
	
		multiTimer(["p_"+anim]);
		if( on )
			llStartAnimation(anim);
		else
			llStopAnimation(anim);
			
	}

}



timerEvent( string id, string data ){

	string pre = llGetSubString(id, 0, 1);
	// move
	if( pre == "m_" ){
		
		integer f = (int)data;
		integer ai = llGetAgentInfo(llGetOwner());
		if( 
			(f & jasAnimHandler$animFlag$stopOnUnsit && ~ai & AGENT_SITTING) ||
			(f & jasAnimHandler$animFlag$stopOnMove && ai & AGENT_WALKING) 
		){
			
			toggleAnim( llGetSubString(id, 2, -1), FALSE, 0, 0, 0 );
		
		}
		
	}
	// End
	else if( pre == "e_" ){
	
		string anim = llGetSubString(id, 2, -1);
		toggleAnim( anim, FALSE, 0, 0, 0 );
		
	}
	// Predelay
	else if( pre == "p_" ){
		
		list d = llJson2List(data);
		toggleAnim(l2s(d, 0), l2i(d, 1), l2f(d, 2), l2i(d, 3), 0);
		
	}
	
	#ifdef AnimHandlerConf$useAudio
	if( id == "STOP_SOUND" )
		llStopSound();
	#endif
	
}

default{

    attach( key id ){llResetScript();}
    state_entry(){
		
        memLim(1.5);
        if( llGetAttached() )
			llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
		
		#ifdef onStateEntry
		onStateEntry
		#endif
		
    }
    
	#ifdef onPerms
	run_time_permissions( integer perm ){
		if( perm & PERMISSION_TRIGGER_ANIMATION ){
			onPerms();
		}
	}
	#endif

    timer(){multiTimer([]);}

	
    #include "xobj_core/_LM.lsl"
	
		if( method$isCallback )
			return;
		
		if( method$internal ){
		
			if( METHOD == AnimHandlerMethod$remInventory ){
				
				list assets = llJson2List(method_arg(0));
				list_shift_each(assets, val,
					if(llGetInventoryType(val) == INVENTORY_ANIMATION){
						llRemoveInventory(val);
					}
				)
				
			}
			
		}
		
		
		if( method$byOwner && METHOD == AnimHandlerMethod$get ){
		
			list anims = llJson2List(method_arg(0));
			list_shift_each(anims, anim,
			
				if( llGetInventoryType(anim) == INVENTORY_ANIMATION )
					llGiveInventory(id, anim);
				
			)
			
		}
		
		#ifndef AnimHandlerConf$allowAll
        if( method$byOwner ){
		#endif
		
            if( METHOD == AnimHandlerMethod$anim ){
			
				if( ~llGetPermissions()&PERMISSION_TRIGGER_ANIMATION ){
				
					#ifndef AnimHandlerConf$suppressErrors
					qd("Error: Anim permissions lacking, reattach  your HUD.");
					#endif
					return;
					
				}
			
                list anims = (list)method_arg(0);
				if( llJsonValueType((string)anims, []) == JSON_ARRAY )
					anims = llJson2List((string)anims);
					
				if( llJsonValueType(l2s(anims, 0), []) == JSON_ARRAY )
					anims = llJson2List(randElem(anims));
				
				integer start = (integer)method_arg(1);
				//float dly = (float)method_arg(2); not needed
				float end = (float)method_arg(3);
				integer flags = l2i(PARAMS, 4);
				
				if( flags&jasAnimHandler$animFlag$randomize )
					anims = [randElem(anims)];
				
				integer i;
				for( ; i<llGetListLength(anims); ++i ){
				
					string anim = llList2String(anims, i);
					integer s = start;
					string a = anim;
					float d = end;
					int f = flags;
					float predelay = 0;
					
					if( llJsonValueType(anim, []) == JSON_OBJECT ){
					
						if( isset(j(anim, "s")) )
							s = (int)j(anim, "s");
						if( isset(j(anim, "f")) )
							f = (int)j(anim, "f");
						if( isset(j(anim, "a")) )
							a = j(anim, "a");
						if( isset(j(anim, "d")) )
							d = (float)j(anim, "d");
						if( isset(j(anim, "p")) )
							predelay = (float)j(anim, "p");
						
					}

					toggleAnim(a, s, d, f, predelay);
					
				}
				
				
					
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
		#ifndef AnimHandlerConf$allowAll
        }
        #endif
        
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}
 
