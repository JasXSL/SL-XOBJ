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
#define BFL_DIR_UP 0x10
#define BFL_CLIMBING 0x20
// Prevents messages to SC more than every 0.4 sec
#define BFL_LAST_UPDATE 0x40
#define BFL_GRACE_PERIOD 0x80		// Grace period for dismount

// Used in timer_move
integer BFL_CACHE;

// Frame ticker
#define TIMER_MOVE "a"
// Dismount complete
#define TIMER_DISMOUNTING "b"
// Mount complete
#define TIMER_INI "c"
// Can send a new translate request
#define TIMER_CD "d"
// Blocks dismount through E
#define TIMER_GRACE "e"

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
string onStart;
string onEnd;

integer onNode;
rotation rot;
float perc;



#define setCubePos(pos) llRegionSayTo(CUBE, SupportcubeCfg$listenOverride, llList2CSV([SupportcubeOverride$tSetPosAndRot, pos, rot*ladder_root_rot]))

translateCubePos(vector pos){
	vector p = pos-prPos(CUBE);
	rotation rot = rot*ladder_root_rot/prRot(CUBE);
	llRegionSayTo(CUBE, SupportcubeCfg$listenOverride, llList2CSV([SupportcubeOverride$tKFM, p, rot, 0.5]));
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
        AnimHandler$anim(anim_active,FALSE,0,0);
    }
    if(anim_active_down != ""){
        AnimHandler$anim(anim_active_down,FALSE,0,0);
    }
    
    string anm = anim_dismount_bottom;
    if(atoffset){
        vector gpos = llGetPos();
        vector offset = offset2global(llList2Vector(nodes,0));
		
        if(~BFL&BFL_DIR_UP){
            offset = offset2global(llList2Vector(nodes,-1));
            anm = anim_dismount_top;
        }
        if(isset(anm)){
            AnimHandler$anim(anm,TRUE,0,0);
        }
        setCubePos(offset);
    }
    
    float to = .1;
    if(isset(anm))to = 1;
    if(anim_passive != ""){
        AnimHandler$anim(anim_passive, FALSE, 0,0);
    }
    
    multiTimer([TIMER_DISMOUNTING, "", to, FALSE]);
    raiseEvent(ClimbEvt$end, mkarr(([(string)ladder, onEnd])));
}

mount(){
	BFL_CACHE = 0;
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
	
	// Wait a little while to initiate
    multiTimer([TIMER_MOVE, "", 1, FALSE]);
    
    if(isset(anim_passive))AnimHandler$anim(anim_passive,TRUE,0,0);
    multiTimer([TIMER_INI, 0, 3, FALSE]);
    BFL = BFL|BF_CLIMB_INI;
    BFL = BFL|BFL_CLIMBING;
    raiseEvent(ClimbEvt$start, mkarr(([(string)ladder, onStart])));
	
	BFL = BFL|BFL_GRACE_PERIOD;
	multiTimer([TIMER_GRACE, "", 1.5, FALSE]);
}

vector offset2global(vector offset){
    return ladder_root_pos+offset*ladder_root_rot;
}

