#define USE_EVENTS
#include "xobj_core/_ROOT.lsl"
#include "xobj_core/classes/jas Remoteloader.lsl"
#include "xobj_toonie/classes/ton MeshAnim.lsl"




// Preprocessor definitions to spead up reading
	// Get nr of entries in a block
#define blockGetSize(block) (llList2Integer(block,0)>>10)
	// Get current step in the block
#define blockGetStep(block) (llList2Integer(block,0)<<22>>22)
	// Get nr of prims cached into the block
#define blockGetNrPrims(block) (llList2Integer(block,1)>>12)
	// Get a list of prims in the block
#define blockGetPrims(block) (llList2List(block, 2, blockGetNrPrims(block)+1))
	// Get the previously animated face
#define blockGetPreFace(block) (llList2Integer(block,1)<<20>>28)
	// Get the previously animated prim
#define blockGetPrePrim(block) (llList2Integer(block,1)<<24>>24)
	// Get a list of all the frames in the block
#define blockGetFrames(block) (llList2List(block, 2+blockGetNrPrims(block), -1))

// Splices the next block for use in a while loop - blocksArray is the OBJ_CACHE clone to splice from, var is the list the extracted block should be saved to
#define blockSplice(blocksArray, var) list var = llList2List(blocksArray, 0, blockGetSize(blocksArray)-1); blocksArray = llDeleteSubList(blocksArray, 0, blockGetSize(blocksArray)-1);


string CURRENT_ANIM;
/*
		The animating frames are split into blocks with [bitfield, bitfield, prim1, prim2..., face1, face2...]
		proposed new: [(int)0000000000arr_length 0000000000step, (int)00000000prims_stored 0000pre_face 00000000pre_prim, (int)prim1, (int)prim2... (int)frame1, frame2...]
        ex:
			[13<<10|0, 3<<12|0<<8|4, 1,2,3, 0,1,2,3,4,5,6,7]
			13<<10 = Block length is 13 - |0 = currently on step 0/max1024
			3<<20 3 prims are saved --  0<<8 = Previous face visible in this set was 0  --    |4 = Prim #4 (sl prims, not array index) (max 256)
			1,2,3 = These are the 3 prims
			0,1,2,3,4,5,6,7 = These are the frames
		
			Get last visible frame and prim to hide it:
				integer face = llList2Integer(arr, 1)<<20>>24;
				
*/
// See above
list OBJ_CACHE;

// This contains all the data
list MAIN_CACHE;	
#define MAIN_PRE 5
// Nr params before blocks start
// (str)package_name, package_length, (int)package_prio, (int)flags, (float)speed, block1data, block2data..


// Flags of current animation
integer FLAG_CACHE;
// Speed of current animation
float SPEED_CACHE;

list LAST_HIDE;	// (int)link, (int)face to be hidden when a new animation starts

integer BFL = 0;
#define BFL_AGENTS_IN_RANGE 0x1
#define BFL_STOPPED 0x2

startAnim(string name, integer restart){
	debugCommon("Running startAnim");
	integer i; integer found;
	while(i<llGetListLength(MAIN_CACHE)){
		if(llList2String(MAIN_CACHE, i) == name){
			integer f = llList2Integer(MAIN_CACHE, i+3)|MeshAnimFlag$PLAYING;
			MAIN_CACHE = llListReplaceList(MAIN_CACHE, [f], i+3, i+3);
			found = TRUE;
		}
		i+=llList2Integer(MAIN_CACHE, i+1);
	}
	
	if(!found){
		debugUncommon("Anim not found "+name+" in cache "+mkarr(MAIN_CACHE));
		return;
	}
	if(restart && name == CURRENT_ANIM){
		CURRENT_ANIM = "";
	}
	debugCommon("Start anim ran");
    refreshAnims();
}

stopAnim(string name){
	debugCommon("Running stop anim");
	integer i;
	while(i<llGetListLength(MAIN_CACHE)){
		if(llList2String(MAIN_CACHE, i) == name){
			integer f = llList2Integer(MAIN_CACHE, i+3)&~MeshAnimFlag$PLAYING;
			MAIN_CACHE = llListReplaceList(MAIN_CACHE, [f], i+3, i+3);
		}
		i+=llList2Integer(MAIN_CACHE, i+1);
	}
	debugCommon("Stopping ran on "+name);
    //llSetText("Stop", <1,1,1>,1);
    if(name == CURRENT_ANIM)refreshAnims();
}

