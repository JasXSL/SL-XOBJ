#define USE_EVENTS
#include "xobj_core/_ROOT.lsl"
#include "xobj_core/classes/jas Remoteloader.lsl"
#include "xobj_toonie/classes/ton MeshAnim.lsl"
#include "xobj_core/classes/jas MaskAnim.lsl"




// Preprocessor definitions to spead up reading
	// Get nr of entries in a block
#define blockGetTexture(block) llList2Key(block, 0)
	// Get nr of entries in a block
#define blockGetSize(block) (llList2Integer(block,1)>>10)
	// Get current step in the block
#define blockGetStep(block) (llList2Integer(block,1)<<22>>22)
	// Get nr of prims cached into the block
#define blockGetNrPrims(block) (llList2Integer(block,2)>>12)
	// Get a list of prims in the block. The +2 signifies the nr of elements before this one
#define blockGetPrims(block) (llList2List(block, 3, blockGetNrPrims(block)+2))
	// Get the previously animated face
#define blockGetPreFace(block) (llList2Integer(block,2)<<20>>28)
	// Get the previously animated prim
#define blockGetPrePrim(block) (llList2Integer(block,2)<<24>>24)
	// Get a list of all the frames in the block
#define blockGetFrames(block) (llList2List(block, 3+blockGetNrPrims(block), -1))

// Splices the next block for use in a while loop - blocksArray is the OBJ_CACHE clone to splice from, var is the list the extracted block should be saved to
#define blockSplice(blocksArray, var) list var = llList2List(blocksArray, 0, blockGetSize(blocksArray)-1); blocksArray = llDeleteSubList(blocksArray, 0, blockGetSize(blocksArray)-1);


