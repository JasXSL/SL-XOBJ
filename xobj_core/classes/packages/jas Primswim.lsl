#define USE_DB4
#ifndef USE_EVENTS
#define USE_EVENTS
#endif
#if PrimswimCfg$USE_WINDLIGHT==1
	#ifndef USE_SHARED
		#define USE_SHARED ["jas RLV"]
	#endif
#endif

#include "../jas Supportcube.lsl"
#include "../jas RLV.lsl"
#include "../jas AnimHandler.lsl"
#include "../jas Climb.lsl"
#include "../jas Primswim.lsl"
#include "../jas PrimswimAux.lsl"
#include "../jas Interact.lsl"
#include "../jas Soundspace.lsl"
#include "../jas PrimswimParticles.lsl"


string wl_preset;
string wl_set;

vector climb_out_to;			// Position to climb out to
rotation climb_out_rot;			// Rotation to climb out at

key PH;							// Cache for particle helper
integer PCHAN;

// Timers
float timerSpeed;
float SSM = 1;					// SwimSpeedMulti PrimswimMethod$swimSpeedMultiplier

#define SURFACE_DEPTH -.4


integer STATUS;
setStatus( integer st ){
	STATUS = st;
	str s = (str)st;
	db4$freplace(PrimSwimCfg$table, PrimSwimCfg$table$status, s);
	//raiseEvent(PrimswimEvt$status, (str)s);
}


integer BFA;                        // Anims bitfield
#define BFA_IDLE 1
#define BFA_ACTIVE 2

#define TIMER_SWIM_CHECK "a"
#define TIMER_WETFEET_FADE "b"
#define TIMER_SPEEDCHECK "c"
#define TIMER_CLIMB_CD "f"
#define TIMER_COUT_CHECK "g"

integer BF_COMBAT;
#define BFC_RECENT_ATTACK 1
#define BFC_ATTACK_LINEDUP 2


// Checks if the object the script is in is intersecting id and returns the surface Z coordinate at that location
float waterZ(vector userPos, key id, integer inverse){
        vector vPos = userPos;
        
        list d = llGetObjectDetails(id, [OBJECT_POS, OBJECT_ROT]);
        vector gpos = llList2Vector(d,0);
        if(gpos == ZERO_VECTOR)return -1;
        rotation grot = llList2Rot(d,1);
        list bb = llGetBoundingBox(id);
        
        vector v1 = llList2Vector(bb,0);
        vector v2 = llList2Vector(bb,1);
        
        vPos = vPos-gpos;
        
        float fTemp;
        // Order in size so v2 is always greater
        if (v1.x > v2.x){fTemp = v2.x;v2.x = v1.x;v1.x = fTemp;}
        if (v1.y > v2.y){fTemp = v2.y;v2.y = v1.y;v1.y = fTemp;}
        if (v1.z > v2.z){fTemp = v2.z;v2.z = v1.z;v1.z = fTemp;}
        
        // Adjust the point to object rotation
        vPos/=llList2Rot(d,1);
        if (vPos.x < v1.x || vPos.y < v1.y || vPos.z < v1.z || vPos.x > v2.x || vPos.y > v2.y || vPos.z > v2.z)return 0;
        
        vector scale = <v2.x-v1.x, v2.y-v1.y, v2.z-v1.z>*.5;
        if(inverse)scale.z=-scale.z;
        vector offset = userPos-gpos;
        offset.z = 0;
        offset*=grot;
        offset.z+=scale.z;
        float ret = gpos.z+offset.z;
        return ret;
}


// -1 = is submerged
// 0 = not submerged (linden air)
// anything else = global Z for where bubble begins
float pointSubmerged(vector point){

    integer i; float submerged = 0;
    float s; float vs;
    for(i=0;i<llGetListLength(water);i++){
        if((vs = waterZ(point,llList2Key(water,i), FALSE))>0){
            submerged = -1;
            i = 9000;
        }
    }
    
    for(i=0; i<llGetListLength(airpockets); i++){
	
        if((s=waterZ(point, llList2Key(airpockets, i), TRUE))>0)
            return s;
        
    }
     
    return submerged;
	
}