stopAll(){
	debugUncommon("Stopping all");
    llSetTimerEvent(0);
}

refreshAnims(){
	debugCommon("Refresh anim");
    string top; integer pri; float speed; integer flags; integer i; integer topnr; integer toplen;
	
	while(i<llGetListLength(MAIN_CACHE)){
		integer f = llList2Integer(MAIN_CACHE, i+3);
		if(f&MeshAnimFlag$PLAYING){
			integer p = llList2Integer(MAIN_CACHE, i+2);
			
			if(p>=pri){
				//qd("Anim: "+llList2String(MAIN_CACHE, i)+" Prio is now the highest: "+(string)p);
				flags = f;
				pri = p; 
				top = llList2String(MAIN_CACHE, i);
				speed = llList2Float(MAIN_CACHE, i+4);
				topnr = i;
				toplen = llList2Integer(MAIN_CACHE, i+1);
			}
		}
		i+=llList2Integer(MAIN_CACHE, i+1);
	}
	
	
	//qd("Top: "+(string)top);
	if(top == "" || top != CURRENT_ANIM){
		// Hide previous
		
		list cur = OBJ_CACHE;
		while(cur){
			blockSplice(cur, block);
			LAST_HIDE+=[blockGetPrePrim(block), blockGetPreFace(block)];
		}
		if(top == ""){
			CURRENT_ANIM = "";
			stopAll();
		}
    }
	
	debugUncommon("Top is "+top);
    if(top == CURRENT_ANIM || top == "")return;
	
    CURRENT_ANIM = top;
	
    OBJ_CACHE = llList2List(MAIN_CACHE, topnr+MAIN_PRE, topnr+toplen-1);
	//qd("OBJ CACHE: "+llList2CSV(OBJ_CACHE));
	
    FLAG_CACHE = flags;
    SPEED_CACHE = speed;
	
	#if MeshAnimConf$LIMIT_AGENT_RANGE>0
	if(~BFL&BFL_AGENTS_IN_RANGE)return;
	#endif
	debugCommon("Starting anim '"+CURRENT_ANIM+"' Speed: "+(string)SPEED_CACHE);
	debugCommon("OBJ_CACHE = "+mkarr(OBJ_CACHE));

	
	#ifdef MeshAnimConf$animStartEvent
	raiseEvent(MeshAnimEvt$onAnimStart, CURRENT_ANIM);
	#endif
	
	if(~BFL&BFL_STOPPED){
		llSetTimerEvent(SPEED_CACHE);
		debugCommon("Starting at speed: "+(str)SPEED_CACHE);
	}
	else{debugCommon("script is force stopped");}
		
}


#ifdef MeshAnimConf$remoteloadOnAttachedIni
onEvt(string script, integer evt, list data){
	if(script == "jas Attached" && evt == evt$SCRIPT_INIT){
		integer pin = llFloor(llFrand(0xFFFFFF));
		llSetRemoteScriptAccessPin(pin);
		runMethod(llGetOwner(), "jas Remoteloader", RemoteloaderMethod$load, [cls$name, pin, 2], TNN);
	}
}
#endif

sens(integer inrange){
	if(inrange||llGetAttached()){
		if(~BFL&BFL_AGENTS_IN_RANGE){
			#ifdef MeshAnimConf$animStartEvent
			raiseEvent(MeshAnimEvt$onAnimStart, CURRENT_ANIM);
			#endif
			llSetTimerEvent(SPEED_CACHE);
			raiseEvent(MeshAnimEvt$agentsInRange, "");
			debugCommon("Player in range, setting timer: "+(string)SPEED_CACHE);
		}
		BFL = BFL|BFL_AGENTS_IN_RANGE;
	}else{
		if(BFL&BFL_AGENTS_IN_RANGE){
			raiseEvent(MeshAnimEvt$agentsLost, "");
			debugUncommon("No player in range, stopping");
			llSetTimerEvent(0);
		}
		BFL = BFL&~BFL_AGENTS_IN_RANGE; 
	}
}

