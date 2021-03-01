#include "xobj_core/_ROOT.lsl"
#include "xobj_core/classes/jas VibHub.lsl"


string ID_TOKEN;
string VERSION;
string HW_VERSION;
list CAPABILITIES;
int NUM_PORTS = 4;

integer PORTS_BUTT = 2;
integer PORTS_GROIN = 1;
integer PORTS_BREASTS = 12;

integer MENU;
#define MENU_KEY 0
#define MENU_DEFAULT 1
#define MENU_PORT 2

integer PORT_CFG;	// Port configured in MENU_PORT
// Butt/Groin/breasts

integer diagChan;			// Channel to dialog on
key metaFetch;				// HTTP Request to get device meta
integer dialogFetch;		// Should we open the dialog after fetching device data?


string portsToNames( integer ports ){
    
    list out;
    integer i;
    for(; i < 4; ++i ){
        
        if( ports & (1<<i) )
            out += (i+1);
        
    }
    
    if( out )
        return llList2CSV(out);
        
    return "NONE";
    
}

openDialog(){
    
    if( ID_TOKEN == "" )
        MENU = MENU_KEY;
    
    if( MENU == MENU_KEY ){
        
        string text = "\nVibHub Key not found. Please paste it here:";
        if( ID_TOKEN )
            text = "\nEnter a new VibHub key to change device:";
        llTextBox(llGetOwner(), text, diagChan);
        
    }
    
    else if( MENU == MENU_DEFAULT ){
        
        string text = "\n: DEVICE :\n"+
            llGetSubString(ID_TOKEN, 0, 3)+"********";
        
        text += "\nVersion: "+VERSION;
        text += "\nPorts: "+(str)NUM_PORTS;
        text += "\nHW Version: "+HW_VERSION;
        text += "\nCapabilities: ";
        
        integer i;
        for( ; i < count(CAPABILITIES); i += 2 )           
            text += "\n    - "+l2s(CAPABILITIES, i) + " : " + l2s(CAPABILITIES, i+1);            
            
        text += "\n\n: PORTS :";
            text += "\nButt: "+portsToNames(PORTS_BUTT);
            text += "\nGroin: "+portsToNames(PORTS_GROIN);
            text += "\nBreasts: "+portsToNames(PORTS_BREASTS);
                    
        
        llDialog(llGetOwner(), text, [
            "Butt", 
            "Groin", 
            "Breasts", 
            "Change Device", 
            "Refresh",
			"Zero",
			"Pulse"
        ], diagChan);
        
    }
    
    else if( MENU == MENU_PORT ){
        
        list slots = [
            "Butt", "Groin", "Breasts"
        ];
        
        string text = "\n: Ports :\n";
        text += "\nSelect ports for: "+l2s(slots, PORT_CFG);
        
        list buttons = (list)"Back";
        list current;
        
        integer cur = PORTS_BUTT;
        if( PORT_CFG == 1 )
            cur = PORTS_GROIN;
        else if( PORT_CFG == 2 )
            cur = PORTS_BREASTS;
        
        integer i;
        for(; i < NUM_PORTS; ++i ){
            
            integer n = i+1;
            buttons += (string)n;
            if( cur & (1 << i) )
                current += n;
            
        }
        
        text += "\nActive Ports: ";
        if( current )
            text += llList2CSV(current);
        else
            text += "NONE";
  
        llDialog(llGetOwner(), text, buttons, diagChan);
        
    }
    
}


fetchMeta( integer popup ){
    
    dialogFetch = popup;
    metaFetch = jasVibHub$meta$get(ID_TOKEN);
    
}


key sendProgram( string program, float duration ){

	multiTimer(["reset"]);
	if( duration > 0 )
		multiTimer(["reset", 0, duration, FALSE]);
		
	return jasVibHub$program$execute( ID_TOKEN, program );

}

resetAllPorts(){

	string program = jasVibHub$newProgram( 0, 0 );
	
	string stage = jasVibHub$newStage();
	jasVibHub$stage$setIntensity(stage, 0);
	jasVibHub$program$addStage( program, stage );
	
	sendProgram(program, 0);
	
}

// Named timers
timerEvent(string id, string data){
    
	if( id == "reset" )
		resetAllPorts();
	
}