string CURRENT_ANIM;
/*
		The animating frames are split into blocks with [bitfield, bitfield, prim1, prim2..., face1, face2...]
		proposed new: [(int)0000000000arr_length 0000000000step, (int)00000000prims_stored 0000pre_face 00000000pre_prim, (int)prim1, (int)prim2... (int)frame1, frame2...]
        ex:
			[(key)texture, 13<<10|0, 3<<12|0<<8|4, 1,2,3, 0,1,2,3,4,5,6,7]
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

integer BFL = 0;
#define BFL_AGENTS_IN_RANGE 0x1
#define BFL_STOPPED 0x2
#define BFL_AGENTS_INIT 0x4			// Animations have been started at least once
#define BFL_AGENTS_IN_RANGE_OVERRIDE 0x8	// Can be set by other scripts, forces animations to play regardless of range

string need_hide = "";				// Need to hide this animation

startAnim(string name, integer restart){
	integer i; integer found;
	while(i<llGetListLength(MAIN_CACHE)){
		if(llList2String(MAIN_CACHE, i) == name){
			//qd("Starting "+name);
			integer f = llList2Integer(MAIN_CACHE, i+3)|MaskAnimFlag$PLAYING;
			MAIN_CACHE = llListReplaceList(MAIN_CACHE, [f], i+3, i+3);
			found = TRUE;
		}
		i+=llList2Integer(MAIN_CACHE, i+1);
	}
	
	if(!found){
		debugUncommon("Anim not found "+name+" in cache "+mkarr(MAIN_CACHE));
		return;
	}
	if(name != CURRENT_ANIM)restart = FALSE;			// make sure we don't restart the current anim unless it's playing
    refreshAnims(restart);
}

stopAnim(string name){
	integer i;
	while(i<llGetListLength(MAIN_CACHE)){
		if(llList2String(MAIN_CACHE, i) == name){
			integer f = llList2Integer(MAIN_CACHE, i+3)&~MaskAnimFlag$PLAYING;
			MAIN_CACHE = llListReplaceList(MAIN_CACHE, [f], i+3, i+3);
		}
		i+=llList2Integer(MAIN_CACHE, i+1);
	}
	debugCommon("Stopping "+name);
    //llSetText("Stop", <1,1,1>,1);
    if(name == CURRENT_ANIM)refreshAnims(FALSE);
}

// Switches an animation's blocks between mask and alpha
list toggleMask(string anim, integer useMask, integer ret){
	integer pos = llListFindList(MAIN_CACHE, [anim]);
	if(pos == -1)return [];
	
	list CL = llList2List(MAIN_CACHE, pos+MAIN_PRE, pos+llList2Integer(MAIN_CACHE, pos+1)-1); 
	list out;
	while(CL){
		blockSplice(CL, block);
		list prims = blockGetPrims(block);
		string texture = blockGetTexture(block);
		
		integer i;
		for(i=0; i<llGetListLength(prims); i++){
			if(useMask){
				out+= [PRIM_LINK_TARGET, llList2Integer(prims, i), PRIM_TEXTURE, ALL_SIDES, "11a77942-f739-544f-1c3a-cd00f4b911db", <1,1,0>, ZERO_VECTOR, 0, PRIM_COLOR, ALL_SIDES, <1,1,1>, 1, PRIM_ALPHA_MODE, ALL_SIDES, PRIM_ALPHA_MODE_MASK, 100];
			}else{
				out+= [PRIM_LINK_TARGET, llList2Integer(prims, i), PRIM_TEXTURE, ALL_SIDES, texture, <1,1,0>, ZERO_VECTOR, 0, PRIM_COLOR, ALL_SIDES, <1,1,1>, 0];
			}
		}

	}
	if(ret)return out;
	llSetLinkPrimitiveParamsFast(0,out);
	return [];
}

#define stopAll() llSetTimerEvent(0)


refreshAnims(integer restart){
	if(BFL&BFL_STOPPED)return;
	debugCommon("Refresh anim");
    string top; integer pri; float speed; integer flags; integer i; integer topnr; integer toplen;
	
	// Find the top level animation
	while(i<llGetListLength(MAIN_CACHE)){
		integer f = llList2Integer(MAIN_CACHE, i+3);
		if(f&MaskAnimFlag$PLAYING){
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
	if(top == ""){
		CURRENT_ANIM = "";
		stopAll();
	}
	
	if((top == CURRENT_ANIM && !restart) || top == "")return;
	
	

	if(top == CURRENT_ANIM){
		// Just reset the pointers
		list cur = OBJ_CACHE; integer slot;
		while(cur){
			blockSplice(cur, block);
			integer a = llList2Integer(block, 1)&~1023;
			/*
			integer b = llList2Integer(block, 2);
			b = (b&~4095)|(side<<8)|prim;*/
			//qd("Step is now: "+(string)(a&1023));
			OBJ_CACHE = llListReplaceList(OBJ_CACHE, [a], slot+1, slot+1);
			slot+=blockGetSize(block);
		}
	}
	else{
		need_hide = CURRENT_ANIM;
		debugUncommon("Setting hide to "+need_hide);
	
		
		CURRENT_ANIM = top;
		toggleMask(CURRENT_ANIM, FALSE, FALSE);
		OBJ_CACHE = llList2List(MAIN_CACHE, topnr+MAIN_PRE, topnr+toplen-1);
		
		

		//qd("OBJ CACHE: "+llList2CSV(OBJ_CACHE));
		
		
		FLAG_CACHE = flags;
		SPEED_CACHE = speed;
	}
	
	#ifdef MaskAnimConf$animStartEvent
	raiseEvent(MaskAnimEvt$onAnimStart, CURRENT_ANIM);
	#endif
		
	
	debugCommon("Starting anim '"+CURRENT_ANIM+"' Speed: "+(string)SPEED_CACHE);
	debugCommon("OBJ_CACHE = "+mkarr(OBJ_CACHE));
	#if MaskAnimConf$LIMIT_AGENT_RANGE>0
	if(~BFL&BFL_AGENTS_IN_RANGE && ~BFL&BFL_AGENTS_IN_RANGE_OVERRIDE)return;
	#endif
	if(~BFL&BFL_STOPPED)
		llSetTimerEvent(SPEED_CACHE);
}


#ifdef MaskAnimConf$remoteloadOnAttachedIni
onEvt(string script, integer evt, list data){
	if(script == "jas Attached" && evt == evt$SCRIPT_INIT){
		integer pin = floor(llFrand(0xFFFFFF));
		llSetRemoteScriptAccessPin(pin);
		runMethod(llGetOwner(), "jas Remoteloader", RemoteloaderMethod$load, [cls$name, pin, 2], TNN);
	}
}
#endif

sens(integer inrange){
	if(inrange || BFL&BFL_AGENTS_IN_RANGE_OVERRIDE || llGetAttached()){
		if(~BFL&BFL_AGENTS_IN_RANGE && CURRENT_ANIM != ""){
			BFL = BFL|BFL_AGENTS_INIT;
			#ifdef MaskAnimConf$animStartEvent
			raiseEvent(MaskAnimEvt$onAnimStart, CURRENT_ANIM);
			#endif
			llSetTimerEvent(SPEED_CACHE);
			raiseEvent(MaskAnimEvt$agentsInRange, "");
			debugCommon("Player in range, setting timer: "+(string)SPEED_CACHE);
		}
		BFL = BFL|BFL_AGENTS_IN_RANGE;
	}else{
		if(BFL&BFL_AGENTS_IN_RANGE){
			raiseEvent(MaskAnimEvt$agentsLost, "");
			debugUncommon("No player in range, stopping");
			llSetTimerEvent(0);
		}
		BFL = BFL&~BFL_AGENTS_IN_RANGE; 
	}
}

