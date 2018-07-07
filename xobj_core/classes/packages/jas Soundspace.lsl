#include "xobj_core/_ROOT.lsl"
#include "xobj_core/classes/jas SoundspaceAux.lsl"
#include "xobj_core/classes/jas Interact.lsl"
#include "xobj_core/classes/jas Soundspace.lsl"

#ifndef SOUNDSPACE_ADDITIONAL
	#define SOUNDSPACE_ADDITIONAL []
#endif

integer BFL;
#define BFL_IN_WATER 1
#define BFL_QUEUE 2			// Timer needs to update soundspace
 
// Active sound
string currentsound; 
float currentsoundvol = .5;

// Active ground soundspace
string groundsound;
float groundsoundvol = .5;

// Active override sound set via script
key overridesound;
float overridesoundvol = .5;

float last_update;				// Last update of soundspace

integer aux = 1;   
updateSoundspace(){
	
	if( last_update+2 > llGetTime() ){
	
		BFL = BFL|BFL_QUEUE;
		return;
		
	}

    string cs = currentsound;
    float csv = currentsoundvol;
	// Scripted sound override
	if( overridesound ){
	
		cs = overridesound;
		csv = overridesoundvol;
		
	}
	// Underwater is second
    else if( BFL&BFL_IN_WATER ){
        
		cs = SP_UNDERWATER;
        csv = .5;
		
    }
	// Ground sound last
    else{
        
		csv = groundsoundvol;
        cs = groundsound;
		
    }
	
	// Turn it off if NULL
    if( cs == "" || cs == "NULL" ){
	
        clearSoundspace();
        return;
		
    }
	
	if( cs == currentsound && csv == currentsoundvol )
		return;
	
	last_update = llGetTime();
	
	list SS = SP_DATA+SOUNDSPACE_ADDITIONAL;
	key sound = cs;
	
	// See if sound is a shorthand
	integer i;
    for( i=0; i<llGetListLength(SS); i+=2 ){
	
        if(llList2String(SS,i) == cs)
			sound = llList2String(SS,i+1);
			
	}
	
	SoundspaceAux$set(aux, sound, csv);
	++aux;
    if( aux > 2 )
		aux = 1;
	
	//qd("Soundspace is now "+(str)cs);
}
clearSoundspace(){

    currentsound = "";
    groundsound = "";
	SoundspaceAux$set(0, "", 0);
 
}


default
{
    state_entry(){
	
        clearSoundspace(); 
        llSetMemoryLimit(llCeil(llGetUsedMemory()*1.5));
		llSetTimerEvent(0.5);
        llSetStatus(STATUS_DIE_AT_EDGE, TRUE);
		
    }

    timer(){
	
        // Raycast
        list ray = llCastRay(llGetPos(), llGetPos()-<0,0,10>, [RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]);

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
                    if(currentsound == "")
						updateSoundspace();
						
                }
				
            } 
			
        }
		
		if( BFL&BFL_QUEUE && llGetTime() > last_update+2 ){
			
			BFL = BFL&~BFL_QUEUE;
			updateSoundspace();
			
		}
			
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
		
		qd("Overridesound is now "+(str)s);
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
		
		currentsound = "";
		groundsound = "";
		updateSoundspace();
		
	}
	
    #define LM_BOTTOM   
    #include "xobj_core/_LM.lsl" 
    
}


