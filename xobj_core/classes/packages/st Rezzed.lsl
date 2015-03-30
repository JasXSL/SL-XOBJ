// Preprocessor shortcuts
#include "xobj_core/classes/st Rezzed.lsl" 
#include "xobj_core/classes/st Remoteloader.lsl" 

// Include local head and class type
#include "xobj_core/_CLASS_STATIC.lsl"

default
{ 
    on_rez(integer start){
        if(start == playerChan(llGetOwner())){
			llSleep(.25);
            integer pin = llFloor(llFrand(0xFFFFFFF));
			llSetRemoteScriptAccessPin(pin);
            runMethod(llGetOwner(), "st Remoteloader", RemoteloaderMethod$load, [cls$name, pin, 2], TNN);
        } 
    }
    
    state_entry()
    {
		#if RezzedConf$removeByName!=0
		runOmniMethod(cls$name, RezzedMethod$remove, [], TARG_NULL, NORET, llGetObjectName());
		#endif
		llListen(playerChan(llGetOwner()), "", "", "");
		llListen(0, "", llGetOwner(), "");
        memLim(1.5);
		if(llGetStartParameter()){
			raiseEvent(evt$SCRIPT_INIT, "");
		}
    }
	
	#define LISTEN_LIMIT_BY_NAME
	#define LISTEN_LIMIT_ALLOW_WILDCARD
	#include "xobj_core/_LISTEN.lsl"
    
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
			if(METHOD == RezzedMethod$remove){
                llDie();
            }
		}
        
        
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}
 







