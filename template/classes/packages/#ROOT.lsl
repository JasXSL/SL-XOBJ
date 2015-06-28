// Here's a template root input script with lots of features

// First off you need to define that this script is the root script
#define SCRIPT_IS_ROOT

// Listen override can be used to bypass the standard xobj input/output in case you need really fast but less secure calls
// Overridden messages get sent to the onListenOverride(chan, id, message) message
// #define LISTEN_OVERRIDE_ALLOW_ALL 
// #define LISTEN_OVERRIDE -10

// Uncomment this if you need root to accept events. You'll want to create an onEvt(string script, integer evt, string data) function
//#define USE_EVENTS

// You can uncomment this if you want to enable debugging. Debug levels are DEBUG_ALL, DEBUG_COMMON, DEBUG_UNCOMMON, DEBUG_RARE and DEBUG_USER
// You can also use the qd("Message") function to quickly override debug settings
//#define DEBUG DEBUG_COMMON
#include "template/_core.lsl"
 
// We'll accept custom key bindings through the RootMethod$statusControls method
integer STATUS_CONTROLS;

// These are global variables for doubleclick and click hold detection
float pressStart;
float lastclick;
integer lcb;

// This is the function that grabs the controls
takeControls(){
    if(!llGetAttached())return;
    if(~llGetPermissions()&PERMISSION_TAKE_CONTROLS) 
        return llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS|PERMISSION_ATTACH);
    integer conts = CONTROL_ML_LBUTTON|CONTROL_UP|STATUS_CONTROLS;
    llTakeControls(conts, TRUE, FALSE); 
}

// If you want to use listen override, it ends up here
// onListenOverride(integer chan, key id, string message){}

// Timer to handle double clicks and click hold
timerEvent(string id, string data){
    if(llGetSubString(id, 0, 1) == "H_"){
        integer d = (integer)data;
        d++;
        raiseEvent(evt$BUTTON_HELD_SEC, mkarr(([(integer)llGetSubString(id, 2, -1), d])));
        multiTimer([id, d, 1, FALSE]);
    }
}

default 
{
	// Initialize on attach
    on_rez(integer bap){
        raiseEvent(evt$SCRIPT_INIT, "");
        if(llGetAttached())takeControls();
    }
    
	// Start up the script
    state_entry()
    {
		// If you use the RLV supportcube
        runOmniMethod("jas Supportcube", SupportcubeMethod$killall, [], TNN);
        
		// Reset all other scripts
		resetAllOthers();
		
		// Start listening
		initiateListen();
		
		// Take controls if attached
        if(llGetAttached())takeControls(); 
    }
    
	// Timer event
    timer(){multiTimer([]);}
    
	// Touch handlers
    touch_start(integer total){
        if(llDetectedKey(0) != llGetOwner())return;
        string ln = llGetLinkName(llDetectedLinkNumber(0));
        string desc = (string)llGetLinkPrimitiveParams(llDetectedLinkNumber(0), [PRIM_DESC]);
        raiseEvent(evt$TOUCH_START, llList2Json(JSON_ARRAY, [llDetectedLinkNumber(0), llDetectedKey(0)]));
    }
    touch_end(integer total){ 
        if(llDetectedKey(0) != llGetOwner())return;
        raiseEvent(evt$TOUCH_END, llList2Json(JSON_ARRAY, [llDetectedLinkNumber(0), llDetectedKey(0)]));
    }
	
	
    run_time_permissions(integer perm){
        if(perm&PERMISSION_TAKE_CONTROLS)
            takeControls();
    }

	
    control(key id, integer level, integer edge){
        if(level&edge){ // Pressed
            pressStart = llGetTime();
            raiseEvent(evt$BUTTON_PRESS, (string)(level&edge));
            if(llGetTime()-lastclick < .5){
                raiseEvent(evt$BUTTON_DOUBLE_PRESS, (string)(level&edge&lcb));
                lcb = 0;
            }else{
                lastclick = llGetTime();
                lcb = (level&edge);
            }
            
            integer i;
            for(i=0; i<32; i++){
                integer pow = llCeil(llPow(2,i));
                if(level&edge&pow)multiTimer(["H_"+(string)pow, 0, 1, TRUE]);
            }
        }
        
        if(~level&edge){
            raiseEvent(evt$BUTTON_RELEASE, (string)(~level&edge)+","+(string)(llGetTime()-pressStart));
            integer i;
            for(i=0; i<32; i++){
                integer pow = llCeil(llPow(2,i));
                if(~level&edge&pow)multiTimer(["H_"+(string)pow]);
            }
        } 
    }
    
    changed(integer change){
        if(change&CHANGED_OWNER)llResetScript();
    }
	
	
	// This is the listener
	#include "xobj_core/_LISTEN.lsl"
    
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
        if(METHOD == RootMethod$statusControls){
            STATUS_CONTROLS = (integer)method_arg(0); 
            takeControls();
        }
    }
    
	// ByOwner means the method was run by the owner of the prim
    if(method$byOwner){
        
    }
	
	// Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
