#define USE_EVENTS

#include "xobj_core/classes/st Remoteloader.lsl"
#include "xobj_toonie/classes/cl MeshAnim.lsl"


#ifndef MeshAnimConf$LIMIT_AGENT_RANGE
#define MeshAnimConf$LIMIT_AGENT_RANGE 0
#endif


#define TIMER_FRAME "a"

string CURRENT_ANIM;
/*

        list OBJ_CACHE; // Ex: [0, | 2,0, | 1,2, | 0,1,2,3,4,5,6,7,"benis"]
                // [0] = step
                // [2,0] = PRE prim, face
                // [1,2] = prims
                // [0,1,2,3,4,5,6,7,"benis"] = steps
                
        list OBJ_INDEX; 
                // Stride: [(int)prim_index_length, (int)frames_length]
                // Ex: [2] - 2 prims are stored
                // Ex: [9] - 9 frames are stored
*/

list OBJ_CACHE;
list OBJ_INDEX;

integer FLAG_CACHE;
list PRE; 
float SPEED_CACHE;
list LAST_HIDE;

integer BFL = 1;
#define BFL_AGENTS_IN_RANGE 1


public_startAnim(string name){

    list search = __search(name, MeshAnimVal$name);
    if(llList2Integer(search,0) == -1)return;
    
    
    list_shift_each(search, val, {
        cls$setIndex(val);
        integer f = (integer)this(MeshAnimVal$flags);
        f = f|MeshAnimFlag$PLAYING;
        this$setProperty(MeshAnimVal$flags, f);
    });
    
    private_refreshAnims(); 
}

public_stopAnim(string name){
    list search = __search(name, MeshAnimVal$name);
    if(llList2Integer(search,0) == -1){
        return;
    }
    
    list_shift_each(search, val, {
        cls$setIndex(val);
        integer f = (integer)this(MeshAnimVal$flags);
        f = f&~MeshAnimFlag$PLAYING;
        this$setProperty(MeshAnimVal$flags, f);
    });
    //llSetText("Stop", <1,1,1>,1);
    if(name == CURRENT_ANIM){
		private_refreshAnims();
	}
}

public_stopAll(){
    multiTimer([TIMER_FRAME]);
}

public_hideAllAnimating(){   
    llSetLinkAlpha(LINK_SET, 0, ALL_SIDES);
}

private_refreshAnims(){
    string top; integer pri; string data; integer idx; integer flags; integer  i;
    cls$each(index, obj, {
        integer playing = (integer)jVal(obj, [MeshAnimVal$flags]);
        if(playing&MeshAnimFlag$PLAYING){
            integer p = (integer)jVal(obj, [MeshAnimVal$priority]);
            if(p>=pri){
                flags = playing;
                pri = p; top = jVal(obj, [MeshAnimVal$name]);
                data = obj;
            }
        }
    });
	
	if(top == "" || top != CURRENT_ANIM){
		if(CURRENT_ANIM != ""){
			LAST_HIDE = [];
			for(i=0; i<llGetListLength(OBJ_INDEX); i+=2){
				LAST_HIDE+=[llList2Integer(OBJ_CACHE, idx+1), llList2Integer(OBJ_CACHE, idx+2)];
				idx+= 3+llList2Integer(OBJ_INDEX, i)+llList2Integer(OBJ_INDEX, i+1); // Fixed length params
			}
		}
		if(top == ""){
			CURRENT_ANIM = "";
			cls$clear();
			public_stopAll();
		}
    }
	
    if(top != CURRENT_ANIM && top != ""){
        CURRENT_ANIM = top;
        list json = llJson2List(llJsonGetValue(data, [MeshAnimVal$frames, "o"]));
        OBJ_INDEX = []; OBJ_CACHE = [];
        
        for(i=0;  i<llGetListLength(json);  i++){
            // Build the index 
            string val = llList2String(json,  i);
            string rootPrimName = jVal(val, ["p"]);
            list frames = llJson2List(jVal(val, ["f"]));
            list idCache = []; 
            
            // Build idCache
            integer maxFrame; integer x; 
            for(x=0; x<llGetListLength(frames); x++){
                if(llList2Integer(frames, x)>maxFrame)maxFrame = llList2Integer(frames,x);
            }
			
			
            for(x=0; x<llCeil((float)maxFrame/8) || x<1; x++)idCache+=0;

            links_each(num, ln, {
                if(llGetSubString(ln, 0, llStringLength(rootPrimName)-1) == rootPrimName){
                    integer n = (integer)llGetSubString(ln, llStringLength(rootPrimName), -1);
                    
                    if(n<=llGetListLength(idCache))
                        idCache = llListReplaceList(idCache, [num], n-1, n-1);
                }
            });
            

            OBJ_CACHE += [0,0,0]+idCache+frames;
            OBJ_INDEX += [llGetListLength(idCache), llGetListLength(frames)];
        }
        
        FLAG_CACHE = flags;
        SPEED_CACHE = (float)jVal(data, ([MeshAnimVal$frames, "s"]));
		if(MeshAnimConf$LIMIT_AGENT_RANGE && ~BFL&BFL_AGENTS_IN_RANGE)return;
        multiTimer([TIMER_FRAME, "", SPEED_CACHE, FALSE]);
    }
    
}

integer __construct(list args){ // name, frames, flags, priority
    cls$push(([
        MeshAnimVal$name, fn_arg(0),
        MeshAnimVal$frames, fn_arg(1),
        MeshAnimVal$flags, fn_arg(2),
        MeshAnimVal$priority, fn_arg(3)
    ])); 
	private_refreshAnims();
    return TRUE; 
}