updateAnimstate(){

    integer bf_start;
    integer bf_stop;
	integer sitting = llGetAgentInfo(llGetOwner())&AGENT_SITTING;
	integer forceStop = checkForceStop();
	integer override;
	#ifdef USE_SCRIPT_RUNNING_CHECK
		override = !scriptRunning();
	#endif
	
    if( STATUS & PrimswimStatus$IN_WATER && !sitting && !forceStop && !override ){
		if(~BFA&BFA_IDLE){
			bf_start = bf_start|BFA_IDLE;
			BFA = BFA|BFA_IDLE;
		}
    }else if(BFA&BFA_IDLE){
        bf_stop = bf_stop|BFA_IDLE;
        BFA = BFA&~BFA_IDLE;
    }
        
    if( STATUS&PrimswimStatus$SWIMMING && !sitting && !forceStop && !override ){
		if( ~BFA&BFA_ACTIVE ){
			bf_start = bf_start|BFA_ACTIVE;
			BFA = BFA|BFA_ACTIVE;
		}
    }else if( BFA&BFA_ACTIVE ){
        bf_stop = bf_stop|BFA_ACTIVE;
        BFA = BFA&~BFA_ACTIVE;
    }
    
	
	
    if( bf_start != 0 ){
	
        if( bf_start&BFA_IDLE )
			AnimHandler$anim(PrimswimCfg$animIdle,TRUE,0,0,0);
        if( bf_start&BFA_ACTIVE )
            AnimHandler$anim(PrimswimCfg$animActive, TRUE, 0,0,0);
        
    }
    if(bf_stop != 0){
	
        if( bf_stop&BFA_IDLE )
			AnimHandler$anim(PrimswimCfg$animIdle, FALSE, 0,0,0);
        if( bf_stop&BFA_ACTIVE )
			AnimHandler$anim(PrimswimCfg$animActive, FALSE, 0,0,0);
			
    }
	
}


enterWater(){

	#ifdef USE_SCRIPT_RUNNING_CHECK
		if(!scriptRunning())
			return;
	#endif

    setStatus(STATUS|PrimswimStatus$IN_WATER);
    setStatus(STATUS&~PrimswimStatus$FEET_SUBMERGED);
    setBuoyancy();
    float vel = llVecMag(llGetVel());
	int weight;
    if( vel > 8 )
		weight = 2;
	else if( vel > 5 )
		weight = 1;
	    
	vector gpos = llGetRootPosition();
	gpos.z = deepest+0.05;
	#ifdef onWaterEnter
		onWaterEnter
	#endif
    raiseEvent(PrimswimEvt$onWaterEnter, mkarr((list)weight + gpos));
	debugUncommon("Entered water");

    //dif=llGetVel()*.25;
    prePush=llGetVel()*.1;
    pp=.75;
	
	multiTimer([TIMER_COUT_CHECK, "", .5, TRUE]);
	
}

exitWater(){
	
    // Just exited water
    CONTROL = 0;
    llStopMoveToTarget();
	setStatus(STATUS&~PrimswimStatus$IN_WATER);
    setStatus(STATUS&~PrimswimStatus$AT_SURFACE);
    setStatus(STATUS&~PrimswimStatus$SWIMMING);
    setStatus(STATUS&~PrimswimStatus$FULLY_SUBMERGED);
    
    raiseEvent(PrimswimEvt$onWaterExit, "");
	#ifdef onWaterExit
		onWaterExit
	#endif

	
    setBuoyancy();
    // Diving soundspace
    Soundspace$dive(FALSE);
    //sendLocalCom(LINK_ROOT, SCRIPT_SOUNDSPACE, SCRIPT_NO_RET, "", SOUNDSPACE_DIVE, "0");
    toggleCam(FALSE);
    wl_set = "";
	
	debugUncommon("Exited water");
	raiseEvent(PrimswimEvt$atLedge, 0);
	multiTimer([TIMER_COUT_CHECK]);
	
}

#if PrimswimCfg$USE_WINDLIGHT==1
toggleCam(integer submerged){

	#ifdef USE_SCRIPT_RUNNING_CHECK
		if(!scriptRunning())
			return;
	#endif
	if( !isset(wl_set) )
		return;
    if(submerged){
	
        setStatus(STATUS|PrimswimStatus$CAM_UNDER_WATER);
        RLV$windlightPreset(LINK_ROOT, wl_set, TRUE);
		
    }
	else{
	
        setStatus(STATUS&~PrimswimStatus$CAM_UNDER_WATER);
        RLV$resetWindlight(LINK_ROOT);
		
	}
	
}
#else
	#define toggleCam(input)
