#include "xobj_core/libraries/libjas.lsl"
#include "xobj_core/libraries/partiCat.lsl"
key target;
vector targetOffset;
rotation targetRotOffset;
integer targetBF;
float turnStrength; 
float MS;


float maxHeight;
float MINHEIGHT;
float maxDist;
float minDist;

list deathSound = [];
list repeatSound = [];

list deathCallback = [];

vector startpos;
integer bitfield;

multiTimerEvent(string id){
    if(id == "F"){
        
        
        // FOllow
        list data = llGetObjectDetails(target, [OBJECT_POS, OBJECT_ROT]);
        vector tscale = llGetAgentSize(target);
        vector gtp = llList2Vector(data, 0);
        if(gtp == ZERO_VECTOR && bitfield&PC_DIE_ON_NO_TARGET){
            die();return;
        }
        vector add = targetOffset;
        if(targetBF&PC_TARGET_ROTATE){
            if(~targetBF&PC_TARGET_ROT_Z_ONLY)add*=llList2Rot(data,1);
            else{
                vector vrot = llRot2Euler(llList2Rot(data,1));
                vrot=<0,0,vrot.z>;
                add*=llEuler2Rot(vrot);
            }
            if(turnStrength<=0)turnStrength=.1;
            llRotLookAt(llList2Rot(data,1)*targetRotOffset, turnStrength,1);
        }
        if(targetBF&PC_TARGET_SCALE)add*=(tscale.z/2);
        
        
        if(~targetBF&PC_TARGET_FLYTO){
            llSetRegionPos(gtp+add);
        }else{
            // Move2
            float t = llVecDist(llGetRootPosition(), gtp+add);
            llMoveToTarget(gtp+add,t/MS);
        }

        
        if(targetBF&PC_TARGET_AS_STARTPOS)startpos = gtp+add;
    }
    else if(id == "HC"){
        // Height check
        if(startpos==ZERO_VECTOR)return;
        vector gpos = llGetRootPosition();
        float dist  = llVecDist(startpos,gpos);
        if((dist>maxDist && maxDist!=0) || (minDist!=0 && dist<minDist) || (gpos.z>startpos.z+maxHeight && maxHeight!=0) || (gpos.z<startpos.z-MINHEIGHT && MINHEIGHT!=0)){
            die();
        }
    }
    else if(id == "STP")llStopSound();
    else if(id == "DIE")die();
    else if(id == "RS"){
        if(repeatSound!=[]){
            string s = llList2String(repeatSound, 0);
            float v = llList2Float(repeatSound,1);
            if(llList2Integer(repeatSound,2))llPlaySound(s,v);
            else llTriggerSound(s,v);
        }
    }
    else if(id == "OC"){
        if(llGetAgentSize(llGetOwner())==ZERO_VECTOR)die();
    }
}


die(){
    while(llGetListLength(deathSound)){
        llTriggerSound(llList2String(deathSound,0), llList2Float(deathSound,1));
        deathSound = llDeleteSubList(deathSound,0,1);
    }
    while(llGetListLength(deathCallback)){
        llRegionSayTo(llList2String(deathCallback,0), llList2Integer(deathCallback,2), llList2String(deathCallback,1));
        deathCallback = llDeleteSubList(deathCallback, 0, 2);
    }
    llDie();
}