remAnim(string name){
	integer i;
	while(i<llGetListLength(MAIN_CACHE) && llGetListLength(MAIN_CACHE)){
		if(llList2String(MAIN_CACHE, i) == name){
			integer len = llList2Integer(MAIN_CACHE, i+1);
			MAIN_CACHE = llDeleteSubList(MAIN_CACHE, i, i+len-1);
		}else i+=llList2Integer(MAIN_CACHE, i+1);
	}
	refreshAnims(FALSE);
}

default
{
	#ifdef MaskAnimConf$remoteloadOnRez
	on_rez(integer start){
		llResetScript();
	}
	#endif
	
    state_entry()
    {
	
		//qd("Running v1");
		#ifdef MaskAnimConf$remoteloadOnRez
		integer pin = floor(llFrand(0xFFFFFF));
		llSetRemoteScriptAccessPin(pin);
		runMethod(llGetOwner(), "jas Remoteloader", RemoteloaderMethod$load, [cls$name, pin, 2], TNN);
		#endif
		
        //hideAllAnimating();

		raiseEvent(evt$SCRIPT_INIT, "");
		
		
		BFL = BFL|BFL_AGENTS_IN_RANGE;
		raiseEvent(MaskAnimEvt$agentsInRange, "");
		
		#if MaskAnimConf$LIMIT_AGENT_RANGE>0
			llSensorRepeat("", "", AGENT, MaskAnimConf$LIMIT_AGENT_RANGE, PI, 2);			
		#endif
		raiseEvent(MaskAnimEvt$agentsInRange, "");
    }
	
	attach(key id){llResetScript();}
	
	
	#if MaskAnimConf$LIMIT_AGENT_RANGE>0
	sensor(integer total){
		#ifdef MaskAnimConf$LIMIT_RAYCAST_RANGE
		if(~BFL&BFL_AGENTS_INIT){
			integer i;
			for(i=0; i<total; i++){
				if(llVecDist(llGetPos(), llDetectedPos(i))<MaskAnimConf$LIMIT_RAYCAST_RANGE){
					return sens(TRUE);
					// Agent is lower than raycast req range
				}
				else if(llList2Integer(llCastRay(llGetPos()+<0,0,1>, llDetectedPos(i), [RC_REJECT_TYPES, RC_REJECT_AGENTS|RC_REJECT_PHYSICAL]),-1) <=0){
					return sens(TRUE);
				}
			}
			return sens(FALSE);
		}
		#endif
		
		sens(TRUE);
		
		
	}
	no_sensor(){
		
		sens(FALSE);
	}
	#endif 
	
    timer(){ 
		llSetTimerEvent(0);
        integer played;
        integer looping = (integer)FLAG_CACHE&MaskAnimFlag$LOOPING;
        integer side;
        integer prim;
		
		list set;
		list cl = OBJ_CACHE; integer slot; // Slot keeps track of where we are
		
		// Just alpha out the previous
		if(FLAG_CACHE&MaskAnimFlag$HIDE_PREVIOUS_PRE && need_hide != ""){
			set+=toggleMask(need_hide, FALSE, TRUE);
			need_hide = "";
		}
		
		while(cl){
			blockSplice(cl, block);
			integer prePrim = blockGetPrePrim(block);
            integer preFace = blockGetPreFace(block);
            integer step = blockGetStep(block);
			

			
			
			list frames = blockGetFrames(block);
			list prims = blockGetPrims(block);
			//qd("NrPrims: "+(string)blockGetNrPrims());
			//qd("Prims: "+mkarr(prims));
			
			integer maxSteps = llGetListLength(frames);
            integer maxPrims = blockGetNrPrims(block);
			
			//qd("Block "+llGetLinkName(llList2Integer(prims, 0))+" max steps "+(string)maxSteps+" max prims : "+(string)maxPrims);
			
			
            while(llGetListEntryType(frames, step) == TYPE_STRING && step<llGetListLength(frames)){
                raiseEvent(MaskAnimEvt$frame, llList2String(frames,step));
                step++;
            }
			
			//qd((string)step+"::"+(string)llGetListLength(frames));
            if(step >= llGetListLength(frames)){
                if(looping){
					step = 0;
				}
                else step = -1;
            }
            
            
            if(step != -1){
                played = TRUE;
                side = llList2Integer(frames,step);
                integer pr = floor((float)side/8);
                side-=pr*8;
                prim = llList2Integer(prims, pr);
				
				
				
				//set+= [linkAlpha(prim, 1, side)];
				set+= [PRIM_LINK_TARGET, prim, PRIM_COLOR, side, <1,1,1>, 1]; //, PRIM_ALPHA_MODE, side, PRIM_ALPHA_MODE_MASK, 100
				//llSetLinkAlpha(prim, 1, side);
				if(prePrim != prim || preFace != side)
					set+= [PRIM_LINK_TARGET, prePrim, PRIM_COLOR, preFace, <1,1,1>, 0]; //, PRIM_ALPHA_MODE, side, PRIM_ALPHA_MODE_MASK, 100
					//llSetLinkAlpha(prePrim, 0, preFace);
                //llSetText((string)step+" :: "+(string)prim+" :: "+(string)side,<1,1,1>,1);
				
				
				
				
            }
            
            // Set step
			if(prim){
				integer a = llList2Integer(block, 1);
				a = (a&~1023)|(step+1);
				integer b = llList2Integer(block, 2);
				b = (b&~4095)|(side<<8)|prim;
				//qd("Step is now: "+(string)(a&1023));
				OBJ_CACHE = llListReplaceList(OBJ_CACHE, [a, b], slot+1, slot+2);
			}
			slot+=blockGetSize(block);
        }

		// Only hide previous if it actually animated
		if(~FLAG_CACHE&MaskAnimFlag$DONT_HIDE_PREVIOUS && need_hide != ""){
			toggleMask(need_hide, TRUE, FALSE);
			need_hide = "";
		}
		
		
		//llSetText(llList2Json(JSON_ARRAY, [looping]+set), <1,1,1>, 1);
		if(llGetListLength(set)>1){
			llSetLinkPrimitiveParamsFast(0, set);
		}
		
		
        if(!played){
            // Clear playing
			debugCommon("AnimDone");
            
			if(FLAG_CACHE&MaskAnimFlag$STOP_ON_END){
				BFL = BFL|BFL_STOPPED;
				llSetTimerEvent(0);
			}
			stopAnim(CURRENT_ANIM);
        }else{
			//qd((string)SPEED_CACHE);
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
        if(method$isCallback)return;
		
		
		if(METHOD == MaskAnimMethod$forceInRange){
			if((int)method_arg(0)){
				BFL = BFL|BFL_AGENTS_IN_RANGE_OVERRIDE;
			}else{
				BFL = BFL&~BFL_AGENTS_IN_RANGE_OVERRIDE;
				sens(BFL&BFL_AGENTS_IN_RANGE);
			}
		}
        else if(METHOD == MaskAnimMethod$start){
			debugUncommon("Start anim: "+method_arg(0));
			if((integer)method_arg(2))BFL = BFL&~BFL_STOPPED;
			startAnim(method_arg(0), (integer)method_arg(1));
		}
        else if(METHOD == MaskAnimMethod$stop){ 
            stopAnim(method_arg(0));
        } 
		else if(METHOD == MaskAnimMethod$resume){
			BFL = BFL&~BFL_STOPPED;
			llSetTimerEvent(0);
			refreshAnims(TRUE);
		}
        else if(METHOD == MaskAnimMethod$pause)stopAll() ;     
		else if(METHOD == MaskAnimMethod$emulateFrameEvent)raiseEvent(MaskAnimEvt$frame, method_arg(0));
		else if(METHOD == MaskAnimMethod$rem)remAnim(method_arg(0));
			
		else if(METHOD == MaskAnimMethod$add){
			//(str)package_name, package_length, (int)package_prio, (int)flags, (float)speed, block1data, block2data..
			// anim, data, flags, priority
			remAnim(method_arg(0));
			debugCommon("Adding anim "+method_arg(0));
			
			float speed = (float)method_arg(1);
			integer flags = (integer)method_arg(2);
			integer priority = (integer)method_arg(3);
			list json = llJson2List(method_arg(4));
			
			list package = [method_arg(0), 0, priority, flags, speed];
			while(json){
			// Build the index 
				list frames = llJson2List(llList2String(json, 0));	// Contains the prim data
				json = llDeleteSubList(json,0,0);
				
				string rootPrimName = llList2String(frames, 0);
				string texture = llList2String(frames, 1);
				frames = llDeleteSubList(frames, 0, 1);
				
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
					list found = [];
					list_shift_each(idCache, val,
						found+= llGetLinkName((int)val);
					)
					qd("Error: Prims not found for "+method_arg(0)+" ("+(string)p+"). Your scripted prim name should not end in a number as that's auto-implemented. Missing prims for "+rootPrimName+" Found prims was "+mkarr(found));
					return;
				}
				
				// Step should naturally be 0, and list length is 3+prims.length+frames.length
				integer one = (3+llGetListLength(frames+idCache))<<10;
				// hide should be 0 at start so all we need is the nr of prims in the block
				integer two = (llGetListLength(idCache)<<12);
					list block = [texture, one, two]+idCache+frames;
				package += block;
			}
			package = llListReplaceList(package, [llGetListLength(package)], 1, 1);
			MAIN_CACHE+=package;
			toggleMask(method_arg(0), TRUE, FALSE); // Hide it
			refreshAnims(FALSE);
		}
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
    
       
} 
 



 