#endif

float buoyancy_default = 0;
setBuoyancy(){

    float b = buoyancy_default;
    if( STATUS&PrimswimStatus$IN_WATER )
		b = .9;
    llSetBuoyancy(b);
	
}

vector ascale;
integer CONTROL;
list water;
list airpockets;
float deepest;		// Z position of surface in region coordinates
vector prePush;
float pp;

timerEvent(string id, string data){
	
	// Core frame
    if( id == TIMER_SWIM_CHECK ){
	
		#ifdef USE_SCRIPT_RUNNING_CHECK
			if(!scriptRunning()){
				return;
			}
		#endif
	
		integer stopped = checkForceStop();
        integer ainfo = llGetAgentInfo(llGetOwner());
        integer i;
        deepest = 0;
		
		#ifndef RC_DEFAULT
		list RC_DEFAULT = (list)RC_REJECT_TYPES + (RC_REJECT_AGENTS|RC_REJECT_PHYSICAL);
		#endif
		
		for( ; i < count(water) && water != [] && ~STATUS&PrimswimStatus$CLIMBING; ++i ){
		
			key wID = llList2Key(water,i);
			
			vector gpos = llGetRootPosition();
			
			float is = pointSubmerged(<gpos.x,gpos.y,gpos.z+ascale.z/2>); // Checks if feet are submerged, or if there's an airbubble.

			// Point is not an air bubble
			if( is ==-1 || is == 0 )
				is = waterZ(llGetRootPosition(), wID, FALSE);	// Get the water surface Z position at this location
			
			if( is > deepest ){
				deepest = is;
			}
			
			// How far below the water the top of your head is. If negative, it means your head is out of the water.
			float depth = is-(gpos.z+ascale.z/2);
			
			
			
			// Check for bottom
			list ray = llCastRay(gpos-<0,0,ascale.z/2-.1>,gpos-<0,0,ascale.z>, [RC_REJECT_TYPES,RC_REJECT_AGENTS]);
			vector bottom;
			if( llList2Integer(ray,-1) > 0 )
				bottom = llList2Vector(ray,1);
			
			// Handle camera
			vector pos = llGetCameraPos();
			if( pointSubmerged(pos) != 0 && (~STATUS&PrimswimStatus$AT_SURFACE || ~ainfo&AGENT_MOUSELOOK) ){
			
				if( ~STATUS&PrimswimStatus$CAM_UNDER_WATER )
					toggleCam(TRUE);
					
			}else if( STATUS&PrimswimStatus$CAM_UNDER_WATER )
				 toggleCam(FALSE);
			
			
			integer water_just_entered = FALSE;
			integer atSurface = TRUE;
			// Head is above the surface
			if( depth > 0 )
				atSurface = FALSE;

			// The water has been deleted, object no longer found
			if( is == -1 ){
				
				water = llDeleteSubList(water,i,i);
				--i; 
				
			}
			// We are not fully submerged. But might be standing in water
			else if( depth < SURFACE_DEPTH ){
			
				is = waterZ(gpos-<0,0,ascale.z/2>, wID, FALSE);
				if( is > deepest )
					deepest = is;
				
			}
			// We are fully submerged
			else if( depth > SURFACE_DEPTH || atSurface ){
				
				if( i > 0 ){ // INDEX THIS WATER
				
					water = [wID]+llDeleteSubList(water, i, i);
					i=0;
					
				}  
				
				vector turb; vector tan;
				
				list dta = llGetObjectDetails(wID, [OBJECT_DESC, OBJECT_ROT, OBJECT_POS]);
				string desc = llList2String(dta,0);
				rotation oRot = llList2Rot(dta,1);
				
				vector stream; 
				float cyclone; 
				float ssm; 
				wl_set = "Nacon's nighty fog";
				
				list split = llParseString2List(desc, ["$$"], []);
				list_shift_each(split, val, 
				
					list s = llParseString2List(val, ["$"], []);
					string t = llList2String(s, 0);
					if(t == Interact$TASK_WATER){
						stream = (vector)llList2String(s,1);
						cyclone = llList2Float(s,2);
						ssm = llList2Float(s,3);
						if(llGetListLength(s)>4)wl_set = llList2String(s,4);
					}
					
				)
				
				
				if( ~ainfo&AGENT_SITTING ){
				
					if( stream )
						turb = stream*llList2Rot(dta,1);
						
					if( cyclone ){
						vector oPos = llList2Vector(dta,2);
						
						vector dif = (gpos-oPos)/oRot;
						float dist = llVecDist(<oPos.x,oPos.y,0>,<gpos.x,gpos.y,0>);
						
						float atan = llAtan2(dif.y,dif.x);
						vector pre = <llCos(atan),llSin(atan),0>*oRot*dist;
						atan+=cyclone*5*DEG_TO_RAD;
						vector add = <llCos(atan),llSin(atan),0>*oRot*dist;
						tan = add-pre;
					}
					
				}
				
				vector dif; vector vel = llGetVel(); 
				if( ~STATUS&PrimswimStatus$IN_WATER ){ // Just entered water
				
					enterWater();
					water_just_entered = TRUE;
					
				}
				

				// Calculate direction
				if( CONTROL && !stopped && ~ainfo&AGENT_SITTING ){
				
					vector fwd; vector left; vector up;
					if( CONTROL&(CONTROL_FWD|CONTROL_BACK) )
						fwd = llRot2Fwd(llGetCameraRot());
					if( CONTROL&CONTROL_BACK )
						fwd = -fwd;
					if( CONTROL&(CONTROL_LEFT|CONTROL_RIGHT) )
						left = llRot2Left(llGetCameraRot());
					if( CONTROL&CONTROL_RIGHT )
						left = -left;
						
					if( CONTROL&CONTROL_UP )
						up = <0,0,1>;
					else if( CONTROL&CONTROL_DOWN )
						up = <0,0,-1>;

						dif=llVecNorm(fwd+left+up);
					
					// At surface
					if( atSurface && dif.z > -.5 )
						dif.z = 0;
					
					dif = llVecNorm(dif);
					
					if( ainfo&AGENT_ALWAYS_RUN )
						dif*=1.5;
						
					// Used for soft slowdown
					prePush = dif;   
					pp = 1.;
					
				}
				// Calculate pre-push. Not sure waht this is
				else if( pp > 0 ){
				
					pp-=.1;
					if( pp>0 )
						dif = prePush*(1-llSin(PI_BY_TWO+pp*PI_BY_TWO))*.5;
					if( water_just_entered )
						dif*=4;
					
				}
				
				
				// Swim sound
				if(
					~ainfo&AGENT_SITTING && 
					!stopped && 
					(
						CONTROL&(CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT|CONTROL_DOWN) || 
						(CONTROL&CONTROL_UP && ~STATUS&PrimswimStatus$AT_SURFACE) || 
						llVecMag(<dif.x,dif.y,0>) > .5
					)
				){ 
				
					if( ~STATUS&PrimswimStatus$SWIMMING )
						setStatus(STATUS|PrimswimStatus$SWIMMING);
					
				}
				else if( STATUS&PrimswimStatus$SWIMMING )
					setStatus(STATUS&~PrimswimStatus$SWIMMING);
					
				if( ssm <= 0 )
					ssm = 1;
				
				vector SP = gpos;

				float sprint = (( llGetAgentInfo(llGetOwner()) & (AGENT_ALWAYS_RUN|AGENT_WALKING) ) == (AGENT_ALWAYS_RUN|AGENT_WALKING));
				if( sprint == 0 && llGetAgentInfo(llGetOwner()) & AGENT_ALWAYS_RUN )
					sprint = -0.6;

				
				// Add whirlwind/stream
				dif += turb+tan;
				
				//else debug((string)SP + " "+(string)llVecDist(SP, SP+dif)+" "+(string)(llVecDist(gpos,gpos+dif)+.5));
				
				float mag = llVecMag(dif); // Calculate the magnitude before messing with it

				// Surface detect
				integer SUB = TRUE;
				// Unless pivoting heavily down, set SP.z to the surface
				if( depth <= 0 && !water_just_entered && dif.z>-.1 && atSurface ){
				
					// Then set to swim at surface level
					if( bottom.z+ascale.z > depth+SURFACE_DEPTH ){
					
						SP.z = is-SURFACE_DEPTH-.1-ascale.z*.5;
						dif.z = 0;
						setStatus(STATUS|PrimswimStatus$AT_SURFACE);
						
					}
					else{
						setStatus(STATUS&~PrimswimStatus$AT_SURFACE);
					}
					SUB = FALSE;
					
				}
				else
					setStatus(STATUS&~PrimswimStatus$AT_SURFACE);
				
				integer B;	// We're bottoming out at our current position, so only use XY
				// Check if we're at the bottom, in that case only move on XY
				ray = llCastRay(gpos, gpos-<0,0,ascale.z*.75>, RC_DEFAULT);
				if( l2i(ray, -1) == 1 && dif.z < 0 ){
					B = true;
					dif.z = 0;
				}
				
				vector a = dif;
				float b = a.z;
				a.z = 0;
				
				// XY and Z have different speeds
				dif = (llVecNorm(dif)*ssm*SSM*(1+sprint*.5))*.75;
				
				
				SP += dif*mag;
				
				
				// XY checking isn't needed because we're moving relative to our current position
				
				// BOttoming out is calculated from the position we want to go to, not where we're at
				ray = llCastRay(SP, SP-<0,0,ascale.z*.6>, RC_DEFAULT);
				if( l2i(ray, -1) == 1 ){
				
					// We are at the bottom
					vector v = l2v(ray, 1);
					SP.z = v.z+ascale.z*.6;
					dif.z = 0;
					
				}
			
				
				//llSetText((str)B+"\n"+(str)SP+"\n"+(str)dif+"\n"+(str)llGetTime(), <1,1,1>, 1);
				
								
				float t = .5;
				if( water_just_entered )
					t=2;
					
				if( !stopped ){
					llMoveToTarget(SP, t);
				}
				
				// HANDLES DIVING SOUNDS
				if( SUB ){ // Entire body is submerged
					
					if( ~STATUS&PrimswimStatus$FULLY_SUBMERGED ){
						
						// Dive
						setStatus(STATUS|PrimswimStatus$FULLY_SUBMERGED);
						Soundspace$dive(TRUE);
						
					}
					
				}
				else if( STATUS&PrimswimStatus$FULLY_SUBMERGED ){
				
					// Emerge
					
					Soundspace$dive(FALSE);
					setStatus(STATUS&~PrimswimStatus$FULLY_SUBMERGED);
					vector pos = gpos;
					pos.z = deepest;
					list ray = llCastRay(pos+<0,0,.1>, pos-<0,0,.2>, [
						RC_REJECT_TYPES, RC_REJECT_AGENTS|RC_REJECT_PHYSICAL, 
						RC_DATA_FLAGS, RC_GET_NORMAL|RC_GET_ROOT_KEY, 
						RC_DETECT_PHANTOM,TRUE, 
						RC_MAX_HITS,3
					]);
					integer ri;
					rotation rot;
					for( ;ri<l2i(ray,-1)*3; ri+=3 ){
						if( l2k(ray, ri) == wID ){
							vector norm = l2v(ray, ri+2);
							vector axis = <1,0,0>;
							rot = norm2rot(norm, axis);
							pos += <0,0,.05>*rot;
							ray = [];
						}
					}
					raiseEvent(PrimswimEvt$submerge, mkarr((list)0 + pos + rot));
					
				}
				
				updateAnimstate();
				multiTimer([id,"", timerSpeed, FALSE]);
				// We are submerged, let's return
				return;
				
			}
						
		}
            
		db4$freplace(PrimSwimCfg$table, PrimSwimCfg$table$surfaceZ, deepest);
		
		
        if( deepest > 0 || STATUS & PrimswimStatus$IN_WATER ){
            
			if( ~STATUS&PrimswimStatus$FEET_SUBMERGED ){

                setStatus(STATUS|PrimswimStatus$FEET_SUBMERGED);
                setStatus(STATUS|PrimswimStatus$HAS_WET_FEET);
                if( deepest > 0 )
					multiTimer([TIMER_WETFEET_FADE]);
				raiseEvent(PrimswimEvt$feetWet, "1");
				
            }
			
        }
		else if( STATUS & PrimswimStatus$FEET_SUBMERGED ){
		
            setStatus(STATUS&~PrimswimStatus$FEET_SUBMERGED);
            multiTimer([TIMER_WETFEET_FADE,"", 30, FALSE]);
			
        }
		
		// Couldn't find
        if( STATUS & PrimswimStatus$IN_WATER && ~STATUS & PrimswimStatus$CLIMBING )
			exitWater();
			
        updateAnimstate();
        multiTimer([id,"", timerSpeed, FALSE]);

    }
    
	// Removes wet feet
    else if( id == TIMER_WETFEET_FADE ){
	
        setStatus(STATUS&~PrimswimStatus$HAS_WET_FEET);
		raiseEvent(PrimswimEvt$feetWet, "0");
		
    }
	
	// See if you can climb out
	else if( id == TIMER_COUT_CHECK ){
	
		// Checks if you're at an edge and can climb out
		if(
			STATUS & PrimswimStatus$IN_WATER && 
			~llGetAgentInfo(llGetOwner())&AGENT_SITTING && 
			STATUS & PrimswimStatus$AT_SURFACE && 
			~STATUS & PrimswimStatus$CLIMBING
		){
		
			// Check ray
			vector vrot = llRot2Euler(llGetRootRotation());
			vector f = llRot2Fwd(llEuler2Rot(<0,0,vrot.z>));
			
			vector gpos = llGetRootPosition();
			
			// Need at least 1m free above the user
			vector avTop = gpos+<0,0,ascale.z/2*0.95>;
			float headOffset = 1;			
			integer rejecttypes = RC_REJECT_AGENTS|RC_REJECT_LAND|RC_REJECT_PHYSICAL;
			
			// Checks if the position above your head is clear
			list up = llCastRay(avTop, avTop+<0,0,headOffset>, [RC_REJECT_TYPES, rejecttypes]);
			// Checks if there is a platform within 0.5m in front of the user
			list fwd = llCastRay(
				avTop+<0,0,headOffset>, 
				avTop+f*headOffset-<0,0,headOffset>, 
				[
					RC_REJECT_TYPES, rejecttypes, RC_DATA_FLAGS, RC_GET_NORMAL
				]
			);
			vector normal = l2v(fwd, 2);
			vector landing = l2v(fwd, 1)+<0,0,.1>;	// Floor plus a little bit just in case

			

			// So far so good
			if( l2i(up, -1) == 0 && l2i(fwd, -1) == 1 && normal.z > 0.9 ){
				
				// Check if there is enough space to fit the avatar
				up = llCastRay(landing, landing+<0,0,ascale.z>, [RC_REJECT_TYPES, rejecttypes]);

				if( l2i(up, -1) == 0 ){

					// We just reached a ledge
					if( climb_out_to == ZERO_VECTOR ){
						raiseEvent(PrimswimEvt$atLedge, "1");
					}
					// Base climb out pos and rot
					climb_out_to = landing-<0,0,.1>;	// Remove offset above
					climb_out_rot = llEuler2Rot(<0,0,vrot.z>);
					
					// Find the edge rotation if possible, using 5cm as a buffer
					fwd = llCastRay(<gpos.x, gpos.y, landing.z-0.05>, landing-<0,0,0.05>, [
						RC_REJECT_TYPES, rejecttypes, RC_DATA_FLAGS, RC_GET_NORMAL
					]);
					
					if( l2i(fwd, -1) == 1 ){
						
						normal = l2v(fwd, 2);
						climb_out_to = 
							// Edge position
							l2v(fwd, 1)+
							// Plus 0.25m
							llVecNorm(l2v(fwd, 1)-<gpos.x, gpos.y, landing.z-0.05>)*0.25
						;
						climb_out_rot = llRotBetween(<-1,0,0>, llVecNorm(<normal.x, normal.y, 0>));
				
					}
					
					climb_out_to.z += ascale.z/2-0.1;
					return;
					
				}
				
			}
			
		}

		
		// No longer at ledge
		if( climb_out_to != ZERO_VECTOR )
			raiseEvent(PrimswimEvt$atLedge, "");
		climb_out_to = ZERO_VECTOR;
		
	}
    
    else if( id == TIMER_SPEEDCHECK ){ // Dynamic timer speed

        multiTimer([id, "", 4, TRUE]);
        
        if( STATUS & PrimswimStatus$IN_WATER || count(water) ){
		
            if( ~STATUS & PrimswimStatus$TIMER_FAST ){
			
				setStatus(STATUS|PrimswimStatus$TIMER_FAST);
				timerSpeed = PrimswimCfg$maxSpeed;
				multiTimer([TIMER_SWIM_CHECK,"",timerSpeed, FALSE]);
				
			}
			
			return;
			
        }
        
        if( STATUS & PrimswimStatus$TIMER_FAST ){
		
            timerSpeed = PrimswimCfg$minSpeed;
            multiTimer([TIMER_SWIM_CHECK, 0, timerSpeed, FALSE]);
			
        }
        setStatus(STATUS&~PrimswimStatus$TIMER_FAST);
        
    }
    
    else if( id == TIMER_CLIMB_CD )
		setStatus(STATUS&~PrimswimStatus$CLIMBING);
    
    
    
	
}