timerEvent(string id, string data){
    if(id == TIMER_FRAME){
        integer played;
        integer looping = (integer)FLAG_CACHE&MeshAnimFlag$LOOPING;
        
        /*

        list OBJ_CACHE; // Ex: [0, | 2,0, | 1,2, | 0,1,2,3,4,5,6,7,"benis"]
                // [0] = step
                // [2,0] = PRE prim, face
                // [1,2] = prims
                // [0,1,2,3,4,5,6,7,"benis"] = steps
                
        list OBJ_INDEX; 
                // Stride: [(int)prim_index_length, (int)frames_length]
                // Ex: [2] - 2 prims are stored
                // Ex: [9] - 9 frames are stored
        */
        
        integer  i; integer idx; // Hide the old
        for(i=0; i<llGetListLength(OBJ_INDEX); i+=2){
            integer prePrim = llList2Integer(OBJ_CACHE, idx+1);
            integer preFace = llList2Integer(OBJ_CACHE, idx+2);
            integer step = llList2Integer(OBJ_CACHE, idx);
            integer maxSteps = llList2Integer(OBJ_INDEX, i+1);
            integer maxPrims = llList2Integer(OBJ_INDEX, i);
            list frames = llList2List(OBJ_CACHE, idx+3+maxPrims, idx+3+maxPrims+maxSteps-1);
            list prims = llList2List(OBJ_CACHE, idx+3, idx+3+maxPrims-1);
			//llSetText(llList2CSV(OBJ_CACHE),<1,1,1>,1);
            while(llGetListEntryType(frames, step) == TYPE_STRING && step<llGetListLength(frames)){
                raiseEvent(evt$MESH_ANIM_FRAME_EVENT, llList2String(frames,step));
                step++;
            }
            
            if(step >= llGetListLength(frames)){
                if(looping)step = 0;
                else step = -1;
            }
            
            integer side;
            integer prim;
            
            if(step != -1){
                played = TRUE;
                side = llList2Integer(frames,step);
                integer pr = llFloor((float)side/8);
                side-=pr*8;
                prim = llList2Integer(prims, pr);
				
				
				
                llSetLinkAlpha(prim, 1, side);
				if(LAST_HIDE!=[]){
					integer i;
					for(i = 0; i<llGetListLength(LAST_HIDE); i+=2){
						if(llList2Integer(LAST_HIDE,i) != prim || llList2Integer(LAST_HIDE, i+1) != side){
							llSetLinkAlpha(llList2Integer(LAST_HIDE, i), 0, llList2Integer(LAST_HIDE, i+1));
						}
					}
					LAST_HIDE = [];
				}
				if(prePrim != prim || preFace != side)llSetLinkAlpha(prePrim, 0, preFace);
                //llSetText((string)step+" :: "+(string)prim+" :: "+(string)side,<1,1,1>,1);
            }
            
            
            // Set step
			if(prim){
				OBJ_CACHE = llListReplaceList(OBJ_CACHE, [step+1, prim, side], idx, idx+2);
			}
			
            idx+= 3+maxPrims+maxSteps;
        }

        if(!played){
            // Clear playing
            public_stopAnim(CURRENT_ANIM);
            
        }else multiTimer([TIMER_FRAME, "", SPEED_CACHE, FALSE]);
    }
}

// Anim
/*
{
    "s":(flot)speed,
    "o":[{
        "c":[(int)prim1ID...],
        "p":(str)primName,          // 1, 2, 3 is appended as you go
        "s":(int)step,
        "f":[(int)frame OR (obj)command]
    }...]
}

	 
	  
	  
*/
#ifdef MeshAnimConf$remoteloadOnAttachedIni
onEvt(string script, integer evt, string data){
	if(script == "st Attached" && evt == evt$SCRIPT_INIT){
		integer pin = llFloor(llFrand(0xFFFFFF));
		llSetRemoteScriptAccessPin(pin);
		runMethod(llGetOwner(), "st Remoteloader", RemoteloaderMethod$load, [cls$name, pin, 2], TNN);
	}
}
#endif

default
{
    state_entry()
    {
        public_hideAllAnimating();
		
        if(llGetStartParameter() == 2){
			raiseEvent(evt$SCRIPT_INIT, "");
		}
		if(MeshAnimConf$LIMIT_AGENT_RANGE > 0){
			llSensorRepeat("", "", AGENT, MeshAnimConf$LIMIT_AGENT_RANGE, 4, PI);
		}
    }
	
	sensor(integer total){
		if(~BFL&BFL_AGENTS_IN_RANGE)multiTimer([TIMER_FRAME, "", SPEED_CACHE, FALSE]);
		BFL = BFL|BFL_AGENTS_IN_RANGE;
	}
    
	no_sensor(){BFL = BFL&~BFL_AGENTS_IN_RANGE; multiTimer([TIMER_FRAME]);}
	
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
            CB - The callback you specified when you sent a task
        */ 
        if(nr == RUN_METHOD){
            if(METHOD == MeshAnimMethod$startAnim)public_startAnim(llJsonGetValue(PARAMS, [0]));
            else if(METHOD == MeshAnimMethod$stopAnim){ 
                public_stopAnim(method_arg(0));
            } 
            else if(METHOD == MeshAnimMethod$stopAll)public_stopAll() ;     
			else if(METHOD == MeshAnimMethod$emulateFrameEvent)raiseEvent(evt$MESH_ANIM_FRAME_EVENT, method_arg(0));
        }  
        else if(nr == METHOD_CALLBACK){   
            
        }  

    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
    
       
} 
 



 