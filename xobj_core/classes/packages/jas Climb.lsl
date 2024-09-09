#ifndef USE_EVENTS
#define USE_EVENTS
#endif
#include "xobj_core/_CLASS_STATIC.lsl"
#include "xobj_core/classes/jas Supportcube.lsl"
#include "xobj_core/classes/jas RLV.lsl"
#include "xobj_core/classes/jas AnimHandler.lsl"
#include "xobj_core/classes/jas Climb.lsl"


init(){
	llLinkStopSound(ClimbCfg$soundPrim);
    llSetMemoryLimit(llCeil(llGetUsedMemory()*1.5));
	#ifdef ClimbCfg$onInit
	ClimbCfg$onInit();
	#endif
}

list CSOUNDS = [
	"ld", "c0039e86-b805-c039-db3f-54b7e32d2ad0", 	// Wood ladder
	"rc", "a0596509-bfab-111c-aa94-9c12bd70bf05",	// Rope climb
	"rs", "4d2070de-28a0-3061-7068-71b9fa83b68b",	// Rope slide
	"sh", "095684dd-224d-a542-f66b-4d443e902757",	// Shimmy Rope
	"cc", "ee5b1830-26ec-bd0c-7dc5-a6e83d522aa7",	// climb chain
	"cs", "be14a8a5-0d66-0d11-78da-586c699932e2"	// slide chain
];

// Set when climbing to ClimbCfg$defaultSpeed
float CLIMBSPEED;
float CLIMBSPEED_REV;
string CSOUND;
string CSOUND_D;

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
integer cDir; // Cache of last sent climb direction. Used for the event.

string curSound; // Sound currently being looped
updateSound(){
	
	string s;
	if( BFL&BFL_MOVING ){
	
		s = CSOUND;
		// Actually down
		if( BFL & BFL_DIR_UP )
			s = CSOUND_D;
			
	}
	
	integer pos = llListFindList(CSOUNDS, (list)s);
	if( pos == -1 )
		s = "";
		
	if( s == curSound )
		return;
	
	curSound = s;
	
	if( s == "" ){
		llLinkStopSound(ClimbCfg$soundPrim);
		return;
	}
	
	key uuid = l2k(CSOUNDS, pos+1);
	llLinkPlaySound(ClimbCfg$soundPrim, uuid, 0.1, SOUND_LOOP);

}

sendCdir( integer dir ){
	
	if( ~BFL&BFL_CLIMBING )
		return;
	if( dir == cDir )
		return;
	cDir = dir;
	raiseEvent(ClimbEvt$dir, (str)cDir);
	
}

#define setCubePos(pos) llRegionSayTo(CUBE, SupportcubeCfg$listenOverride, llList2CSV([SupportcubeOverride$tSetPosAndRot, pos, rot*ladder_root_rot]))

translateCubePos(vector pos){
	vector p = pos-prPos(CUBE);
	rotation rot = rot*ladder_root_rot/prRot(CUBE);
	llRegionSayTo(CUBE, SupportcubeCfg$listenOverride, llList2CSV([SupportcubeOverride$tKFM, p, rot, 0.5]));
}

dismount( integer atoffset ){
    
	if( BFL&BFL_DISMOUNTING )
		return;
	
	sendCdir(0);
    BFL = BFL|BFL_DISMOUNTING;
    multiTimer([TIMER_MOVE]);
    BFL = BFL&~BF_CLIMB_INI;
    BFL = BFL&~BFL_CLIMBING_ANIM;
    BFL = BFL&~BFL_CLIMBING;
	BFL = BFL&~BFL_MOVING;
    anim_active_cur = "";
    updateSound();
	
	
    if(anim_active != ""){
        AnimHandler$anim(anim_active,FALSE,0,0,0);
    }
    if(anim_active_down != ""){
        AnimHandler$anim(anim_active_down,FALSE,0,0,0);
    }
    
    string anm = anim_dismount_bottom;
    if(atoffset){
        vector gpos = llGetRootPosition();
        vector offset = offset2global(llList2Vector(nodes,0));
		
        if(~BFL&BFL_DIR_UP){
            offset = offset2global(llList2Vector(nodes,-1));
            anm = anim_dismount_top;
        }
        if(isset(anm)){
            AnimHandler$anim(anm,TRUE,0,0,0);
        }
        setCubePos(offset);
    }
    
    float to = .1;
    if( isset(anm) )
		to = 1;
    if(anim_passive != ""){
        AnimHandler$anim(anim_passive, FALSE, 0,0,0);
    }
    
    multiTimer([TIMER_DISMOUNTING, "", to, FALSE]);
    raiseEvent(ClimbEvt$end, mkarr(([(string)ladder, onEnd])));
	updateSound();
	
}