integer climbOut(){

	if( climb_out_to == ZERO_VECTOR || STATUS & PrimswimStatus$CLIMBING )
		return FALSE;
		
	list tasks = [
		SupportcubeBuildTask(Supportcube$tSetPos, [climb_out_to]),
        SupportcubeBuildTask(Supportcube$tSetRot, [climb_out_rot]),
        SupportcubeBuildTask(Supportcube$tForceSit, ([FALSE, TRUE])),
        SupportcubeBuildTask(Supportcube$tRunMethod, ([llGetLinkKey(LINK_ROOT), "jas AnimHandler", AnimHandlerMethod$anim, llList2Json(JSON_ARRAY, ["water_out", TRUE, 0])])),
        SupportcubeBuildTask(Supportcube$tDelay, [2]),
        SupportcubeBuildTask(Supportcube$tForceUnsit, [])
    ];
                
    RLV$cubeTask(tasks);
    setStatus(STATUS|PrimswimStatus$CLIMBING);
	
	climb_out_to = ZERO_VECTOR;
	raiseEvent(PrimswimEvt$atLedge, "0");
    multiTimer([TIMER_CLIMB_CD, "", 1, FALSE]);
	return TRUE;
	
}

onEvt( string script, integer evt, list data ){

	#ifdef USE_CUSTOM_EVENTS
	onCustomEvt(script, evt, data);
	#endif
	
	integer d = llList2Integer(data,0);
    if( script == "#ROOT" ){
	
        if( evt == evt$BUTTON_PRESS ){
		
            CONTROL = CONTROL|d;
			#ifndef PrimSwimCfg$useJasInteract
			if( CONTROL&CONTROL_UP )
				climbOut();
			#endif
				
        }
        else if( evt == evt$BUTTON_RELEASE )
			CONTROL = CONTROL&~d;
			
    }
	
	#ifdef PrimSwimCfg$useJasInteract
	
	if( 
		script == "jas Interact" && 
		evt == InteractEvt$onInteract && 
		l2s(data, 0) == "_PRIMSWIM_CLIMB_" 
	)climbOut();
	
	#endif
	
}