default
{
	#ifdef MeshAnimConf$remoteloadOnRez
	on_rez(integer start){
		llResetScript();
	}
	#endif
	
    state_entry()
    {
		debugCommon("Script started");
		//qd("Running v1");
		#ifdef MeshAnimConf$remoteloadOnRez
		integer pin = llFloor(llFrand(0xFFFFFF));
		llSetRemoteScriptAccessPin(pin);
		runMethod(llGetOwner(), "jas Remoteloader", RemoteloaderMethod$load, [cls$name, pin, 2], TNN);
		#endif
		
        //hideAllAnimating();
        if(llGetStartParameter() == 2){
			debugCommon("Raising init");
			raiseEvent(evt$SCRIPT_INIT, "");
		}
		else{
			debugCommon("Not raising init because start param was " +(str)llGetStartParameter());
		}
		#if MeshAnimConf$LIMIT_AGENT_RANGE>0
			BFL = BFL|BFL_AGENTS_IN_RANGE;
			llSensorRepeat("", "", AGENT, MeshAnimConf$LIMIT_AGENT_RANGE, 4, PI);			
		#else
			raiseEvent(MeshAnimEvt$agentsInRange, "");
			BFL = BFL|BFL_AGENTS_IN_RANGE;
		#endif
		raiseEvent(MeshAnimEvt$agentsInRange, "");
    }
	
	/*
	attach(key id){llResetScript();}
	*/
	
	#if MeshAnimConf$LIMIT_AGENT_RANGE>0
	sensor(integer total){sens(TRUE);}
	no_sensor(){
		if(llGetAttached()){
			sens(TRUE);
			llSensorRemove();
		}
		else sens(FALSE);
	}
	#endif 
	
    timer(){ 
		llSetTimerEvent(0);
        integer played;
        integer looping = (integer)FLAG_CACHE&MeshAnimFlag$LOOPING;
        integer side;
        integer prim;
		
		list set;
		list cl = OBJ_CACHE; integer slot; // Slot keeps track of where we are
		
		
		while(cl){
			blockSplice(cl, block);
			integer prePrim = blockGetPrePrim(block);
            integer preFace = blockGetPreFace(block);
            integer step = blockGetStep(block);
            
			
			
			list frames = blockGetFrames(block);
			list prims = blockGetPrims(block);

			integer maxSteps = llGetListLength(frames);
            integer maxPrims = blockGetNrPrims(block);
			
			//qd("Block "+llGetLinkName(llList2Integer(prims, 0))+" max steps "+(string)maxSteps+" max prims : "+(string)maxPrims);
			
            while(llGetListEntryType(frames, step) == TYPE_STRING && step<llGetListLength(frames)){
                raiseEvent(MeshAnimEvt$frame, llList2String(frames,step));
                step++;
            }
			
            if(step >= llGetListLength(frames)){
                if(looping)step = 0;
                else step = -1;
            }
            
            
            if(step != -1){
                played = TRUE;
                side = llList2Integer(frames,step);
                integer pr = llFloor((float)side/8);
                side-=pr*8;
                prim = llList2Integer(prims, pr);
				
				set+= [linkAlpha(prim, 1, side)];
				//llSetLinkAlpha(prim, 1, side);
				if(prePrim != prim || preFace != side)set += [linkAlpha(prePrim, 0, preFace)];
				//llSetLinkAlpha(prePrim, 0, preFace);
                //llSetText((string)step+" :: "+(string)prim+" :: "+(string)side,<1,1,1>,1);
				
				// Only hide previous if it actually animated
				if(~FLAG_CACHE&MeshAnimFlag$DONT_HIDE_PREVIOUS){
					while(LAST_HIDE){
						integer lpr = llList2Integer(LAST_HIDE, 0);
						integer lfc = llList2Integer(LAST_HIDE, 1);
						LAST_HIDE = llDeleteSubList(LAST_HIDE, 0, 1);
						if(lpr != prim || lfc != side)
							set+= [linkAlpha(lpr, 0, lfc)];
						
					}
				}
				
				
            }
            
            // Set step
			if(prim){
				integer a = llList2Integer(block, 0);
				a = (a&~1023)|(step+1);
				integer b = llList2Integer(block, 1);
				b = (b&~4095)|(side<<8)|prim;
				OBJ_CACHE = llListReplaceList(OBJ_CACHE, [a, b], slot, slot+1);
			}
			slot+=blockGetSize(block);
        }
		
		debugCommon("Ticked");
		
		if(llGetListLength(set)>1){
			//debugCommon("Setting: "+mkarr(set));
			llSetLinkPrimitiveParamsFast(0, set);
		}
		
		
        if(!played){
            // Clear playing
			debugCommon("AnimDone");
            
			if(FLAG_CACHE&MeshAnimFlag$STOP_ON_END){
				BFL = BFL|BFL_STOPPED;
				llSetTimerEvent(0);
				debugCommon("Animation ended");
			}else stopAnim(CURRENT_ANIM);
        }else{
			//qd((string)SPEED_CACHE);
			debugCommon("Resuming");
			llSetTimerEvent(SPEED_CACHE);
		}
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
            if(METHOD == MeshAnimMethod$startAnim){
				debugUncommon("Start anim: "+method_arg(0));
				startAnim(method_arg(0), (integer)method_arg(1));
			}
            else if(METHOD == MeshAnimMethod$stopAnim){ 
                stopAnim(method_arg(0));
            } 
			else if(METHOD == MeshAnimMethod$resume){
				BFL = BFL&~BFL_STOPPED;
				refreshAnims();
			}
            else if(METHOD == MeshAnimMethod$stopAll)stopAll() ;     
			else if(METHOD == MeshAnimMethod$emulateFrameEvent)raiseEvent(MeshAnimEvt$frame, method_arg(0));
			else if(METHOD == MeshAnimMethod$rem){
				debugCommon("Removing anim "+method_arg(0)+" sent from "+SENDER_SCRIPT);
				integer i; string name = method_arg(0);
				while(i<llGetListLength(MAIN_CACHE) && llGetListLength(MAIN_CACHE)){
					if(llList2String(MAIN_CACHE, i) == name){
						integer len = llList2Integer(MAIN_CACHE, i+1);
						MAIN_CACHE = llDeleteSubList(MAIN_CACHE, i, i+len-1);
					}else i+=llList2Integer(MAIN_CACHE, i+1);
				}
				debugCommon("Anim removed");
				refreshAnims();
			}
			else if(METHOD == MeshAnimMethod$add){
				//(str)package_name, package_length, (int)package_prio, (int)flags, (float)speed, block1data, block2data..
				// anim, data, flags, priority
				debugCommon("Adding anim "+method_arg(0));
				
				string data = method_arg(1);
				list package = [method_arg(0), 0, (integer)method_arg(3), (integer)method_arg(2), (float)jVal(data, ["s"])];
				list json = llJson2List(jVal(data, ["o"]));
				while(json){
					// Build the index 
					string val = llList2String(json,  0);
					json = llDeleteSubList(json,0,0);
					
					string rootPrimName = jVal(val, ["p"]);
					list frames = llJson2List(jVal(val, ["f"]));
					list idCache = []; 
					integer x;
					
					// Fetch the nr of prims you need for this block
					integer maxFrame;  
					for(x=0; x<llGetListLength(frames); x++)
						if(llList2Integer(frames, x)>maxFrame)maxFrame = llList2Integer(frames,x);
					// Put the IDs into an array
					for(x=0; x<llCeil((float)maxFrame/8) || x<1; x++)idCache+=0;
					

					// Find all the prims in the linkset and put them to idCache
					links_each(num, ln, {
						if(llGetSubString(ln, 0, llStringLength(rootPrimName)-1) == rootPrimName){
							integer n = (integer)llGetSubString(ln, llStringLength(rootPrimName), -1);
							if(n<=llGetListLength(idCache)){
								idCache = llListReplaceList(idCache, [num], n-1, n-1);
							}
						}
					});
					integer p =llListFindList(idCache, [0]); 
					if(~p){
						qd("Error: Prims not found for "+method_arg(0)+" ("+(string)p+"). Your prim should not end in a number as that's auto-implemented. Missing prims for "+rootPrimName);
						return;
					}
					
					// Step should naturally be 0, and list length is 2+prims.length+frames.length
					integer one = (2+llGetListLength(frames+idCache))<<10;
					// hide should be 0 at start so all we need is the nr of prims in the block
					integer two = (llGetListLength(idCache)<<12);
					
					list block = [one, two]+idCache+frames;
					package += block;
				}
				package = llListReplaceList(package, [llGetListLength(package)], 1, 1);
				MAIN_CACHE+=package;
				debugCommon("Anim added");
				refreshAnims();
			}
        }   
        else if(nr == METHOD_CALLBACK){   
            
        }  

    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
    
       
} 
 



 

