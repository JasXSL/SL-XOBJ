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


string wl_preset;
string wl_set;

vector climb_out_to;			// Position to climb out to
rotation climb_out_rot;			// Rotation to climb out at

// Timers
float timerSpeed;
float ssm = 1;

#define SURFACE_DEPTH -.4
#define FOOTSTEP_SPEED .4

integer BFL;
#define BFL_IN_WATER 1
#define BFL_SWIMMING 2              // Actively swimming
#define BFL_CAM_UNDER_WATER 4
#define BFL_FULLY_SUBMERGED 8
#define BFL_FEET_SUBMERGED 16
#define BFL_WITHIN_20M_OF_WATER 32
//#define BFL_STOP_ANIMATION 64       // Stop swimming because of effect
#define BFL_HAS_WET_FEET 256
#define BFL_CONTROLS_TAKEN 512
#define BFL_AT_SURFACE 1024
#define BFL_CLIMBING 2048



integer BFA;                        // Anims bitfield
#define BFA_IDLE 1
#define BFA_ACTIVE 2

#define TIMER_SWIM_CHECK "a"
#define TIMER_WETFEET_FADE "b"
#define TIMER_SPEEDCHECK "c"
#define TIMER_SWIMSTROKE "d"
#define TIMER_FOOTSPLASH "e"
#define TIMER_CLIMB_CD "f"
#define TIMER_COUT_CHECK "g"

integer BF_COMBAT;
#define BFC_RECENT_ATTACK 1
#define BFC_ATTACK_LINEDUP 2


// Checks if the object the script is in is intersecting id
float waterZ(vector userPos, key id, integer inverse)
{
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
        if((s=waterZ(point, llList2Key(airpockets, i), TRUE))>0){
            return s;
        }
    }
    
    //debug((string)s+"\n"+(string)vs+"\n"+(string)llList2Key(airpockets, 0));    
    return submerged;
}

updateAnimstate(){
    integer bf_start;
    integer bf_stop;
	integer sitting = llGetAgentInfo(llGetOwner())&AGENT_SITTING;
	integer forceStop = checkForceStop();
	
    if(BFL&BFL_IN_WATER && !sitting && !forceStop){
		if(~BFA&BFA_IDLE){
			bf_start = bf_start|BFA_IDLE;
			BFA = BFA|BFA_IDLE;
		}
    }else if(BFA&BFA_IDLE){
        bf_stop = bf_stop|BFA_IDLE;
        BFA = BFA&~BFA_IDLE;
    }
        
    if(BFL&BFL_SWIMMING && !sitting && !forceStop){
		if(~BFA&BFA_ACTIVE){
			bf_start = bf_start|BFA_ACTIVE;
			BFA = BFA|BFA_ACTIVE;
		}
    }else if(BFA&BFA_ACTIVE){
        bf_stop = bf_stop|BFA_ACTIVE;
        BFA = BFA&~BFA_ACTIVE;
    }
    
	
	
    if(bf_start != 0){
        if(bf_start&BFA_IDLE)AnimHandler$anim(PrimswimCfg$animIdle,TRUE,0,0);
        if(bf_start&BFA_ACTIVE){
            AnimHandler$anim(PrimswimCfg$animActive, TRUE, 0,0);
        }
    }
    if(bf_stop != 0){
        if(bf_stop&BFA_IDLE)AnimHandler$anim(PrimswimCfg$animIdle, FALSE, 0,0);
        if(bf_stop&BFA_ACTIVE)AnimHandler$anim(PrimswimCfg$animActive, FALSE, 0,0);
    }
}


enterWater(){
    BFL = BFL|BFL_IN_WATER;
    BFL=BFL&~BFL_FEET_SUBMERGED;
    setBuoyancy();
    float vel = llVecMag(llGetVel());
    if(vel>8)llTriggerSound(PrimswimCfg$splashBig, 1.);
    else if(vel>5)llTriggerSound(PrimswimCfg$splashMed, 1.);
    else llTriggerSound(PrimswimCfg$splashSmall, 1);
    
    raiseEvent(PrimswimEvt$onWaterEnter, "");
	debugUncommon("Entered water");


    //dif=llGetVel()*.25;
    prePush=llGetVel()*.1;
    pp=.75;
	
	multiTimer([TIMER_COUT_CHECK, "", 1, TRUE]);
}