timerEvent(string id, string data){
    if(id == TIMER_MOVE && ~BFL&BFL_DISMOUNTING){
        multiTimer([id, "", .1, FALSE]);
        
		// Agent has unsat
		if(~llGetAgentInfo(llGetOwner())&AGENT_SITTING){
            if(BFL&BF_CLIMB_INI)return;
            dismount(FALSE);
            return;
        }
		
		
		// This is used to limit updates to 0.4 sec unless moving has just started or ended
		

		if(BFL&BFL_LAST_UPDATE && (BFL&BFL_MOVING) == (BFL_CACHE&BFL_MOVING))
			return;

		BFL = BFL|BFL_LAST_UPDATE;
		multiTimer([TIMER_CD, "", 0.4, FALSE]);
		
		
        
		if(BFL&BFL_MOVING){
            vector nodea = offset2global(llList2Vector(nodes,1)); 
            vector nodeb = offset2global(llList2Vector(nodes,2));
            float maxdist = llVecDist(nodea, nodeb);
            float spd = CLIMBSPEED/maxdist*.5;
                
            if(BFL&BFL_DIR_UP)
				perc-=spd;
            else
				perc+=spd;
                    
            if(isset(anim_active) && ~BFL&BFL_CLIMBING_ANIM){
                BFL = BFL|BFL_CLIMBING_ANIM;
                string a = anim_active;
                    
                if(~BFL&BFL_DIR_UP)a = anim_active_down;
                if(a != anim_active_cur)AnimHandler$anim(a,TRUE,0,0);
                anim_active_cur = a;
            }
                
				
			// Reached top or bottom
            if(perc>1 || perc<0){
                dismount(TRUE);
                multiTimer([id]);
                return;
            }
            
			// Move
            vector point = vecBetween(nodea, nodeb, maxdist*perc);
            translateCubePos(point);
			
        }
		
		else{
		
            BFL = BFL&~BFL_CLIMBING_ANIM;
            if(anim_active_cur != ""){
                AnimHandler$anim(anim_active_cur,FALSE,0,0);
                anim_active_cur = "";
            }
			
			// We just stopped moving, tell the cube
			if(BFL&BFL_MOVING != BFL_CACHE&BFL_MOVING)
				llRegionSayTo(CUBE, SupportcubeCfg$listenOverride, (str)SupportcubeOverride$tKFMEnd);
			
        }
        
        BFL_CACHE = BFL;
        
    }
	
	// Dismount complete
	else if(id == TIMER_DISMOUNTING){
        if(llGetAgentInfo(llGetOwner())&AGENT_SITTING){
            RLV$unsit(0);
        }

        // Raise climb unsit event
        BFL=BFL&~BFL_DISMOUNTING;
    }
	
	// Initialization complete
	else if(id == TIMER_INI){
        BFL = BFL&~BF_CLIMB_INI;
    }
	
	else if(id == TIMER_CD){
		BFL = BFL&~BFL_LAST_UPDATE;
	}
	else if(id == TIMER_GRACE)
		BFL = BFL&~BFL_GRACE_PERIOD;
	
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

onEvt(string script, integer evt, list data){
    if(script == "jas RLV" && evt == RLVevt$supportcubeSpawn){
        CUBE = llList2String(data,0);
    }
    else if(script == "#ROOT"){
        integer n = llList2Integer(data,0);
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
        
	if(METHOD == ClimbMethod$stop){
		if(BFL&BFL_CLIMBING && (~BFL&BFL_GRACE_PERIOD || ~llGetAgentInfo(llGetOwner()) & AGENT_SITTING ))
			dismount(FALSE);
	}
    if(id == ""){
		
        if(METHOD == ClimbMethod$start){
			if(BFL&BFL_CLIMBING){
                if(~BFL&BFL_GRACE_PERIOD)
					dismount(FALSE);
				debugUncommon("Dismount");
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
			onStart = tr(method_arg(9));
			onEnd = tr(method_arg(10)); 
			

            if(CLIMBSPEED<=0)
				CLIMBSPEED = ClimbCfg$defaultSpeed;
            list dta = llGetObjectDetails(ladder, [OBJECT_POS, OBJECT_ROT]);
            ladder_root_pos = llList2Vector(dta,0);
            ladder_root_rot = llList2Rot(dta, 1);
            integer i;
            if(llGetListLength(nodes) == 2)nodes = llList2List(nodes,0,0)+nodes+llList2List(nodes,-1,-1);
            for(i=0; i<llGetListLength(nodes); i++)nodes = llListReplaceList(nodes, [(vector)llList2String(nodes,i)], i, i);
			
            if(llGetListLength(nodes) == 4){
				mount();
			}
			#ifdef DEBUG
			else debugRare("Invalid node length: "+(string)llGetListLength(nodes));
			#endif
        }
    }
        
    #define LM_BOTTOM 
    #include "xobj_core/_LM.lsl"
} 

