#define USE_EVENTS
#include "../jas Primswim.lsl"
#include "../jas PrimswimAux.lsl"
#include "../jas PrimswimParticles.lsl"
#include "../../_ROOT.lsl"

int BFL;
#define BFL_WAIT_SPAWN 0x1

#define TIMER_WAIT_SPAWN "a"
#define TIMER_SWIMSTROKE "d"
#define TIMER_FOOTSPLASH "e"

list AIR_POCKETS;			// Handles all the air pockets
key PARTICLE_HELPER;		// Active particle generator prim
integer CACHE_CHAN; 		// Channel it communicates on


onEvt( string script, integer evt, list data){
	
	if( script != "jas Primswim" )
		return;
		
	if( evt == PrimswimEvt$onWaterEnter ){
		
		int weight = l2i(data, 0);
		list sounds = (list)
			PrimswimAuxCfg$splashSmall +
			PrimswimAuxCfg$splashMed +
			PrimswimAuxCfg$splashBig
		;
		llTriggerSound(l2k(sounds, weight), 1);		
		send(jasPrimswimParticles$onWaterEntered, data);
		
		multiTimer([TIMER_SWIMSTROKE, "", 1., TRUE]);
		
	}
	else if( evt == PrimswimEvt$onWaterExit ){
		
		llTriggerSound(PrimswimAuxCfg$soundExit, .75);
		send(jasPrimswimParticles$onWaterExited, data);
		multiTimer([TIMER_SWIMSTROKE]);
		
		
	}
	else if( evt == PrimswimEvt$submerge && !l2i(data, 0) ){
		
		llTriggerSound(PrimswimAuxCfg$soundExit, .5);
		vector pos = (vector)l2s(data, 1);
		rotation rot = (rotation)l2s(data, 2);
		send(jasPrimswimParticles$emerge, [pos, rot]);
		
	}
	else if( evt == PrimswimEvt$feetWet ){
	
		int wet = l2i(data, 0);
		if( wet )
			multiTimer([TIMER_FOOTSPLASH, 0, PrimswimAuxCfg$footstepSpeed, TRUE]);
		else
			multiTimer([TIMER_FOOTSPLASH]);
	
	}
	
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
	multiTimer([TIMER_WAIT_SPAWN, 0, 5, FALSE]);

}

timerEvent( string id, string data ){

	if( id == TIMER_SWIMSTROKE ){
	
		if( PrimSwimGet$status() & PrimswimStatus$SWIMMING )
			llTriggerSound(PrimswimAuxCfg$soundStroke, llFrand(.25)+.5);
		
	}
	
	else if( id == TIMER_WAIT_SPAWN ){
		
		BFL = BFL&~BFL_WAIT_SPAWN;
	
	}
	
	else if( id == TIMER_FOOTSPLASH ){
	
		float deepest = PrimSwimGet$surfaceZ();
		integer status = PrimSwimGet$status();
        if( ( deepest <=0 && ~status&PrimswimStatus$HAS_WET_FEET ) || status&PrimswimStatus$IN_WATER )
            return;
		
		// Splash sound
		vector ascale = llGetAgentSize(llGetOwner());
        integer ainfo = llGetAgentInfo(llGetOwner());
        vector gpos = llGetRootPosition();
        float depth = deepest-(gpos.z-ascale.z/2);
				
        if( ainfo&AGENT_WALKING ){
		
            // Trigger splash
            if( depth < .1 ){

				if( deepest <= 0 )
					depth = 0;
					
				vector pos = <gpos.x,gpos.y,gpos.z-ascale.z/2+depth>;
				send(jasPrimswimParticles$onFeetWetSplash, [0, pos]);
				
				list sounds = PrimswimAuxCfg$soundFootstepsShallow;
				llTriggerSound(randElem(sounds), .75+llFrand(.25));
                return;
				
            }
            else if( depth<.4 ){
				
				list sounds = PrimswimAuxCfg$soundFootstepsMed;
				llTriggerSound(randElem(sounds), .75+llFrand(.25));
                
			}
            else{
				
				list sounds = PrimswimAuxCfg$soundFootstepsDeep;
				llTriggerSound(randElem(sounds), .75+llFrand(.25));
                
			}
			send(jasPrimswimParticles$onFeetWetSplash, [1, <gpos.x,gpos.y,deepest>]);
			
        }
		
    }
	
	
}

default{
     
    state_entry(){
	
		CACHE_CHAN = Primswim$partChan;
        llSensorRepeat(PrimswimConst$pnAirpocket, "", ACTIVE|PASSIVE, 90, PI, 5);
		memLim(1.5);
		
    }
	
	timer(){
		multiTimer([]);
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
		

    #define LM_BOTTOM 
    #include "xobj_core/_LM.lsl"
} 


