#ifndef USE_SHARED
#define USE_SHARED ["st RLV"]
#endif 
#ifndef USE_EVENTS
#define USE_EVENTS
#endif
#include "xobj_core/_CLASS_STATIC.lsl"
#include "xobj_core/classes/jas Supportcube.lsl"
#include "xobj_core/classes/jas RLV.lsl"
#include "xobj_core/classes/jas AnimHandler.lsl"
#include "xobj_core/classes/jas Climb.lsl"


init(){
    llSetMemoryLimit(llCeil(llGetUsedMemory()*1.5));
}
float CLIMBSPEED = .65;  // M/S


integer BFL;
#define BFL_MOVING 1
#define BFL_DISMOUNTING 2
#define BFL_CLIMBING_ANIM 4
#define BF_CLIMB_INI 8
#define BFL_DIR_UP 16
#define BFL_CLIMBING 32

#define TIMER_MOVE "a"
#define TIMER_DISMOUNTING "b"
#define TIMER_INI "c"

key CUBE;
key ladder;
vector ladder_root_pos;
rotation ladder_root_rot;
list nodes;

string anim_active = "";
string anim_active_down = "";
string anim_passive = "";
string anim_dismount_top = "";
string anim_dismount_bottom = "";
string anim_active_cur;

integer onNode;
rotation rot;
float perc;



setCubePos(vector pos){
    if(CUBE == "" || llKey2Name(CUBE) == ""){
        CUBE = db2$get("st RLV", [RLVShared$supportcube]);
    }
    //rot*ladder_root_rot'
    llRegionSayTo(CUBE, SupportcubeCfg$listenOverride, llList2CSV([SupportcubeOverride$tSetPosAndRot, pos, rot*ladder_root_rot]));
}

dismount(integer atoffset){
    if(BFL&BFL_DISMOUNTING)return;
    BFL = BFL|BFL_DISMOUNTING;
    multiTimer([TIMER_MOVE]);
    BFL = BFL&~BF_CLIMB_INI;
    BFL = BFL&~BFL_CLIMBING_ANIM;
    BFL = BFL&~BFL_CLIMBING;
    anim_active_cur = "";
    

    
    if(anim_active != ""){
        AnimHandler$anim(anim_active,FALSE,0);
    }
    if(anim_active_down != ""){
        AnimHandler$anim(anim_active_down,FALSE,0);
    }
    
    string anm = anim_dismount_bottom;
    if(atoffset){
        vector gpos = llGetPos();
        vector offset = offset2global(llList2Vector(nodes,0));
        if(llVecDist(gpos, offset2global(llList2Vector(nodes,-1)))<llVecDist(gpos, offset)){
            offset = offset2global(llList2Vector(nodes,-1));
            anm = anim_dismount_top;
        }
        if(isset(anm)){
            AnimHandler$anim(anm,TRUE,0);
        }
        setCubePos(offset);
    }
    
    float to = .05;
    if(isset(anm))to = 1;
    if(anim_passive != ""){
        AnimHandler$anim(anim_passive, FALSE, 0);
    }
    
    multiTimer([TIMER_DISMOUNTING, "", to, FALSE]);
    raiseEvent(ClimbEvt$end, (string)ladder);
}

mount(){
    findNearestNode();
    // Position cube at node and start
    vector p = offset2global(llList2Vector(nodes, onNode));
	
	debugUncommon("Mounting");
    if(llKey2Name(CUBE) == ""){
        debugUncommon("Spawning cube");
		RLV$cubeTask(([
            SupportcubeBuildTask(Supportcube$tSetPos, [p]),
            SupportcubeBuildTask(Supportcube$tSetRot, [rot*ladder_root_rot])
        ]));
    }
    setCubePos(p);
	
	
    RLV$cubeTask(([
        SupportcubeBuildTask(Supportcube$tForceSit, [])
    ]));

// CHECK THIS
    /*
    sendLocalCom(LINK_ROOT, SCRIPT_RLV, SCRIPT_NO_RET, "", RLV_SIT, llList2Json(JSON_OBJECT, [
        "u", "c"
    ]));
    */
    //sendLocalCom(LINK_THIS, SCRIPT_PRIMSWIM, SCRIPT_NO_RET, "", PRIMSWIM_CLIMB, "1");
    multiTimer([TIMER_MOVE, "", 1.5, FALSE]);
    
    if(isset(anim_passive))AnimHandler$anim(anim_passive,TRUE,0);
    multiTimer([TIMER_INI, 0, 3, FALSE]);
    BFL = BFL|BF_CLIMB_INI;
    BFL = BFL|BFL_CLIMBING;
    raiseEvent(ClimbEvt$start, (string)ladder);
}

vector offset2global(vector offset){
    return ladder_root_pos+offset*ladder_root_rot;
}

