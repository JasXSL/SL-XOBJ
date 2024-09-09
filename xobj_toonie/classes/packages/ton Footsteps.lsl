#define USE_EVENTS
#include "../ton Footsteps.lsl"
#include "xobj_core/classes/jas Interact.lsl"
#include "xobj_core/classes/jas RLV.lsl"
#include "xobj_core/classes/jas Primswim.lsl"



  
string CURRENT_WALKABLE; 
string CURRENT_DESC;
float CURRENT_VOL = -1;
list SOUND_CACHE;
key previousSound;

integer BFL;
#define BFL_IN_AIR 1
#define BFL_SWIMMING 2

#define TIMER_STEP "a"
#define TIMER_RECHECK "b"

integer pInteract; 

string targDesc;
string WL;
key targ;



onEvt(string script, integer evt, list data){ 
    if(script == "jas Primswim"){
        
        if( evt == PrimswimEvt$onWaterEnter )
			BFL = BFL|BFL_SWIMMING;
        else if( evt == PrimswimEvt$onWaterExit )
			BFL = BFL&~BFL_SWIMMING;
		#ifdef gotTable$primSwim
		else if( evt == PrimswimEvt$waterChanged ){
			WATER = PrimSwimGet$water();
		}
		#endif
		
    }
	
	#ifdef customEvt
		customEvt(script, evt, data)
	#endif
	
} 

recheck(){
	vector pos = llGetRootPosition();
	list ray = llCastRay(pos, pos-<0,0,4>, [RC_REJECT_TYPES, RC_REJECT_AGENTS]);
	
	if( llList2Integer(ray, -1) <= 0 ){
		
		CURRENT_DESC = "";
		return;
		
	}
	
	string desc = prDesc(llList2Key(ray,0));
	if( desc == CURRENT_DESC )
		return;


	CURRENT_DESC = llList2Key(ray, 0);
	list split = explode("$$", desc);
	integer found = FALSE;
	
	list_shift_each(split, val, 
	
		list p = explode("$", val);
		string task = llList2String(p,0);
		
		if( task == Interact$TASK_FOOTSTEPS ){
		
			setWalkable(llList2String(p,1));
			
			if( llGetListLength(p) >= 3 )
				CURRENT_VOL = llList2Float(p,1);
			else
				CURRENT_VOL = -1;
				
			found = TRUE;
			
		}  
		else if( task == Interact$TASK_WL_PRESET ){
		
			string wl = llList2String(p,1);
			if( wl != WL ){
			
				WL = wl;
				RLV$windlightPreset(LINK_ROOT, WL, FALSE);
				
			}
			
		}
		
	)
	
	if( found )
		return;
	
	CURRENT_VOL = -1;
	setWalkable("DEFAULT");
}

timerEvent(string id, string data){
    if( id == TIMER_STEP ){ 
	
        integer status = llGetAgentInfo(llGetOwner());
        if( status&AGENT_IN_AIR ){
		
			BFL=BFL|BFL_IN_AIR; 
			return;

		}
		
        BFL = BFL&~BFL_IN_AIR;
        if( 
			~status&AGENT_WALKING ||
			SOUND_CACHE == [] ||
			BFL&BFL_SWIMMING
		){
			return;
		}


        float vol = CURRENT_VOL;
        if( vol == -1 ){ 
		
            vol = FootstepsCfg$WALK_VOL;
			
            if( status&AGENT_ALWAYS_RUN )
				vol = FootstepsCfg$RUN_VOL;
				
            if( status&AGENT_CROUCHING )
				vol = FootstepsCfg$CROUCH_VOL;
			
        }
		
        if( vol <= 0 )
			return;
        
		list snd = SOUND_CACHE;
        
		if( llGetListLength(snd) >1 )
            remByVal(snd, previousSound);
        
        llTriggerSound(randElem(snd), vol);
		
    }
	
	else if( id == TIMER_RECHECK ){
        
		recheck();
        
    }
}

// Use "" to just init
setWalkable( string walkable ){
    
	if( walkable == CURRENT_WALKABLE || walkable == "" )
		return;
		
    CURRENT_WALKABLE = walkable;
    
    SOUND_CACHE = [];
    integer i; integer pushing;
    for( ; i < count(SOUNDS); ++i ){
	
        integer type = llGetListEntryType(SOUNDS, i);
        if(type != TYPE_KEY){ 
            if(llList2String(SOUNDS, i) == CURRENT_WALKABLE){
                pushing = TRUE;
            }
            else if(pushing)return;
        }
        else if(pushing){
            SOUND_CACHE += llList2Key(SOUNDS, i);
        }
		
    }
} 

// Use water position when thudding
#ifdef gotTable$primSwim
list WATER;
#endif

default{

    on_rez(integer mew){
        llResetScript();
    }
    
    state_entry(){
	
        init();
        setWalkable("DEFAULT");
        multiTimer([TIMER_STEP, "", FootstepsCfg$SPEED, TRUE]);
        multiTimer([TIMER_RECHECK, "", .5, TRUE]);
		#ifdef gotTable$primSwim
		WATER = PrimSwimGet$water(); // Caching
		#endif
		
    }
    
    collision_start(integer total){
	
		#ifdef onCollision
		onCollision();
		#endif
		
        if( ~BFL&BFL_IN_AIR )
			return;
        BFL = BFL&~BFL_IN_AIR;
        vector vel = llGetVel();
        if( vel.z < -4 ){
		
			// Setting this will make us cache and use water info from primswim to prevent thuds when landing in water
			#ifdef PrimSwimCfg$table
			vector as = llGetAgentSize(llGetOwner());
			vector gp = llGetPos();
			list ray = llCastRay(gp, gp-<0,0,as.z>, []);
			
			if( l2i(ray, -1) == 1 ){
			
				vector as = l2v(ray, 1)+<0,0,.05>;
				float z = PrimswimHelper$pointSubmergedFast(as);
				if( z > 0 ){
				
					// If we thud into water it is up to this script to handle the splash
					gp.z = z;
					integer speed = 1 + (vel.z < -12);
					PrimswimAux$triggerSplash(speed, gp);
					
					return;
				}
				
			}
			#endif
		
			recheck();
            integer i;
            list available; integer parsing;
            for( ; i < llGetListLength(COLS); ++i ){
			
                integer type = llGetListEntryType(COLS, i);
                if( type != TYPE_KEY ){ 
				
                    if( llList2String(COLS, i) == CURRENT_WALKABLE )
                        parsing = TRUE;
                    else if( parsing )
						i = llGetListLength(COLS);
						
                } 
                else if( parsing )
                    available += llList2Key(COLS, i);
				
            }
			
            if( available != [] ){
			
                llTriggerSound(randElem(available), 1);
                float range = llFabs(vel.z);
				onThud(range);
				
            }
			
        }
		
		
		
    }
    
    timer(){multiTimer([]);}
    
    #include "xobj_core/_LM.lsl" 
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
    
}

