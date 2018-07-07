#include "xobj_core/_ROOT.lsl"
#include "xobj_core/classes/jas SoundspaceAux.lsl"

float vol_max = 1;
float vol;
integer BFL;
#define BFL_DIR_UP 1

default{

    state_entry(){
	
        llStopSound();
        llSetMemoryLimit(llCeil(llGetUsedMemory()*1.5));
		
    }
    
    timer(){
		
		float dir = -0.05;
		if( BFL&BFL_DIR_UP )
			dir = -dir;
		
		vol += dir;
		if( vol < 0 ){
		
			vol = 0;
			llStopSound();
			llSetTimerEvent(0);
			return;
			
		}
		
		if( vol > vol_max ){
			
			vol = vol_max;
			llSetTimerEvent(0);
			
		}
		
		llAdjustSoundVolume(vol);
		
    }
    
    #include "xobj_core/_LM.lsl" 
	
        if( id != "" || method$isCallback )
			return;

        if( METHOD == SoundspaceAuxMethod$set ){
			
			int active = l2i(PARAMS, 0);
			key sound = method_arg(1);
			float v = l2f(PARAMS, 2);
			
			if( active != THIS_SUB && vol > 0 ){
				
				llSetTimerEvent(0.05);
				BFL = BFL&~BFL_DIR_UP;
			
			}
			else if( active == THIS_SUB ){
				
				vol = 0;
				vol_max = v;
				BFL = BFL|BFL_DIR_UP;
				llStopSound();
				llLoopSound(sound, 0.01);
				llSetTimerEvent(0.05);
			
			}

        }
        
        
    #define LM_BOTTOM   
    #include "xobj_core/_LM.lsl" 
}