exitWater(){
    // Just exited water
    CONTROL = 0;
    multiTimer([TIMER_SWIMSTROKE]);
    llStopMoveToTarget();
    llStopSound();
    BFL=BFL&~BFL_IN_WATER;
    BFL=BFL&~BFL_AT_SURFACE;
    BFL=BFL&~BFL_SWIMMING;
    BFL=BFL&~BFL_FULLY_SUBMERGED;
    
    raiseEvent(PrimswimEvt$onWaterExit, "");
	
	#if PrimswimCfg$USE_PARTICAT==1
    PrimswimAux$particleset(2,llGetPos());
	#endif
    
	triggerRandomSound([PrimswimCfg$soundExit], .5, .75);
    preCallPos = ZERO_VECTOR;
    setBuoyancy();
    // Diving soundspace
    Soundspace$dive(FALSE);
    //sendLocalCom(LINK_ROOT, SCRIPT_SOUNDSPACE, SCRIPT_NO_RET, "", SOUNDSPACE_DIVE, "0");
    toggleCam(FALSE);
    wl_set = "";
	
	debugUncommon("Exited water");
	raiseEvent(PrimswimEvt$atLedge, mkarr([FALSE]));
	multiTimer([TIMER_COUT_CHECK]);
}
#if PrimswimCfg$USE_WINDLIGHT==1
toggleCam(integer submerged){
	if(!isset(wl_set))return;
    if(submerged){
        BFL = BFL|BFL_CAM_UNDER_WATER;
        RLV$windlightPreset(wl_set, TRUE);
    }else{
        BFL = BFL&~BFL_CAM_UNDER_WATER;
        RLV$resetWindlight();
	}
}
#else
	#define toggleCam(input)
#endif

float buoyancy_default = 0;
setBuoyancy(){
    float b = buoyancy_default;
    if(BFL&BFL_IN_WATER)b = .9;
    llSetBuoyancy(b);
}

vector ascale;
integer CONTROL;
list water;
list airpockets;
float deepest;
vector prePush;
vector preCallPos; // What post was last TIMER_SWIM_CHECK
float pp;

