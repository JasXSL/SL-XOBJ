#define USE_EVENTS
#include "../jas Primswim.lsl"
#include "../jas PrimswimAux.lsl"
#include "../jas PrimswimParticles.lsl"
#include "../../_ROOT.lsl"

int BFL;
#define BFL_WAIT_SPAWN 0x1

list AIR_POCKETS;			// Handles all the air pockets
key PARTICLE_HELPER;		// Active particle generator prim
integer CACHE_CHAN; 		// Channel it communicates on

onEvt( string script, integer evt, list data){
	
	if( script != "jas Primswim" )
		return;
		
	if( evt == PrimswimEvt$onWaterEnter )
		send(jasPrimswimParticles$onWaterEntered, data);
	
	else if( evt == PrimswimEvt$onWaterExit )
		send(jasPrimswimParticles$onWaterExited, data);
	
}

list QUEUE;
send( string task, list data ){
	
	if( llKey2Name(PARTICLE_HELPER) )
		return llRegionSayTo(PARTICLE_HELPER, CACHE_CHAN, mkarr((list)task+data));
	
	QUEUE = (list)task+data;
	spawnHelper();
	
}

spawnHelper(){
	
	if( BFL&BFL_WAIT_SPAWN )
		return;
	llRezAtRoot("PrimSwimParts", llGetRootPosition()-<0,0,3>, ZERO_VECTOR, ZERO_ROTATION, 1);
	BFL = BFL|BFL_WAIT_SPAWN;
	llSetTimerEvent(5);

}

default
{     
    state_entry(){
	
		CACHE_CHAN = Primswim$partChan;
        llSensorRepeat(PrimswimConst$pnAirpocket, "", ACTIVE|PASSIVE, 90, PI, 5);
		memLim(1.5);
		
    }
	
	timer(){
		BFL = BFL&~BFL_WAIT_SPAWN;
		llSetTimerEvent(0);
	}

    object_rez(key id){ 
	
        if( llKey2Name(id) == "PrimSwimParts" ){
		
			if( PARTICLE_HELPER )
				llRegionSayTo(PARTICLE_HELPER, CACHE_CHAN, "DIE");
			
			PARTICLE_HELPER = id;
			Primswim$particleHelper(PARTICLE_HELPER);
			llSleep(.1);
			send(l2s(QUEUE, 0), llDeleteSubList(QUEUE, 0, 0));
			
        }
		
    }
    
    sensor( integer total ){
	
        list output; 
		integer i; 
		integer recache;
        for( ; i<total; i++ ){
		
            if( !recache ){
			
                integer pos = llListFindList(AIR_POCKETS, [llDetectedKey(i)]);
                if( pos==-1 )
					recache = TRUE;
					
            }
			
            output+=llDetectedKey(i);
			
        }
		
		if( !recache )
			return;
			
        AIR_POCKETS = output;
        Primswim$airpockets(AIR_POCKETS);
		
    }
    
    no_sensor(){
	
        if( AIR_POCKETS != [] )
			Primswim$airpockets([]);
        AIR_POCKETS = [];
  
	}

    #include "xobj_core/_LM.lsl"
    if( method$isCallback || !method$internal )
		return;
		
	if( METHOD == PrimswimAuxMethod$spawn )
		spawnHelper();
	

    #define LM_BOTTOM 
    #include "xobj_core/_LM.lsl"
} 


