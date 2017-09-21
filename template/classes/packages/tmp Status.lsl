// Here's a generic script
// Uncomment this if you need root to accept events. You'll want to create an onEvt(string script, integer evt, string data) function
#define USE_EVENTS

// You can uncomment this if you want to enable debugging. Debug levels are DEBUG_ALL, DEBUG_COMMON, DEBUG_UNCOMMON, DEBUG_RARE and DEBUG_USER
// You can also use the qd("Message") function to quickly override debug settings
//#define DEBUG DEBUG_COMMON

// REPLACE THIS WITH YOUR PROJECT CORE FILE
#include "template/_core.lsl"
 
// Named timers
timerEvent(string id, string data){
    
}

// When event is received
onEvt(string script, integer evt, list data){
	
}

default 
{
	// Start up the script
    state_entry()
    {
		
    }
    
	// Timer event
    timer(){multiTimer([]);}
    
	
	// This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
    /*
        Included in all these calls:
        METHOD - (int)method  
        INDEX - (int)obj_index
        PARAMS - (var)parameters 
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task 
    */ 
	
	// Here's where you receive callbacks from running methods
    if(method$isCallback){
        return;
    }
    
	// Internal means the method was sent from within the linkset
    if(method$internal){
        
    }
    
	// ByOwner means the method was run by the owner of the prim
    if(method$byOwner){
        
    }
	
	// Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