string MY_ID;
integer CHAN_GLOBAL; 
default
{
    on_rez(integer mew){
        llResetScript();
    }
    
    state_entry()
    { 
        llListen(integerLizeKey(llGetKey(),3268), "", "", "");
        startpos = llGetRootPosition();
        CHAN_GLOBAL = integerLizeKey(llGetOwner(), 13278);
        llSetStatus(STATUS_PHYSICS, FALSE);
        llSetStatus(STATUS_DIE_AT_EDGE|STATUS_PHANTOM, TRUE);
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEMP_ON_REZ, TRUE]);
    }
    
    collision_start(integer total){
        if(bitfield&PC_DIE_ON_COL)die();
    }
     
    land_collision_start(vector pos){
        if(bitfield&PC_DIE_ON_COL)die();
    }
    
    timer(){
        timersRefresh();
    }
    
    listen(integer chan, string name, key id, string message){
        if(llGetOwnerKey(id)!=llGetOwner())return;
        if(chan == CHAN_GLOBAL){
            if(llGetSubString(message, 0, llStringLength(MY_ID)-1) == MY_ID){
                if((integer)llGetSubString(message, -1,-1))die();
                else llDie();
            }
            return;
        }
        
        
        list temp = llCSV2List(message);
        if(llList2String(temp,0)!=TASK_PARTICAT)return;
        temp = llDeleteSubList(temp,0,0);
        while(llGetListLength(temp)){
            integer t = llList2Integer(temp,0);
            list tasks = unEscapeList(llGetSubString(llList2String(temp,1), 1, -2));
            temp = llDeleteSubList(temp,0,1);

            if(t == PC_TASK_BITFIELD){
                bitfield = llList2Integer(tasks,0);
                if(bitfield&PC_DIE_ON_NO_OWNER)setMultiTimer("OC", 5, TRUE);
                else removeMultiTimer("OC");
            }
            else if(t == PC_TASK_PARTICLES){
                llParticleSystem(tasks);
            }
            else if(t == PC_TASK_PRIMPARAMS){
                llSetLinkPrimitiveParamsFast(LINK_THIS, tasks);
            }
            else if(t == PC_TASK_TASK){
                while(llGetListLength(tasks)){
                    integer t = llList2Integer(tasks,0);
                    tasks = llDeleteSubList(tasks,0,0);

                    // DONE
                    if(t == PC_TARGET){
                        target = llList2String(tasks,0);
                        targetOffset = (vector)llList2String(tasks,1);
                        targetBF = llList2Integer(tasks,2);
                        targetRotOffset = (rotation)llList2String(tasks,3);
                        tasks = llDeleteSubList(tasks,0,3);
                        if(targetBF&PC_TARGET_AS_STARTPOS)startpos = ZERO_VECTOR;
                        setMultiTimer("F",.1,TRUE);
                    }
                    
                    // DONE
                    else if(t == PC_LIFE){
                        setMultiTimer("DIE", llList2Float(tasks,0), FALSE);
                        tasks = llDeleteSubList(tasks,0,0);
                    }
                    
                    // DONE
                    else if(t == PC_MAX_HEIGHT){
                        maxHeight = llList2Float(tasks,0);
                        tasks = llDeleteSubList(tasks,0,0);
                        setMultiTimer("HC",.2,TRUE);
                    }
                    
                    // DONE
                    else if(t == PC_MIN_HEIGHT){
                        MINHEIGHT = llList2Float(tasks,0);
                        tasks = llDeleteSubList(tasks,0,0);
                        setMultiTimer("HC",.2,TRUE);
                    }
                    
                    // DONE
                    else if(t == PC_MAX_DIST){
                        maxDist = llList2Float(tasks,0);
                        tasks = llDeleteSubList(tasks,0,0);
                    }
                    
                    // DONE
                    else if(t == PC_REZ_SOUND){
                        string s = llList2String(tasks,0);
                        float v = llList2Float(tasks,1);
                        if(llList2Integer(tasks,2))llTriggerSound(s,v);
                        else llPlaySound(s,v);
                        tasks = llDeleteSubList(tasks,0,2);
                    }
                    
                    // DONE
                    else if(t == PC_DEATH_SOUND){
                        deathSound += [llList2String(tasks,0),llList2Float(tasks,1)];
                        tasks = llDeleteSubList(tasks,0,1);
                    }
                    
                    // DONE
                    else if(t == PC_LOOP_SOUND){
                        llLoopSound(llList2String(tasks,0),llList2Float(tasks,1));
                        if(llList2Float(tasks,2)>0)setMultiTimer("STP", llList2Float(tasks,2), FALSE);
                        tasks = llDeleteSubList(tasks,0,2);
                    }
                    
                    // DONE
                    else if(t == PC_REPEAT_SOUND){ 
                        repeatSound = [llList2String(tasks,0),llList2Float(tasks,1),llList2Integer(tasks,2)];
                        setMultiTimer("RS", llList2Float(tasks,3), TRUE);
                        tasks = llDeleteSubList(tasks,0,3);
                    }
                    
                    // DONE
                    else if(t == PC_FLYTO){
                        MS = llList2Float(tasks,0);
                        turnStrength = llList2Float(tasks,1);
                        tasks = llDeleteSubList(tasks,0,1);
                    }
                    
                    // DONE
                    else if(t == PC_REGIONSAY){ 
                        llRegionSay(llList2Integer(tasks,1), llList2String(tasks,0));
                        tasks = llDeleteSubList(tasks,0,1);
                    }
                    
                    // DONE
                    else if(t == PC_REGIONSAY_TO){ 
                        llRegionSayTo(llList2String(tasks,0),llList2Integer(tasks,2), llList2String(tasks,1));
                        tasks = llDeleteSubList(tasks,0,2);
                    }
                    
                    // DONE
                    else if(t == PC_OWNERSAY){
                        llOwnerSay(llList2String(tasks,0));
                        tasks = llDeleteSubList(tasks,0,0);
                    }
                    
                    // DONE
                    else if(t == PC_SITTARGET){
                        llSitTarget((vector)llList2String(tasks,0), (rotation)llList2String(tasks,1));
                        tasks = llDeleteSubList(tasks,0,1);
                    }
                    
                    // DONE
                    else if(t == PC_SET_VEL){
                        llSetVelocity((vector)llList2String(tasks,0), llList2Integer(tasks,1));
                        tasks = llDeleteSubList(tasks,0,1);
                    }
                    
                    // DONE
                    else if(t == PC_SET_ANG_VEL){
                        llSetAngularVelocity((vector)llList2String(tasks,0), llList2Integer(tasks,1));
                        tasks = llDeleteSubList(tasks,0,1);
                    }
                    
                    // DONE
                    else if(t == PC_APPLY_IMPULSE){
                        llApplyImpulse((vector)llList2String(tasks,0), llList2Integer(tasks,1));
                        tasks = llDeleteSubList(tasks,0,1);
                    }
                    
                    // DONE
                    else if(t == PC_APPLY_ROT_IMPULSE){
                        llApplyRotationalImpulse((vector)llList2String(tasks,0), llList2Integer(tasks,1));
                        tasks = llDeleteSubList(tasks,0,1);
                    }
                    
                    
                    else if(t == PC_SET_ID){
                        if(MY_ID=="")llListen(CHAN_GLOBAL, "", "", "");
                        MY_ID = llList2String(tasks,0);
                        llRegionSay(CHAN_GLOBAL, MY_ID+llList2String(tasks,1));
                        tasks = llDeleteSubList(tasks,0,1);
                    }

                    else if(t == PC_DIE)die();
                    
                    else if(t == PC_MIN_DIST){
                        minDist = llList2Float(tasks,0);
                        tasks = llDeleteSubList(tasks,0,0);
                    }
                    
                    else if(t == PC_DEATH_CALLBACK){
                        deathCallback += [llList2String(tasks,0), llList2String(tasks,1), llList2Integer(tasks,2)];
                        tasks = llDeleteSubList(tasks,0,2);
                    }
                    
                    else if(t == PC_SET_POS){
                        llSetRegionPos(llList2Vector(tasks,0));
                        tasks = llDeleteSubList(tasks,0,0);
                    }
                    else if(t == PC_SET_ROT){
                        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_ROTATION, llList2Rot(tasks,0)]);
                        tasks = llDeleteSubList(tasks,0,0);
                    }
                }
                
                if(maxDist!=0||MINHEIGHT!=0||maxHeight!=0||minDist!=0)setMultiTimer("HC",.2,TRUE);
                else removeMultiTimer("HC");
            }
        }
        
    }
    
}