timerEvent(string id, string data){
    if(id == TIMER_SWIM_CHECK){
		integer stopped = checkForceStop();
        integer ainfo = llGetAgentInfo(llGetOwner());
        integer i;
        deepest = 0;
		
        if(~BFL&BFL_CLIMBING){
            for(i=0;i<llGetListLength(water) && llGetListLength(water);i++){
                key wID = llList2Key(water,i);
                
                vector gpos = llGetPos();
                float is = pointSubmerged(<gpos.x,gpos.y,gpos.z+ascale.z/2>);
                if(is ==-1 || is == 0)is = waterZ(llGetPos(), wID, FALSE);
                
                if(is>deepest)deepest = is;
                
                // How far below the water the top of your head is
                float depth = is-(gpos.z+ascale.z/2);
                
                // Check for bottom
                list ray = llCastRay(gpos-<0,0,ascale.z/2-.1>,gpos-<0,0,ascale.z>, [RC_REJECT_TYPES,RC_REJECT_AGENTS]);
                vector bottom;
                if(llList2Integer(ray,-1)>0)bottom = llList2Vector(ray,1);
                
                vector pos = llGetCameraPos();
                if(pointSubmerged(pos) != 0 && (~BFL&BFL_AT_SURFACE || ~ainfo&AGENT_MOUSELOOK)){
                    if(~BFL&BFL_CAM_UNDER_WATER){
                        toggleCam(TRUE);
                    }
                }else{
                    if(BFL&BFL_CAM_UNDER_WATER){
                        toggleCam(FALSE);
                    }
                }
                
                integer water_just_entered = FALSE;
                integer atSurface = TRUE;
                if(depth>0){
                    atSurface = FALSE;
                }
				
				
				
                if(is==-1){ // water removed
                    water = llDeleteSubList(water,i,i);
                    i--; 
                }else if(is==0){ 
                    is = waterZ(gpos-<0,0,ascale.z/2>, wID, FALSE);
                    if(is>deepest)deepest=is;
                }else if(depth>SURFACE_DEPTH || atSurface){ // || (is>0 && bottom==ZERO_VECTOR)
                    //if(~BFL&BFL_IN_WATER)llOwnerSay((string)depth+" "+(string)SURFACE_DEPTH+" "+(string)is+" "+(string)bottom);
                    
                    if(i>0){ // INDEX THIS WATER
                        water = llDeleteSubList(water, i, i); water = [wID]+water;i=0;
                    }  
                    vector turb; vector tan;
                    
                    list dta = llGetObjectDetails(wID, [OBJECT_DESC, OBJECT_ROT, OBJECT_POS]);
                    string desc = llList2String(dta,0);
                    
                    vector stream; float cyclone; float ssm; wl_set = "Nacon's nighty fog";
                    list split = llParseString2List(desc, ["$$"], []);
                    list_shift_each(split, val, {
                        list s = llParseString2List(val, ["$"], []);
                        string t = llList2String(s, 0);
                        if(t == Interact$TASK_WATER){
                            stream = (vector)llList2String(s,1);
                            cyclone = llList2Float(s,2);
                            ssm = llList2Float(s,3);
                            if(llGetListLength(s)>4)wl_set = llList2String(s,4);
                        }
                    })
                    
                    
                    if(~ainfo&AGENT_SITTING){
                        if(stream)
                            turb = stream*llList2Rot(dta,1);
                        if(cyclone){
                            vector oPos = llList2Vector(dta,2);
                            rotation oRot = llList2Rot(dta,1);
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
                    if(~BFL&BFL_IN_WATER){ // Just entered water
                        enterWater();
                        #if PrimswimCfg$USE_PARTICAT==1
                        PrimswimAux$particleset(0,(<gpos.x,gpos.y,is-.5>));
                        #endif
						water_just_entered = TRUE;
                    }
                    
                    

				
                    if(CONTROL && !stopped && ~ainfo&AGENT_SITTING){
                        vector fwd; vector left; vector up;
                        if(CONTROL&(CONTROL_FWD|CONTROL_BACK))fwd = llRot2Fwd(llGetCameraRot());
                        if(CONTROL&CONTROL_BACK)fwd=-fwd;
                        if(CONTROL&(CONTROL_LEFT|CONTROL_RIGHT))left = llRot2Left(llGetCameraRot());
                        if(CONTROL&CONTROL_RIGHT)left=-left;
                        if(CONTROL&CONTROL_UP)up = <0,0,1>;
                        else if(CONTROL&CONTROL_DOWN)up = <0,0,-1>;
                        
                        
                        dif=llVecNorm(fwd+left+up);
                        
                        // At surface
                        if(atSurface && dif.z>-.5)dif.z=0;
                        dif = llVecNorm(dif);
                        if(ainfo&AGENT_ALWAYS_RUN)dif*=1.5;
                        // Used for soft slowdown
                        prePush = dif;   
                        pp = 1.;
                    }else if(pp>0){
                        pp-=.1;
                        if(pp>0)dif = prePush*(1-llSin(PI_BY_TWO+pp*PI_BY_TWO))*.5;
                        if(water_just_entered)dif*=4;
                    }
                    
                    
                    if(~ainfo&AGENT_SITTING && !stopped && ((CONTROL&(CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT|CONTROL_DOWN) || (CONTROL&CONTROL_UP&&~BFL&BFL_AT_SURFACE) || llVecMag(<dif.x,dif.y,0>)>.5))){ 
                        if(~BFL&BFL_SWIMMING){
                            BFL=BFL|BFL_SWIMMING;
                            triggerRandomSound([PrimswimCfg$soundStroke], .5, .75);
                            multiTimer([TIMER_SWIMSTROKE, "", 1., TRUE]);
                        }
                    }
                    else if(BFL&BFL_SWIMMING){
                        multiTimer([TIMER_SWIMSTROKE]);
                        BFL=BFL&~BFL_SWIMMING;
                    }
                    
                    float bssm = ssm;
                    if(ssm!=0)bssm = bssm-1+ssm;
                    else bssm = 1;
                    
                    vector SP = gpos;

                    if(preCallPos != ZERO_VECTOR)SP = preCallPos;
                    dif = (dif*.2*bssm)+turb+tan;
                    
                    
                    //SP = preCallPos;
                    
                    if(preCallPos != ZERO_VECTOR && llVecDist(gpos, SP)>2){
                        SP = gpos;
                    }
                    //else debug((string)SP + " "+(string)llVecDist(SP, SP+dif)+" "+(string)(llVecDist(gpos,gpos+dif)+.5));
                    SP+=dif;
                    
    
                    integer SUB = TRUE;
                     if(depth<=0 && !water_just_entered && dif.z>-.1 && atSurface){
                        // Then set to swim at surface level
                        if(bottom.z+ascale.z>depth+SURFACE_DEPTH){
                            SP.z = is-SURFACE_DEPTH-.1-ascale.z*.5;
                            BFL = BFL|BFL_AT_SURFACE;
                        }else{
                            BFL = BFL&~BFL_AT_SURFACE;
                        }
                        SUB = FALSE;
                    }else BFL = BFL&~BFL_AT_SURFACE;
                    
                    
                    preCallPos = SP;
                    
                    float t = .5;
                    if(water_just_entered)t=2;
					if(!stopped)llMoveToTarget(SP, t);
                    
                    
                    // HANDLES DIVING SOUNDS
                    if(SUB){ // Entire body is submerged
                        if(~BFL&BFL_FULLY_SUBMERGED){
                            // Dive
                            BFL=BFL|BFL_FULLY_SUBMERGED;
                            Soundspace$dive(TRUE);
                        }
                    }else if(BFL&BFL_FULLY_SUBMERGED){
                        // Submerge
                        llTriggerSound(PrimswimCfg$soundSubmerge, .5);
                        Soundspace$dive(FALSE);
                        BFL=BFL&~BFL_FULLY_SUBMERGED;
                    }
                    
                    updateAnimstate();
                    multiTimer([id,"", timerSpeed, FALSE]);
					// We are submerged, let's return
                    return;
                }
            }
        }
        
        if(deepest>0||BFL&BFL_IN_WATER){
            if(~BFL&BFL_FEET_SUBMERGED){
                BFL=BFL|BFL_FEET_SUBMERGED;
                BFL=BFL|BFL_HAS_WET_FEET;
                multiTimer([TIMER_FOOTSPLASH, "", FOOTSTEP_SPEED, TRUE]);
                if(deepest>0)multiTimer([TIMER_WETFEET_FADE]);
            }
        }else if(BFL&BFL_FEET_SUBMERGED){
            BFL=BFL&~BFL_FEET_SUBMERGED;
            multiTimer([TIMER_WETFEET_FADE,"", 5, FALSE]);
        }
		
		// Couldn't find
        if(BFL&BFL_IN_WATER && ~BFL&BFL_CLIMBING)exitWater();
        updateAnimstate();
        multiTimer([id,"", timerSpeed, FALSE]);
    }
    
    else if(id == TIMER_WETFEET_FADE){
        BFL=BFL&~BFL_HAS_WET_FEET;
		#if PrimswimCfg$USE_PARTICAT==1
        PrimswimAux$killById("SPT");
		#endif
    }
	
	// See if you can climb out
	else if(id == TIMER_COUT_CHECK){
		// Checks if you're at an edge and can climb out
		if(BFL&BFL_IN_WATER && ~llGetAgentInfo(llGetOwner())&AGENT_SITTING && BFL&BFL_AT_SURFACE && ~BFL&BFL_CLIMBING){
			// Check ray
			vector vrot = llRot2Euler(llGetRootRotation());
			vector fwd = llRot2Fwd(llEuler2Rot(<0,0,vrot.z>));
			
			vector gpos = llGetPos();
			vector uppos = gpos+fwd*.5+<0,0,ascale.z/2>;

			integer rejecttypes = RC_REJECT_AGENTS|RC_REJECT_LAND|RC_REJECT_PHYSICAL;
			list up = llCastRay(uppos+<0,0,1>, uppos-<0,0,.5>, [RC_REJECT_TYPES, rejecttypes]);
			if(llVecDist(llList2Vector(up, 1), uppos+<0,0,1>)>.5 && llList2Integer(up, -1)!=0){
				list fwd = llCastRay(gpos, gpos+llRot2Fwd(llEuler2Rot(<0,0,vrot.z>)), [RC_REJECT_TYPES,rejecttypes, RC_DATA_FLAGS, RC_GET_NORMAL]);
				vector n = llList2Vector(fwd,2);
				n = llVecNorm(<n.x,n.y,0>);
				if(llList2Integer(fwd, -1)>0 && llFabs(n.z)<.2){
					float edge_offset = .1;
					
					
					vector pos = llList2Vector(fwd,1)-n*edge_offset;
					vector u = llList2Vector(up,1);
					pos.z = u.z+ascale.z/2;
					
					if(climb_out_to == ZERO_VECTOR)raiseEvent(PrimswimEvt$atLedge, mkarr([TRUE]));
					climb_out_to = pos;
					climb_out_rot = llRotBetween(<-1,0,0>, n);
					return;
				}
			}
		}
		if(climb_out_to != ZERO_VECTOR)raiseEvent(PrimswimEvt$atLedge, mkarr([FALSE]));
		climb_out_to = ZERO_VECTOR;
	}
    
    else if(id == TIMER_SPEEDCHECK){ // Dynamic timer speed
        multiTimer([TIMER_SPEEDCHECK, "", 4, TRUE]);
        
        if(BFL&BFL_IN_WATER){
            if(~BFL&BFL_WITHIN_20M_OF_WATER){
                BFL=BFL|BFL_WITHIN_20M_OF_WATER;
                timerSpeed = PrimswimCfg$maxSpeed;
                multiTimer([TIMER_SWIM_CHECK,"",timerSpeed, FALSE]);
            }
            return;
        }else{
            vector gpos = llGetPos();
            integer i; 
            for(i=0; i<llGetListLength(water); i++){
                vector pos = llList2Vector(llGetObjectDetails(llList2Key(water,i), [OBJECT_POS]), 0);
                if(llVecDist(pos,gpos)<30){ 
                    if(~BFL&BFL_WITHIN_20M_OF_WATER){
                        timerSpeed = PrimswimCfg$maxSpeed;
                        multiTimer([TIMER_SWIM_CHECK,"",timerSpeed, FALSE]);
                        BFL=BFL|BFL_WITHIN_20M_OF_WATER;
                    }
                    return;
                }
            }
        }
        
        if(BFL&BFL_WITHIN_20M_OF_WATER){
            timerSpeed = PrimswimCfg$minSpeed;
            multiTimer([TIMER_SWIM_CHECK,"", timerSpeed, FALSE]);
        }
        BFL=BFL&~BFL_WITHIN_20M_OF_WATER;
        
        
    }
    
    else if(id == TIMER_CLIMB_CD)BFL = BFL&~BFL_CLIMBING;
    
    else if(id == TIMER_SWIMSTROKE){
        triggerRandomSound([PrimswimCfg$soundStroke], .5, .75);
    }
    
    else if(id == TIMER_FOOTSPLASH){
        if((deepest<=0&&~BFL&BFL_HAS_WET_FEET) || BFL&BFL_IN_WATER){
            multiTimer([TIMER_FOOTSPLASH]); // Remove footsplash
            return;
        }
        
        // Splash sound
        integer ainfo = llGetAgentInfo(llGetOwner());
        vector gpos = llGetPos();
        float depth = deepest-(gpos.z-ascale.z/2);
        if(ainfo&AGENT_WALKING){
            // Trigger splash
            
            if(depth<.1){
                PrimswimAux$particleset(1, (<gpos.x,gpos.y,gpos.z-ascale.z/2>));
                triggerRandomSound(PrimswimCfg$soundFootstepsShallow, .75,1);
                return;
            }
            else if(depth<.4)triggerRandomSound(PrimswimCfg$soundFootstepsMed, .75,1);
            else triggerRandomSound(PrimswimCfg$soundFootstepsDeep, .75,1);
            PrimswimAux$particleset(1, (<gpos.x,gpos.y,deepest>));
        }
    }
}

triggerRandomSound(list sounds, float minVol, float maxVol){
    llTriggerSound(llList2Key(sounds, floor(llFrand(llGetListLength(sounds)))), minVol+llFrand(maxVol-minVol));
}

integer climbOut(){
	if(climb_out_to == ZERO_VECTOR || BFL&BFL_CLIMBING)return FALSE;
	list tasks = [
		SupportcubeBuildTask(Supportcube$tSetPos, [climb_out_to]),
        SupportcubeBuildTask(Supportcube$tSetRot, [climb_out_rot]),
        SupportcubeBuildTask(Supportcube$tForceSit, ([FALSE, TRUE])),
        SupportcubeBuildTask(Supportcube$tRunMethod, ([llGetLinkKey(LINK_ROOT), "jas AnimHandler", AnimHandlerMethod$anim, llList2Json(JSON_ARRAY, ["water_out", TRUE, 0])])),
        SupportcubeBuildTask(Supportcube$tDelay, [2]),
        SupportcubeBuildTask(Supportcube$tForceUnsit, [])
    ];
                
    RLV$cubeTask(tasks);
    BFL = BFL|BFL_CLIMBING;
    multiTimer([TIMER_CLIMB_CD, "", 1, FALSE]);
	return TRUE;
}

onEvt(string script, integer evt, list data){
	#ifdef USE_CUSTOM_EVENTS
	onCustomEvt(script, evt, data);
	#endif
	integer d = llList2Integer(data,0);
    if(script == "#ROOT"){
        if(evt == evt$BUTTON_PRESS){
            CONTROL = CONTROL|d;
            if(d&CONTROL_UP)climbOut();
        }
        else if(evt == evt$BUTTON_RELEASE)CONTROL = CONTROL&~d;
    }
}


default
{
    state_entry()
    {
		llSetText("", ZERO_VECTOR, 0);
        ascale = llGetAgentSize(llGetOwner());
        llStopMoveToTarget();
        setBuoyancy();
        llSensor(PrimswimConst$pnWater, "", PASSIVE|ACTIVE, 90, PI);
        llSleep(1);
        multiTimer([TIMER_SPEEDCHECK, "", .1, TRUE]);
        if(llGetInventoryType("jas PrimswimAux") == INVENTORY_SCRIPT)llResetOtherScript("jas PrimswimAux");
        if(llGetAttached())llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
		memLim(1.5);
    }
        
    sensor(integer total){ 
        integer i;
        for(i=0;i<total;i++){
            key id = llDetectedKey(i);
            if(llListFindList(water, [id])==-1){
                water+=[id];
            }
        }
        llSensorRepeat(PrimswimConst$pnWater, "", PASSIVE|ACTIVE, 90, PI, 5);
    }
    no_sensor(){llSensorRepeat(PrimswimConst$pnWater, "", PASSIVE|ACTIVE, 90, PI, 5);}
    
    #include "xobj_core/_LM.lsl"
    /*
        Included in all these calls:
        METHOD - (int)method
        INDEX - (int)obj_index
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters
        CB_DATA - This is where you set any callback data you have
    */
    if(method$isCallback){return;}
    if(id == ""){
        if(METHOD == PrimswimMethod$airpockets)airpockets = PARAMS;
    }
    // Make sure to check the climbing event to prevent swimming while climbing
        
    #define LM_BOTTOM 
    #include "xobj_core/_LM.lsl"

    timer(){multiTimer([]);}
    
}