timerEvent(string id, string data){
    if(id == TIMER_MOVE && ~BFL&BFL_DISMOUNTING){
        multiTimer([id, "", .1, FALSE]);
        if(~llGetAgentInfo(llGetOwner())&AGENT_SITTING){
            if(BFL&BF_CLIMB_INI)return;
            dismount(FALSE);
            return;
        }else{
            if(BFL&BFL_MOVING){
                vector nodea = offset2global(llList2Vector(nodes,1)); 
                vector nodeb = offset2global(llList2Vector(nodes,2));
                float maxdist = llVecDist(nodea, nodeb);
                float spd = CLIMBSPEED/maxdist*.1;
                
                if(BFL&BFL_DIR_UP)perc-=spd;
                else perc+=spd;
                    
                if(isset(anim_active) && ~BFL&BFL_CLIMBING_ANIM){
                    BFL = BFL|BFL_CLIMBING_ANIM;
                    string a = anim_active;
                    
                    if(~BFL&BFL_DIR_UP)a = anim_active_down;
                    if(a != anim_active_cur)AnimHandler$anim(a,TRUE,0);
                    anim_active_cur = a;
                }
                

                if(perc>1 || perc<0){
                    dismount(TRUE);
                    multiTimer([id]);
                    return;
                }
                else{
                    vector point = pointBetween(nodea, nodeb, maxdist*perc);
                    setCubePos(point);
                }
            }else{
                BFL = BFL&~BFL_CLIMBING_ANIM;
                if(anim_active_cur != ""){
                    AnimHandler$anim(anim_active_cur,FALSE,0);
                    anim_active_cur = "";
                }
            }
        }
        
        
    }else if(id == TIMER_DISMOUNTING){
        if(llGetAgentInfo(llGetOwner())&AGENT_SITTING){
            RLV$unsit(0);
        }

        // Raise climb unsit event
        BFL=BFL&~BFL_DISMOUNTING;
    }else if(id == TIMER_INI){
        BFL = BFL&~BF_CLIMB_INI;
    }
}

findNearestNode(){
    list l = llList2List(nodes, 1, -2);
    integer nn; float dist;
    
    integer i;
    for(i=0; i<llGetListLength(l); i++){
        float d = llVecDist(llGetPos(), offset2global(llList2Vector(l,i)));
        if(dist == 0 || d<dist){
            nn = i; dist = d;
        }
    }
    perc = (float)nn/(llGetListLength(l)-1);
    onNode = nn+1;
}

onEvt(string script, integer evt, string data){
    if(script == "st RLV" && evt == RLVevt$supportcubeSpawn){
        CUBE = data;
    }
    else if(script == "#ROOT" && BFL&BFL_CLIMBING){
        integer n = (integer)data;
        integer up = CONTROL_FWD|CONTROL_RIGHT|CONTROL_UP;
        integer dn = CONTROL_BACK|CONTROL_LEFT|CONTROL_DOWN;
            
        if(evt == evt$BUTTON_RELEASE){
            if(n&(up|dn)){
                BFL = BFL&~BFL_MOVING;
                BFL = BFL&~BFL_DIR_UP;
            }
        }else if(evt == evt$BUTTON_PRESS){
            

            if(n&(up|dn)){
                BFL = BFL|BFL_MOVING;
                if(n&up)BFL = BFL&~BFL_DIR_UP;
                else BFL = BFL|BFL_DIR_UP;
            }
            
            return;
        }
    }
    
}

default
{
    on_rez(integer mew){
        llResetScript();
    }
     
    state_entry()
    {
        dismount(FALSE);
        init();
    }
    
    timer(){
        multiTimer([]);
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
    
// REPLACE WITH EVENTS
    /*
    if(nr == THIS && id == "c"){
        // Controls
        
    }
    */
        

    if(id == ""){
        if(METHOD == ClimbMethod$start){
            if(BFL&BFL_CLIMBING){
                dismount(FALSE);
				debug("Dismount");
                return;
            }

			debugUncommon("Climb start: "+PARAMS);
            ladder = tr(method_arg(0));
            rot = (rotation)method_arg(1);
            anim_passive = tr(method_arg(2));
            anim_active = tr(method_arg(3));
            anim_active_down = tr(method_arg(4));
            if(anim_active_down == "")anim_active_down = anim_active;
            anim_dismount_top = tr(method_arg(5));
            anim_dismount_bottom = tr(method_arg(6));
            nodes = llCSV2List(tr(method_arg(7)));
            CLIMBSPEED = (float)tr(method_arg(8));

            if(CLIMBSPEED<=0)CLIMBSPEED = ClimbCfg$defaultSpeed;
            list dta = llGetObjectDetails(ladder, [OBJECT_POS, OBJECT_ROT]);
            ladder_root_pos = llList2Vector(dta,0);
            ladder_root_rot = llList2Rot(dta, 1);
            integer i;
            if(llGetListLength(nodes) == 2)nodes = llList2List(nodes,0,0)+nodes+llList2List(nodes,-1,-1);
            for(i=0; i<llGetListLength(nodes); i++)nodes = llListReplaceList(nodes, [(vector)llList2String(nodes,i)], i, i);
            
            if(llGetListLength(nodes) == 4)mount();
			#ifdef DEBUG
			else debugRare("Invalid node length: "+(string)llGetListLength(nodes));
			#endif
        }
    }
        
    #define LM_BOTTOM 
    #include "xobj_core/_LM.lsl"
} 