mount(){

	BFL_CACHE = 0;
	sendCdir(0);
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
    
    if(isset(anim_passive))AnimHandler$anim(anim_passive,TRUE,0,0,0);
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
		if( ~llGetAgentInfo(llGetOwner()) & AGENT_SITTING ){
            if( BFL&BF_CLIMB_INI )
				return;
            dismount(FALSE);
            return;
        }
		
		
		// This is used to limit updates to 0.4 sec unless moving has just started or ended
		

		if(BFL&BFL_LAST_UPDATE && (BFL&BFL_MOVING) == (BFL_CACHE&BFL_MOVING))
			return;

		BFL = BFL|BFL_LAST_UPDATE;
		multiTimer([TIMER_CD, "", 0.4, FALSE]);
		
		
        
		if( BFL & BFL_MOVING ){
		
            vector nodea = offset2global(llList2Vector(nodes,1)); 
            vector nodeb = offset2global(llList2Vector(nodes,2));
            float maxdist = llVecDist(nodea, nodeb);
            // Up and down are reversed in the script for some reason
			float spd = -CLIMBSPEED_REV/maxdist*.5;
			if( ~BFL&BFL_DIR_UP )
				spd = CLIMBSPEED/maxdist*.5;
            perc += spd;
                    
            BFL = BFL|BFL_CLIMBING_ANIM;
            
			string a = anim_active;
            if( ~BFL&BFL_DIR_UP )
				a = anim_active_down;
            if( a != anim_active_cur ){
				if( anim_active_cur )
					AnimHandler$anim(anim_active_cur,FALSE,0,0,0);
				AnimHandler$anim(a,TRUE,0,0,0);
			}
            anim_active_cur = a;	
				
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
            if( anim_active_cur != "" ){
                AnimHandler$anim(anim_active_cur,FALSE,0,0,0);
                anim_active_cur = "";
            }
			
			// We just stopped moving, tell the cube
			if(BFL&BFL_MOVING != BFL_CACHE&BFL_MOVING)
				llRegionSayTo(CUBE, SupportcubeCfg$listenOverride, (str)SupportcubeOverride$tKFMEnd);
			
        }
        updateSound();
		
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
        float d = llVecDist(llGetRootPosition(), offset2global(llList2Vector(l,i)));
        if(dist == 0 || d<dist){
            nn = i; dist = d;
        }
    }
    perc = (float)nn/(llGetListLength(l)-1);
    onNode = nn+1;
}

int PRESSED_KEYS;
onEvt(string script, integer evt, list data){

    if(script == "jas RLV" && evt == RLVevt$supportcubeSpawn){
        CUBE = llList2String(data,0);
    }
    else if( script == "#ROOT" && (evt == evt$BUTTON_RELEASE || evt == evt$BUTTON_PRESS) ){
	
        integer n = llList2Integer(data,0);
		
        if( evt == evt$BUTTON_RELEASE )
			PRESSED_KEYS = PRESSED_KEYS & ~n;
		else
			PRESSED_KEYS = PRESSED_KEYS | n;
			
        integer up = CONTROL_FWD|CONTROL_RIGHT|CONTROL_UP|CONTROL_ROT_RIGHT;
        integer dn = CONTROL_BACK|CONTROL_LEFT|CONTROL_DOWN|CONTROL_ROT_LEFT;
        if( !(PRESSED_KEYS & (up|dn)) ){
		
			BFL = BFL&~BFL_MOVING;
            BFL = BFL&~BFL_DIR_UP;
			sendCdir(0);
			
		}
		else{
		
			// These are reversed for some reason but it is what it is
			BFL = BFL|BFL_MOVING;
			if( PRESSED_KEYS & up ){
			
				BFL = BFL&~BFL_DIR_UP;
				sendCdir(1);
				
			}
			else{
			
				BFL = BFL|BFL_DIR_UP;
				sendCdir(-1);
				
			}
			
		}
		
    }
    
}

default{
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
            if( anim_active_down == "" )
				anim_active_down = anim_active;
            anim_dismount_top = tr(method_arg(5));
            anim_dismount_bottom = tr(method_arg(6));
            nodes = llCSV2List(tr(method_arg(7)));
            CLIMBSPEED = (float)tr(method_arg(8));
			onStart = tr(method_arg(9));
			onEnd = tr(method_arg(10)); 
			CLIMBSPEED_REV = (float)tr(method_arg(11));
			if( CLIMBSPEED <= 0 )
				CLIMBSPEED = ClimbCfg$defaultSpeed;
			if( CLIMBSPEED_REV < .01 )
				CLIMBSPEED_REV = CLIMBSPEED;
			CSOUND = tr(method_arg(12));
			CSOUND_D = tr(method_arg(13));
			if( CSOUND == JSON_INVALID )
				CSOUND = "";
			if( CSOUND == "" )
				CSOUND = "ld"; // For backwards compatibility, default to ladder
			if( CSOUND_D == "" || CSOUND_D == JSON_INVALID )
				CSOUND_D = CSOUND;
			
			
            list dta = llGetObjectDetails(ladder, [OBJECT_POS, OBJECT_ROT]);
            ladder_root_pos = llList2Vector(dta,0);
            ladder_root_rot = llList2Rot(dta, 1);
            integer i;
            if( llGetListLength(nodes) == 2 )
				nodes = llList2List(nodes,0,0)+nodes+llList2List(nodes,-1,-1);
            for( ; i<llGetListLength(nodes); ++i )
				nodes = llListReplaceList(nodes, [(vector)llList2String(nodes,i)], i, i);
			
			
            if(llGetListLength(nodes) == 4){
				#ifdef ClimbCfg$onClimbStart 
				ClimbCfg$onClimbStart();
				#endif
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