default{

    state_entry(){
	
		PCHAN = Primswim$partChan;
		ascale = llGetAgentSize(llGetOwner());
        llStopMoveToTarget();
        setBuoyancy();
        llSensor(PrimswimConst$pnWater, "", PASSIVE|ACTIVE, 90, PI);
        
		multiTimer([TIMER_SPEEDCHECK, "", .1, TRUE]);
        // Slow timer at start
		timerSpeed = PrimswimCfg$minSpeed;
        multiTimer([TIMER_SWIM_CHECK,"", timerSpeed, FALSE]);
			
		if( llGetInventoryType("jas PrimswimAux") == INVENTORY_SCRIPT )
			llResetOtherScript("jas PrimswimAux");
        if( llGetAttached() )
			llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
		
    }
        
    sensor(integer total){ 
	
        integer i;
        for( ; i < total; ++i ){
		
            key id = llDetectedKey(i);
            if( llListFindList(water, (list)id) == -1)
                water += (list)id;
            
        }
        llSensorRepeat(PrimswimConst$pnWater, "", PASSIVE|ACTIVE, 90, PI, 5);
		
    }
	
    no_sensor(){
		llSensorRepeat(PrimswimConst$pnWater, "", PASSIVE|ACTIVE, 90, PI, 5);
	}
    
    #include "xobj_core/_LM.lsl"

    if( method$isCallback )
		return;
		
    if( method$internal ){
	
        if( METHOD == PrimswimMethod$airpockets )
			airpockets = PARAMS;
		
		else if( METHOD == PrimswimMethod$swimSpeedMultiplier )
			SSM = l2f(PARAMS, 0);
		
		else if( METHOD == PrimswimMethod$particleHelper )
			PH = method_arg(0);
		
    }

    #define LM_BOTTOM 
    #include "xobj_core/_LM.lsl"

    timer(){multiTimer([]);}
    
}