default{

	changed( integer change ){
        if( change & CHANGED_OWNER )
            llResetScript();
    }

    state_entry(){
		
		diagChan = llCeil(llFrand(0xFFFFFFF));
        llListen(diagChan, "", llGetOwner(), "");
		
    }
    
	// Timer event
    timer(){multiTimer([]);}
	
	
	http_response( key id, integer status, list meta, string body ){
        
        if( id != metaFetch )
			return;
		
		integer success = j(body, "success") == JSON_TRUE;
		if( !success )
			return;
			
		string data = j(body, "message");
		
		NUM_PORTS = (int)j(data, "numPorts");
		if( NUM_PORTS < 1 )
			NUM_PORTS = 4;
			
		// Clear ports above max for this device
		integer total = (1<<NUM_PORTS)-1;
		PORTS_BUTT = PORTS_BUTT&total;
		PORTS_GROIN = PORTS_GROIN&total;
		PORTS_BREASTS = PORTS_BREASTS&total;
		
		VERSION = j(data, "version");
		HW_VERSION = j(data, "hwversion");
		CAPABILITIES = [];
		
		raiseEvent(VibHubEvt$meta, mkarr((list)data));
		raiseEvent(VibHubEvt$ports, mkarr((list)PORTS_BUTT + PORTS_GROIN + PORTS_BREASTS));
		
		list caps = llJson2List(j(data, "capabilities"));
		integer i;
		for( ; i < count(caps); i += 2 ){
			
			string val = l2s(caps, i+1);
			if( llToLower(val) == "custom" || val == JSON_TRUE ){
				
				if( val == JSON_TRUE )
					val = "FULL";
				else
					val = "CUSTOM";
					
				CAPABILITIES += (list)l2s(caps, i) + val;
				
			}
			
		}    
						
		// Manual refresh
		if( dialogFetch ){
			MENU = MENU_DEFAULT;
			openDialog();
		}
		
            
        
        
    }
	
	listen(integer chan, string name, key id, string message){
        if( chan != diagChan )
			return;
			
		if( MENU == MENU_KEY ){
            
            message = llStringTrim(message, STRING_TRIM);
			if( message ){
				
				ID_TOKEN = message;
				llOwnerSay("ID Token changed to '"+ID_TOKEN+"'");
				fetchMeta(TRUE);
				
			}
			
		}
		
		else if( MENU == MENU_PORT ){
			
			if( message == "Back" ){
				
				MENU = MENU_DEFAULT;
				openDialog();
				return;
				
			}
			
			integer nr = (integer)message;
			
			integer has = PORTS_BUTT;
			if( PORT_CFG == 1 )
				has = PORTS_GROIN;
			else if( PORT_CFG == 2 )
				has = PORTS_BREASTS;
			
			// Remove the number from all
			PORTS_BUTT = PORTS_BUTT &~ nr;
			PORTS_GROIN = PORTS_GROIN &~ nr;
			PORTS_BREASTS = PORTS_BREASTS &~ nr;
			
			if( ~has & nr ){
				if( PORT_CFG == 0 )
					PORTS_BUTT = PORTS_BUTT | nr;
				else if( PORT_CFG == 1 )
					PORTS_GROIN = PORTS_GROIN | nr;
				else
					PORTS_BREASTS = PORTS_BREASTS | nr;
			}
			
			raiseEvent(VibHubEvt$ports, mkarr((list)PORTS_BUTT + PORTS_GROIN + PORTS_BREASTS));
			openDialog();
			
		}
		
		// Default menu
		else{
			
			if( message == "Refresh" )
				fetchMeta(TRUE);
			
			else if( message == "Change Device"){
				
				MENU = MENU_KEY;
				openDialog();
				
			}
			else if( message == "Zero" ){
			
				llOwnerSay("Setting all ports to 0");
				resetAllPorts();
				openDialog();
			
			}
			else if( message == "Pulse" ){
			
				llOwnerSay("Sending test pulse on all channels");
				string program = jasVibHub$newProgram( 0, -1 );
				
				string stage = jasVibHub$newStage();
				jasVibHub$stage$setIntensity(stage, 255);
				jasVibHub$stage$setDuration( stage, 0.5 );
				jasVibHub$program$addStage(program, stage);
				
				stage = jasVibHub$newStage();
				jasVibHub$stage$setIntensity(stage, 0);
				jasVibHub$stage$setDuration( stage, 0.5 );
				jasVibHub$program$addStage(program, stage);
				
				sendProgram(program, 0);
				
				openDialog();
			
			}
			
			list slots = ["Butt", "Groin", "Breasts"];
			integer pos = llListFindList(slots, (list)message);
			if( ~pos ){
				
				PORT_CFG = pos;
				MENU = MENU_PORT;
				openDialog();
				
			}
			
		}
		
		
	}
    
	
	// This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
    if(method$isCallback){
        return;
    }

    if( method$byOwner ){
	
		if( METHOD == jasVibHubMethod$openDialog ){
			
			MENU = MENU_DEFAULT;
			openDialog();
	
		}
		
		else if( METHOD == jasVibHubMethod$initialize ){
			
			if( ID_TOKEN == "" )
				openDialog();
			else
				fetchMeta(FALSE);
				
			raiseEvent(VibHubEvt$ports, mkarr((list)PORTS_BUTT + PORTS_GROIN + PORTS_BREASTS));
				
		}
		
		else if( METHOD == jasVibHubMethod$sendProgram ){
			
			CB_DATA = (list)sendProgram(method_arg(0), l2f(PARAMS, 1));
		
		}
	
        
    }
	
	// Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}

