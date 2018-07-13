
#include "xobj_core/libraries/libJasPre.lsl"
#include "xobj_core/classes/jas Supportcube.lsl"
#include "xobj_core/classes/jas RLV.lsl"
#include "xobj_core/classes/jas AnimHandler.lsl"
#include "xobj_core/classes/jas Climb.lsl"
#include "xobj_core/classes/jas Primswim.lsl"
#include "xobj_core/classes/jas PrimswimAux.lsl"


list airpockets; 

key lSplash;
integer ochan;
string miniSplashParts; 


triggerParticleSet(integer PSET, vector pos){
    integer pflags = llGetParcelFlags(pos);
    if(pflags&PARCEL_FLAG_ALLOW_CREATE_OBJECTS||pflags&PARCEL_FLAG_ALLOW_CREATE_GROUP_OBJECTS){
        if(PSET == 0){ // Big Splash
            partiCat(llDumpList2String([
                PC_TASK_TASK, "<"+escapeList([
                    PC_LIFE, .5
                ])+">",
                PC_TASK_PRIMPARAMS, "<"+escapeList([PRIM_TEMP_ON_REZ,TRUE])+">",
                
                PC_TASK_PARTICLES, "<"+escapeList([
                    PSYS_PART_MAX_AGE,.5, // max age
                    PSYS_PART_FLAGS, PSYS_PART_INTERP_COLOR_MASK|PSYS_PART_INTERP_SCALE_MASK|PSYS_PART_FOLLOW_VELOCITY_MASK, // flags, glow etc
                    PSYS_PART_START_COLOR, <.6, .8, 1.>, // startcolor
                    PSYS_PART_END_COLOR, <.6, .8, 1.>, // endcolor
                    PSYS_PART_START_SCALE, <0., 0., 0>, // startsize
                    PSYS_PART_END_SCALE, <3.5, 2.5, 0>, // endsize
                    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE, // pattern
                    PSYS_SRC_BURST_RATE, 0.01, // rate
                    PSYS_SRC_ACCEL, <0,0,-5>,  // push
                    PSYS_SRC_BURST_PART_COUNT, 1, // count
                    PSYS_SRC_BURST_RADIUS, 0.5, // radius
                    PSYS_SRC_BURST_SPEED_MIN, 1.5, // minSpeed
                    PSYS_SRC_BURST_SPEED_MAX, 5., // maxSpeed
                    // PSYS_SRC_TARGET_KEY, NULL_KEY, // target
                    PSYS_SRC_OMEGA, <0., 0., 0.>, // omega
                    PSYS_SRC_MAX_AGE, 0.25, // life
                    PSYS_SRC_TEXTURE, "b1b5356d-9c40-e3a7-70ec-c32066f531f6", // texture
                    PSYS_PART_START_ALPHA, .2, // startAlpha
                    PSYS_PART_END_ALPHA, 0.0, // endAlpha
                    PSYS_SRC_ANGLE_BEGIN, .5, // angleBegin
                    PSYS_SRC_ANGLE_END, .5 // angleend
                ])+">"
            ], ","), pos, ZERO_ROTATION);
        }else if(PSET == 1){
            // Little Splash
            if(llKey2Name(lSplash)==""){
                // Rez little splash
                if(miniSplashParts == ""){
                    miniSplashParts = escapeList([
                        PSYS_PART_MAX_AGE,.4, // max age
                        PSYS_PART_FLAGS, PSYS_PART_INTERP_COLOR_MASK|PSYS_PART_INTERP_SCALE_MASK|PSYS_PART_FOLLOW_VELOCITY_MASK|PSYS_PART_BOUNCE_MASK, // flags, glow etc
                        PSYS_PART_START_COLOR, <.6, .8, 1.>, // startcolor
                        PSYS_PART_END_COLOR, <.6, .8, 1.>, // endcolor
                        PSYS_PART_START_SCALE, <0.2, 0.0, 0>, // startsize
                        PSYS_PART_END_SCALE, <.5, .5, 0>, // endsize
                        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE, // pattern
                        PSYS_SRC_BURST_RATE, 0.01, // rate
                        PSYS_SRC_ACCEL, <0,0,-1>,  // push
                        PSYS_SRC_BURST_PART_COUNT, 10, // count
                        PSYS_SRC_BURST_RADIUS, 0.2, // radius
                        PSYS_SRC_BURST_SPEED_MIN, .0, // minSpeed
                        PSYS_SRC_BURST_SPEED_MAX, .5, // maxSpeed
                        // PSYS_SRC_TARGET_KEY, NULL_KEY, // target
                        PSYS_SRC_OMEGA, <0., 0., 0.>, // omega
                        PSYS_SRC_MAX_AGE, 0.1, // life
                        PSYS_SRC_TEXTURE, "b1b5356d-9c40-e3a7-70ec-c32066f531f6", // texture
                        PSYS_PART_START_ALPHA, .2, // startAlpha
                        PSYS_PART_END_ALPHA, 0.0, // endAlpha
                        PSYS_SRC_ANGLE_BEGIN, PI_BY_TWO-.3, // angleBegin
                        PSYS_SRC_ANGLE_END, PI_BY_TWO-.3 // angleend
                    ]);
                }
                
                partiCat(llDumpList2String([
                    PC_TASK_TASK, "<"+escapeList([
                        PC_REGIONSAY_TO, llGetKey(), "SPLASHPART", ochan,
                        PC_SET_ID, "SPT", FALSE
                    ])+">",
                    PC_TASK_BITFIELD, "<"+escapeList([PC_DIE_ON_NO_OWNER])+">",
                    PC_TASK_PARTICLES, "<"+miniSplashParts+">",
                    PC_TASK_PRIMPARAMS, "<"+escapeList([PRIM_TEMP_ON_REZ, FALSE])+">"
                ], ","), pos, ZERO_ROTATION);
            }
            else{
                // Inject into little splash
                llRegionSayTo(lSplash, integerLizeKey(lSplash,3268), TASK_PARTICAT+","+(string)PC_TASK_TASK+",<"+escapeList([PC_SET_POS, pos])+">,"+(string)PC_TASK_PARTICLES+",<"+miniSplashParts+">");
            }
        }else if(PSET == 2){
            partiCat(llDumpList2String([
                    PC_TASK_TASK, "<"+escapeList([
                        PC_TARGET, llGetOwner(),<0,0,0>,PC_TARGET_SCALE,ZERO_ROTATION,
                        PC_LIFE, .75
                    ])+">",
                    PC_TASK_PRIMPARAMS, "<"+escapeList([PRIM_TEMP_ON_REZ,TRUE])+">",
                    PC_TASK_PARTICLES, "<"+escapeList([
                        PSYS_PART_MAX_AGE,.8, // max age
                        PSYS_PART_FLAGS, PSYS_PART_INTERP_COLOR_MASK|PSYS_PART_INTERP_SCALE_MASK|PSYS_PART_FOLLOW_VELOCITY_MASK, // flags, glow etc
                        PSYS_PART_START_COLOR, <.6, .8, 1.>, // startcolor
                        PSYS_PART_END_COLOR, <.6, .8, 1.>, // endcolor
                        PSYS_PART_START_SCALE, <0.2, 0.0, 0>, // startsize
                        PSYS_PART_END_SCALE, <1.3, 2.3, 0>, // endsize
                        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE, // pattern
                        PSYS_SRC_BURST_RATE, 0.01, // rate
                        PSYS_SRC_ACCEL, <0,0,-5>,  // push
                        PSYS_SRC_BURST_PART_COUNT, 1, // count
                        PSYS_SRC_BURST_RADIUS, 0.5, // radius
                        PSYS_SRC_BURST_SPEED_MIN, .0, // minSpeed
                        PSYS_SRC_BURST_SPEED_MAX, .2, // maxSpeed
                        // PSYS_SRC_TARGET_KEY, NULL_KEY, // target
                        PSYS_SRC_OMEGA, <0., 0., 0.>, // omega
                        PSYS_SRC_MAX_AGE, .75, // life
                        PSYS_SRC_TEXTURE, "b1b5356d-9c40-e3a7-70ec-c32066f531f6", // texture
                        PSYS_PART_START_ALPHA, .1, // startAlpha
                        PSYS_PART_END_ALPHA, 0.0, // endAlpha
                        PSYS_SRC_ANGLE_BEGIN, .5, // angleBegin
                        PSYS_SRC_ANGLE_END, .5 // angleend
                    ])+">"
            ], ","), pos, ZERO_ROTATION);
        }
    }
}
pcKillById(string id){
    llRegionSay(integerLizeKey(llGetOwner(), 13278), id+"0");
}
default
{
    on_rez(integer mew){
        llResetScript();
    }
     
    state_entry()
    {
        pcKillById("SPT");
        ochan = integerLizeKey(llGetOwner(), 1287);
        llListen(ochan, "", "", "");
        llSensorRepeat(PrimswimConst$pnAirpocket, "", ACTIVE|PASSIVE, 90, PI, 5);
        llSetMemoryLimit(llCeil(llGetUsedMemory()*1.5));
    }
    
    listen(integer chan, string name, key id, string message){
        if(llGetOwnerKey(id)!=llGetOwner())return;
        if(message == "SPLASHPART"){
            lSplash=id;
        }
    }
    
    object_rez(key id){ 
        if(llKey2Name(id) == "partiCat"){
            if(llGetListLength(partiCatRezzers)){
                llRegionSayTo(id, integerLizeKey(id,3268), TASK_PARTICAT+","+llList2String(partiCatRezzers,0));
                partiCatRezzers = llDeleteSubList(partiCatRezzers,0,0);
            }else{
                llRegionSayTo(id, integerLizeKey(id,3268), TASK_PARTICAT+","+(string)PC_TASK_TASK+","+(string)PC_DIE);
            }
        }
    }
    
    sensor(integer total){
        list output; integer i; integer recache;
        for(i=0; i<total; i++){
            if(!recache){
                integer pos = llListFindList(airpockets, [llDetectedKey(i)]);
                if(pos==-1)recache = TRUE;
            }
            output+=llDetectedKey(i);
        }
        if(recache){
            airpockets = output;
            
            Primswim$airpockets(airpockets); 
        }
    }
    
    no_sensor(){
        if(airpockets!=[])Primswim$airpockets([]);
        airpockets = [];
    }

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
        
        if(METHOD == PrimswimAuxMethod$particleset){
            triggerParticleSet((integer)method_arg(0), (vector)method_arg(1));
        }else if(METHOD == PrimswimAuxMethod$killById){
            pcKillById(method_arg(0));
        }
        
    }
    #define LM_BOTTOM 
    #include "xobj_core/_LM.lsl"
} 


