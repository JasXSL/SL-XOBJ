#include "xobj_core/_CLASS_STATIC.lsl"
#include "xobj_core/classes/jas SoundspaceAux.lsl"
#include "xobj_core/classes/jas Interact.lsl"
#include "xobj_core/classes/jas Soundspace.lsl"


integer BFL;
#define BFL_IN_WATER 1
 
list soundspaces;
string currentsound; 
float currentsoundvol = .5;

float groundsoundvol = .5;
string groundsound;  

key overridesound;
float overridesoundvol = .5;

#define TIMER_GROUNDSPACECHECK "a"
 
timerEvent(string id, string data){
    if(id == TIMER_GROUNDSPACECHECK){
        // Raycast
        list ray = llCastRay(llGetPos(), llGetPos()-<0,0,10>, [RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]);

        if(llList2Integer(ray,-1)==1){
            string desc = (string)llGetObjectDetails(llList2Key(ray,0), [OBJECT_DESC]);
            list split = llParseString2List(desc, ["$$"], []);
            
            
            getDescTaskData(desc, dta, Interact$TASK_SOUNDSPACE);
            string ssp = llList2String(dta,0);  
            float v = llList2Float(dta,1);
            if(dta!=[] && isset(ssp)){
                if(groundsound != ssp || v != groundsoundvol){ 
                    groundsoundvol = v;
                    groundsound = ssp;
                    if(currentsound == "")setSoundspace();
                }
            } 
        }
    }
}
integer recent = 1;   
setSoundspace(){
    string cs = currentsound;
    float csv = currentsoundvol;
	if(overridesound){
		cs = overridesound;
		csv = overridesoundvol;
	}
    else if(BFL&BFL_IN_WATER){
        cs = SP_UNDERWATER;
        csv = .5;
    } 
    else if(cs == ""){
        csv = groundsoundvol;
        cs = groundsound;
    }
    if(cs == "" || cs == "NULL"){
        clearSoundspace();
        return;
    }
	if(cs == currentsound  && csv == currentsoundvol)return;
	
	
	
	key sound = cs;
	integer i;
    for(i=0; i<llGetListLength(soundspaces); i+=2){
        if(llList2String(soundspaces,i) == cs)sound = llList2String(soundspaces,i+1);
	}
	
	runMethod((string)LINK_SET, "jas SoundspaceAux", SoundspaceAuxMethod$stop, [recent], TNN);
	recent++;
    if(recent>2)recent = 1;
    runMethod((string)LINK_SET, "jas SoundspaceAux", SoundspaceAuxMethod$start, [recent, sound, csv], TNN);
}
clearSoundspace(){
    currentsound = "";
    groundsound = "";
    runMethod((string)LINK_SET, "jas SoundspaceAux", SoundspaceAuxMethod$stop, [-1], TNN);
 
}


integer isInside(key id)
{
        vector vPos = llGetPos();
        vector userPos = vPos;
        list d = llGetObjectDetails(id, [OBJECT_POS, OBJECT_ROT]);
        vector gpos = llList2Vector(d,0);
        if(gpos == ZERO_VECTOR)return FALSE;
        rotation grot = llList2Rot(d,1);
        list bb = llGetBoundingBox(id);
        vector v1 = llList2Vector(bb,0);
        vector v2 = llList2Vector(bb,1);
        vPos = (vPos-gpos) / grot;
        
        //vPos = (vPos - gpos) / grot;
        float fTemp;
        if (v1.x > v2.x){fTemp = v2.x;v2.x = v1.x;v1.x = fTemp;}
        if (v1.y > v2.y){fTemp = v2.y;v2.y = v1.y;v1.y = fTemp;}
        if (v1.z > v2.z){fTemp = v2.z;v2.z = v1.z;v1.z = fTemp;}

        if (vPos.x < v1.x || vPos.y < v1.y || vPos.z < v1.z || vPos.x > v2.x || vPos.y > v2.y || vPos.z > v2.z)return 0;
        if(userPos.z-vPos.z+v2.z > 0)return TRUE;
        return FALSE;
}


default
{
    state_entry() 
    {
        soundspaces = SP_DATA;
        clearSoundspace(); 
        llSetMemoryLimit(llCeil(llGetUsedMemory()*1.5));
        multiTimer([TIMER_GROUNDSPACECHECK, "", 1, TRUE]);
        llSetStatus(STATUS_DIE_AT_EDGE, TRUE);
    }

    timer(){
        multiTimer([]);
    }
    
    #include "xobj_core/_LM.lsl" 
    /*
        Included in all these calls:  
        METHOD - (int)method 
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task
    */
    if(method$isCallback){
        return;
    }
		
	if(METHOD == SoundspaceMethod$override){
		key s = (key)method_arg(0);
		if(s){
			overridesound = s;
			overridesoundvol = (float)method_arg(1);
		}else{
			overridesound = "";
		}
		setSoundspace();
	}
		
    if(id != "")return;
    if(METHOD == SoundspaceMethod$dive){
        if((integer)method_arg(0) && ~BFL&BFL_IN_WATER){
            BFL = BFL|BFL_IN_WATER;
            setSoundspace();
        }
        else if(!(integer)method_arg(0)&& BFL&BFL_IN_WATER){
            BFL = BFL&~BFL_IN_WATER;
            setSoundspace();
        }
    }
    #define LM_BOTTOM   
    #include "xobj_core/_LM.lsl" 
    
}


