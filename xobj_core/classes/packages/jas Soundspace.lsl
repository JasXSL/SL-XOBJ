/*
	
	
*/
#include "xobj_core/_ROOT.lsl"
#include "xobj_core/classes/jas Interact.lsl"
#include "xobj_core/classes/jas Soundspace.lsl"

#ifndef SOUNDSPACE_ADDITIONAL
	#define SOUNDSPACE_ADDITIONAL []
#endif

integer BFL;
#define BFL_IN_WATER 1
#define BFL_QUEUE 2			// Timer needs to update soundspace
 
// Active sound
string currentSound;
float currentsoundvol = .5;
float preSoundVol = 0;

// Active ground soundspace
string groundsound;
float groundsoundvol = .5;

// Active override sound set via script
string overridesound;
float overridesoundvol = .5;

float last_update;				// Last update of soundspace

// Time when last change was
float tweenStarted;
int aux;			// Which prim are we tweening up?

integer getAuxLink( integer pr ){
	if( !pr )
		return SoundSpaceConst$prim0;
	return SoundSpaceConst$prim1;
}

updateSoundspace(){


    string cSound;						// 
	float cSoundVol;
	
	// Scripted sound override
	if( overridesound ){
	
		cSound = overridesound;
		cSoundVol = overridesoundvol;
		
	}
	// Underwater is second
    else if( BFL&BFL_IN_WATER ){
        
		cSound = SP_UNDERWATER;
        cSoundVol = .5;
		
    }
	// Ground sound last
    else{
        
		cSoundVol = groundsoundvol;
        cSound = groundsound;
		
    }
	
	if( cSound == "NULL" )
		cSound = "";
	
	if( cSound == currentSound && cSoundVol == currentsoundvol )
		return;
	
	// Need to wait for the current tween
	if( llGetTime()-last_update < 1.0 && ~BFL&BFL_QUEUE ){
		multiTimer(["Q", 0, llGetTime()-last_update+0.1, FALSE]);
		return;
	}
	
	last_update = llGetTime();
	currentSound = cSound;
	
	
	
	
	// Turn it off if NULL
    if( cSound == "" ){
	
        clearSoundspace();
        return;
		
    }

	preSoundVol = currentsoundvol;
	currentsoundvol = cSoundVol;
	
	list SS = SP_DATA+SOUNDSPACE_ADDITIONAL;
	key sound = cSound;
	// See if sound is a shorthand
	integer i;
    for( ; i<llGetListLength(SS); i+=2 ){
	
        if( llList2String(SS,i) == cSound )
			sound = llList2String(SS,i+1);
			
	}
	
	aux = !aux;
	
	int link = getAuxLink(aux);
	llLinkPlaySound(link, sound, 0.01, SOUND_LOOP);
	tweenStarted = llGetTime();
	
	multiTimer(["V", 0, 0.05, TRUE]);
	
}
clearSoundspace(){

    currentSound = "";
    groundsound = "";
	preSoundVol = currentsoundvol;
	currentsoundvol = 0;
	tweenStarted = llGetTime();
	aux = !aux;
	llLinkStopSound(getAuxLink(aux));
	multiTimer(["V", 0, 0.05, TRUE]);
 
}

timerEvent( string id, string data ){

	// Volume
	if( id == "V" ){
	
		float perc = llGetTime()-tweenStarted;
		if( perc > 1 ){
			perc = 1;
			multiTimer([id]);
		}
		

		integer link = getAuxLink(aux);
		llLinkAdjustSoundVolume(link, perc*currentsoundvol);
		link = getAuxLink(!aux);
		llLinkAdjustSoundVolume(link, (1.0-perc)*preSoundVol);

	}
	
	else if( id == "Q" ){
		BFL = BFL&~BFL_QUEUE;
		updateSoundspace();
	}
		

	// Raycast for soundspace
	else if( id == "T" ){
	
		// Raycast
        list ray = llCastRay(llGetRootPosition(), llGetRootPosition()-<0,0,10>, [RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]);

        if( llList2Integer(ray,-1)==1 ){
		
            string desc = (string)llGetObjectDetails(llList2Key(ray,0), [OBJECT_DESC]);
            list split = llParseString2List(desc, ["$$"], []);
            
            getDescTaskData(desc, dta, Interact$TASK_SOUNDSPACE);
            string ssp = llList2String(dta,0);  
            float v = llList2Float(dta,1);
            if( dta != [] && isset(ssp) ){
			
                if( groundsound != ssp || v != groundsoundvol ){ 
				
                    groundsoundvol = v;
                    groundsound = ssp;
					updateSoundspace();
						
                }
				
            } 
			
        }
		
	}

}


default{

    state_entry(){
	
        clearSoundspace(); 
        llSetMemoryLimit(llCeil(llGetUsedMemory()*1.5));
		multiTimer(["T", 0, 0.5, TRUE]);
        llSetStatus(STATUS_DIE_AT_EDGE, TRUE);
		
    }

    timer(){
        multiTimer([]);
    }
    
    #include "xobj_core/_LM.lsl" 
    /*
        Included in all these calls:  
        METHOD - (int)method 
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task
    */
    if(method$isCallback){
        return;
    }
		
	if(METHOD == SoundspaceMethod$override){
	
		key s = (key)method_arg(0);
		overridesound = "";
		
		if( s ){
		
			overridesound = s;
			overridesoundvol = (float)method_arg(1);
			
		}
		
		updateSoundspace();
		
	}
	
		
    if( id != "" )
		return;
    
	if( METHOD == SoundspaceMethod$dive ){
	
        if((integer)method_arg(0) && ~BFL&BFL_IN_WATER){
		
            BFL = BFL|BFL_IN_WATER;
            updateSoundspace();
			
        }
        else if(!(integer)method_arg(0)&& BFL&BFL_IN_WATER){
		
            BFL = BFL&~BFL_IN_WATER;
            updateSoundspace();
			
        }
		
    }
	else if( METHOD == SoundspaceMethod$reset ){
		
		clearSoundspace();
		
	}
	
    #define LM_BOTTOM   
    #include "xobj_core/_LM.lsl" 
    
}


