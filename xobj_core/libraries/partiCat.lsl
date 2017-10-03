// CONSTANTS //
string TASK_PARTICAT = "PTC";

// Style: [PC_TASK_TASK, <params>, PC_TASK_BITFIELD, <bitfield>, PC_TASK_PRIMPARAMS, <primParams>, PC_TASK_PARTICLES, <particles>]

integer PC_TASK_TASK = 1;
integer PC_TASK_BITFIELD = 2;
integer PC_TASK_PRIMPARAMS = 3;
integer PC_TASK_PARTICLES = 4;


// Bitfield for particles
integer PC_DIE_ON_NO_TARGET = 1; // Die on 
integer PC_DIE_ON_COL = 2; // Die on collision
integer PC_DIE_ON_NO_OWNER = 4; // Die if owner leaves the sim


// Tasks
integer PC_TARGET = 1; // followed by [(key)id,(vec)offset,(int)bitfield, (rot)targetRotOffset], target to follow
	integer PC_TARGET_ROTATE = 1; // Rotate with avatar
	integer PC_TARGET_SCALE = 2; // Scale with avatar
	integer PC_TARGET_FLYTO = 4; // Don't instantly follow, use llMoveTo and llLookAt instead
	integer PC_TARGET_AS_STARTPOS = 8; // Sets startpos to be the target's location upon this being called
	integer PC_TARGET_ROT_Z_ONLY = 16; // Only rotate on Z
integer PC_LIFE = 2; // [(float)life]
integer PC_MAX_HEIGHT = 3; // [(float)height] - Dies if height is greater than max height relative to rez position 
integer PC_MIN_HEIGHT = 4; // [(float)height] - Dies if height is less than min height relative to rez position
integer PC_MAX_DIST = 5; // [(float)dist] - Dies when out of dist
integer PC_REZ_SOUND = 6; // [(key)id, (float)vol, (bool)attached] - Triggers sound on rez
integer PC_DEATH_SOUND = 7; // [(key)id,(float)vol] - Triggers sound before dying
integer PC_LOOP_SOUND = 8; // [(key)id,(float)vol,(float)dur] - Loops a sound for duration, if duration<=0, infinite
integer PC_REPEAT_SOUND = 9; // [(key)id,(float)vol,(bool)attached,(float)interval] - Repeats a sound within intervals
integer PC_COL_SOUND = 10; // [(key)id,(float)vol] - Sets collision sound
integer PC_FLYTO = 11; // [(float)M/S, (float)turningStrenght] - Uses llMoveToTarget and llRotLookAt instead of instantly setting pos, set target and offsets in PC_TARGET
integer PC_REGIONSAY = 12; // [(str)message, (int)chan] - Regionsays message on chan
integer PC_REGIONSAY_TO = 13; // [(key)id, (str)message, (int)chan] - Regionsays to id with message and chan
integer PC_OWNERSAY = 14; // [(string)message] - Ownersays message good for rlv_injections
integer PC_SITTARGET = 15; // [(vector)pos, (rotation)rot] - Sets sittarget
integer PC_SET_VEL = 16; // [(vector)force, (bool)local] - Uses llSetVelocity
integer PC_SET_ANG_VEL = 17; // [(vector)foce, (bool)local] - Uses llSetAngularVelocity
integer PC_APPLY_IMPULSE = 18; // [(vector)force, (bool)local] - Uses llApplyImpulse
integer PC_APPLY_ROT_IMPULSE = 19; // [(vector)force, (bool)local] - Applies rotational impulse
integer PC_DIE = 20; // [] Die instantly
integer PC_SET_ID = 21; // [(string)id, (bool)triggerDeath] Sets an ID and kills off all other with the same id, if triggerDeath is on it triggers deathSounds on teh destroyed cube
integer PC_MIN_DIST = 22; // [(float)dist] Minimum dist before it dies
integer PC_DEATH_CALLBACK = 23; // [(key)recipient, (str)message, (int)chan] - Sends a callback to the sender of the task when dying
integer PC_SET_POS = 24; // [(vector)pos] Sets position
integer PC_SET_ROT = 25; // [(rotation)rot] Sets rotation



// FUNCTIONS //
string escapeList(list input){
    integer i; list op;
    for(i=0;i<llGetListLength(input);i++){
        integer t = llGetListEntryType(input,i);
        string v = llList2String(input,i);
        if(t == TYPE_STRING)v="<"+v+">";
        else if(t == TYPE_FLOAT)v = roundTo((float)v,2);
        else if(t == TYPE_VECTOR){
            vector ve = llList2Vector(input, i);
            v = "<"+roundTo(ve.x,2)+","+roundTo(ve.y,2)+","+roundTo(ve.z,2)+">";
        }else if(t == TYPE_ROTATION){
            rotation ve = llList2Rot(input, i);
            v = "<"+roundTo(ve.x,2)+","+roundTo(ve.y,2)+","+roundTo(ve.z,2)+","+roundTo(ve.s,2)+">";
        }
        op+=[(string)t+v];
    }
    return llDumpList2String(op,",");
}

list unEscapeList(string input){
    list op = llCSV2List(input);
    integer i;
    for(i=0;i<llGetListLength(op);i++){
        string v = llList2String(op,i);
        integer t = (integer)llGetSubString(v,0,0);
        v = llGetSubString(v,1,-1);
        if(t == TYPE_INTEGER)op = llListReplaceList(op, [(integer)v], i, i);
        else if(t == TYPE_FLOAT)op = llListReplaceList(op, [(float)v], i, i);
        else if(t == TYPE_KEY)op = llListReplaceList(op, [(key)v], i, i);
        else if(t == TYPE_VECTOR)op = llListReplaceList(op, [(vector)v], i, i);
        else if(t == TYPE_ROTATION)op = llListReplaceList(op, [(rotation)v], i, i);
        else op = llListReplaceList(op, [llGetSubString(v,1,-2)], i, i); // String
    }
    return op;
}

list partiCatRezzers;
partiCat(string task, vector pos, rotation rot){
    if(task!="")partiCatRezzers+=[task];
    if(llGetListLength(partiCatRezzers)){
        llRezAtRoot("partiCat", pos, ZERO_VECTOR, rot, 1);
    }
}

/*
EX:

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

*/

