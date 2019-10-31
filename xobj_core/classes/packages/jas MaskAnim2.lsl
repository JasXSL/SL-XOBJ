#ifdef MaskAnimConf$remoteloadOnAttachedIni
	#define USE_EVENTS
#endif
#include "xobj_core/_ROOT.lsl"
#include "xobj_core/classes/jas Remoteloader.lsl"
#include "xobj_toonie/classes/ton MeshAnim.lsl"
#include "xobj_core/classes/jas MaskAnim.lsl"




// Preprocessor definitions to spead up reading
	// Get nr of entries in a block
#define blockGetTexture(block) llList2Key(block, 1)
#define blockGetAlphaMode(block) l2i(block, 2)
#define blockGetAlpha(block) l2f(block, 3)
#define blockGetGlow(block) l2f(block, 4)
#define blockGetTextureRot(block) l2f(block, 5)

	// Get nr of entries in a block
#define blockGetSize(block) (llList2Integer(block,0)>>10)
	// Get current step in the block
#define blockGetStep(block) (llList2Integer(block,0)<<22>>22)
	// Get nr of prims cached into the block
#define blockGetNrPrims(block) llList2Integer(block,6)
	// Get a list of prims in the block. The +2 signifies the nr of elements before this one
#define blockGetPrims(block) (llList2List(block, 7, 7+blockGetNrPrims(block)-1))
	// Get a list of all the frames in the block
#define blockGetFrames(block) (llList2List(block, 7+blockGetNrPrims(block), -1))

// Splices the next block for use in a while loop - blocksArray is the OBJ_CACHE clone to splice from, var is the list the extracted block should be saved to
#define blockSplice(blocksArray, var) list var = llList2List(blocksArray, 0, blockGetSize(blocksArray)-1); blocksArray = llDeleteSubList(blocksArray, 0, blockGetSize(blocksArray)-1);

// Name of the current anim
string CURRENT_ANIM;
/*
		The animating frames are split into blocks with [bitfield, bitfield, prim1, prim2..., face1, face2...]
		proposed new: [
			0 : (int)0000000000arr_length 0000000000step, 
			1 : (key)texture, 
			2 : (int)alpha_mode = PRIM_ALPHA_MODE_MASK,
			3 : (float)alpha = 1
			4 : (float)glow = 1
			5 : (float)textureRot = 0
			6 : (int)prims_stored, 
			7->n : (int)prim1, (int)prim2... 
			n->end : (int)frame1, frame2...]
        ex:
			[(key)texture, 13<<10|0, 3, 1,2,3, 0,1,2,3,4,5,6,7]
			13<<10 = Block length is 13 - |0 = currently on step 0/max1024
			3<<20 3 prims are saved --  0<<8 = Previous face visible in this set was 0  --    |4 = Prim #4 (sl prims, not array index) (max 256)
			1,2,3 = These are the 3 prims
			0,1,2,3,4,5,6,7 = These are the frames
		
			Get last visible frame and prim to hide it:
				integer face = llList2Integer(arr, 1)<<20>>24;
				
*/
// See above
list OBJ_CACHE;
list ACTIVE_FRAMES;		// 2stride: [(int)prim, (int)face] - Hide before a new anim starts

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

#define BFL_AGENTS_IN_RANGE_OVERRIDE 0x8	// Can be set by other scripts, forces animations to play regardless of range


integer findAnim(string name){
	integer i;
	while(i<llGetListLength(MAIN_CACHE)){
		if(llList2String(MAIN_CACHE, i) == name)
			return i;
		i+=llList2Integer(MAIN_CACHE, i+1);
	}
	return -1;
}

// Sets the playing flag on an anim
startAnim(string name, integer restart){
	integer i = findAnim(name); 
	if(i == -1){
		debugUncommon("Anim not found "+name+" in cache "+mkarr(MAIN_CACHE));
		return;
	}
		
	integer f = llList2Integer(MAIN_CACHE, i+3)|MaskAnimFlag$PLAYING;
	MAIN_CACHE = llListReplaceList(MAIN_CACHE, [f], i+3, i+3);

	if(name != CURRENT_ANIM)restart = FALSE;			// make sure we don't restart the current anim unless it's playing
    refreshAnims(restart);
}

// Sets an animation to not playing
stopAnim(string name){
	integer i = findAnim(name);;
	if(i == -1)
		return;
	
	integer f = llList2Integer(MAIN_CACHE, i+3)&~MaskAnimFlag$PLAYING;
	MAIN_CACHE = llListReplaceList(MAIN_CACHE, [f], i+3, i+3);
	
	debugCommon("Stopping "+name);
    //llSetText("Stop", <1,1,1>,1);
    
	// This is active so we need to refresh
	if(name == CURRENT_ANIM)
		refreshAnims(FALSE);
}

#define stopAll() llSetTimerEvent(0)

// Checks which anim is on top and starts it
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
	

	if(top == ""){
		CURRENT_ANIM = "";
		stopAll();
	}
	
	// Ignore because this is already playing and not a restart
	if((top == CURRENT_ANIM && !restart) || top == "")return;
	
	
	// Restart
	if(top == CURRENT_ANIM){
		// Just reset the pointers
		list cur = OBJ_CACHE; integer slot;
		while(cur){
			blockSplice(cur, block);
			// Replace start position
			integer a = llList2Integer(block, 0)&~1023;
			OBJ_CACHE = llListReplaceList(OBJ_CACHE, [a], slot, slot);
			slot+=blockGetSize(block);
		}
	}
	// New anim
	else{
		
		CURRENT_ANIM = top;
		OBJ_CACHE = llList2List(MAIN_CACHE, topnr+MAIN_PRE, topnr+toplen-1);

		FLAG_CACHE = flags;
		SPEED_CACHE = speed;
		
		if(flags&MaskAnimFlag$DONT_HIDE_PREVIOUS)
			ACTIVE_FRAMES = [];
		
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


// Switches an animation's blocks between mask and alpha
list toggleMask(string anim, integer useMask){
	integer pos = findAnim(anim);
	if(pos == -1)return [];
	
	integer flags = l2i(MAIN_CACHE, pos+3);
	integer mode = PRIM_ALPHA_MODE_MASK;
	
	if(flags&MaskAnimFlag$USE_EMISSIVE && !useMask)
		mode = PRIM_ALPHA_MODE_EMISSIVE;

	list CL = llList2List(MAIN_CACHE, pos+MAIN_PRE, pos+llList2Integer(MAIN_CACHE, pos+1)-1); 
	list out;
	while(CL){
		blockSplice(CL, block);
		list prims = blockGetPrims(block);
		string texture = blockGetTexture(block);
		
		integer i;
		for(i=0; i<llGetListLength(prims); i++){
			if(useMask){
				out+= [PRIM_LINK_TARGET, llList2Integer(prims, i), PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1,1,0>, ZERO_VECTOR, 0, PRIM_COLOR, ALL_SIDES, <1,1,1>, 1, PRIM_ALPHA_MODE, ALL_SIDES, mode, 100];
			}else{
				integer m = mode;
				if(blockGetAlphaMode(block) != PRIM_ALPHA_MODE_MASK)
					m = blockGetAlphaMode(block);
				float rot = blockGetTextureRot(block);
				out+= [PRIM_LINK_TARGET, llList2Integer(prims, i), PRIM_TEXTURE, ALL_SIDES, texture, <1,1,0>, ZERO_VECTOR, rot, PRIM_COLOR, ALL_SIDES, <1,1,1>, 0, PRIM_ALPHA_MODE, ALL_SIDES, m, 100];
			}
		}

	}
	
	return out;
}

toggleAllMasks(integer hidden){
	// Stopped animations such as death will be borked without this
	if(BFL&BFL_STOPPED)
		return;
	// Find the top level animation
	integer i;
	while(i<llGetListLength(MAIN_CACHE)){
		list data = toggleMask(l2s(MAIN_CACHE, i), hidden);
		PP(0, data);
		i+=llList2Integer(MAIN_CACHE, i+1);
	}
	
	
}


sens(integer inrange){
	if(inrange || BFL&BFL_AGENTS_IN_RANGE_OVERRIDE || llGetAttached()){
		if(~BFL&BFL_AGENTS_IN_RANGE && CURRENT_ANIM != ""){
			#ifdef MaskAnimConf$animStartEvent
			raiseEvent(MaskAnimEvt$onAnimStart, CURRENT_ANIM);
			#endif
			llSetTimerEvent(SPEED_CACHE);
			raiseEvent(MaskAnimEvt$agentsInRange, "");
			debugCommon("Player in range, setting timer: "+(string)SPEED_CACHE);
			
			toggleAllMasks(FALSE);
		}
		BFL = BFL|BFL_AGENTS_IN_RANGE;
	}else{
		if(BFL&BFL_AGENTS_IN_RANGE){
			raiseEvent(MaskAnimEvt$agentsLost, "");
			debugUncommon("No player in range, stopping");
			llSetTimerEvent(0);
			toggleAllMasks(TRUE);
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
	
		#ifdef MaskAnimConf$remoteloadOnRez
		integer pin = floor(llFrand(0xFFFFFF));
		llSetRemoteScriptAccessPin(pin);
		runMethod(llGetOwner(), "jas Remoteloader", RemoteloaderMethod$load, [cls$name, pin, 2], TNN);
		#endif
		

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

		integer i;
		for(i=0; i<total; i++){
			if(llVecDist(llGetRootPosition(), llDetectedPos(i))<MaskAnimConf$LIMIT_RAYCAST_RANGE){
				sens(TRUE);
				return;
				// Agent is lower than raycast req range
			}
			else if(llList2Integer(llCastRay(llGetRootPosition()+<0,0,1>, llDetectedPos(i), [RC_REJECT_TYPES, RC_REJECT_AGENTS|RC_REJECT_PHYSICAL]),-1) ==0){
				sens(TRUE);
				return;
			}
		}
		sens(FALSE);
		
		#else
			sens(TRUE);
		#endif
		
		
		
		
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
		
		// ACTIVE_FRAMES is modified at the end of the loop, to prevent the last frame of an animation from sticking
		list active = ACTIVE_FRAMES;
		while(active){
			integer l = l2i(active, 0);
			integer s = l2i(active, 1);
			set+= [PRIM_LINK_TARGET, l, PRIM_COLOR, s, <1,1,1>,0, PRIM_GLOW, s, 0];
			active = llDeleteSubList(active, 0, 1);
		}
		
		while(cl){
			
			blockSplice(cl, block);
			/*
			integer prePrim = blockGetPrePrim(block);
            integer preFace = blockGetPreFace(block);
			*/
            integer step = blockGetStep(block);
			
					
			list frames = blockGetFrames(block);
			list prims = blockGetPrims(block);
	
			
			
			integer maxSteps = llGetListLength(frames);
            integer maxPrims = blockGetNrPrims(block);
			
            while(llGetListEntryType(frames, step) == TYPE_STRING && step<llGetListLength(frames)){
                raiseEvent(MaskAnimEvt$frame, llList2String(frames,step));
                step++;
            }
			
            if(step >= llGetListLength(frames)){
                if(looping){
					step = 0;
				}
                else{
					step = -1;
					set = [];	// Prevent last frame from going invisible
				}
            }
            
            // Successfully stepped a frame
            if(step != -1){
                played = TRUE;
                side = llList2Integer(frames,step);
                integer pr = floor((float)side/8);
                side-=pr*8;
                prim = llList2Integer(prims, pr);
				
				float glow = blockGetGlow(block);
				float alpha = blockGetAlpha(block);
				
				//set+= [linkAlpha(prim, 1, side)];
				set+= [PRIM_LINK_TARGET, prim, PRIM_COLOR, side, <1,1,1>, alpha];
				if(glow)
					set+= [PRIM_GLOW, side, glow];
				
				// Since active frames was shifted off into empty, we can add to it again
				active += [prim, side];
				
            }
			
            
            // Set step
			
			if(prim){
				integer a = llList2Integer(block, 0);
				a = (a&~1023)|(step+1);
				OBJ_CACHE = llListReplaceList(OBJ_CACHE, [a], slot, slot);
			}
			
			slot+=blockGetSize(block);
        }

        if(!played){
            // Clear playing
			debugCommon("AnimDone");
            
			if(FLAG_CACHE&MaskAnimFlag$STOP_ON_END){
				BFL = BFL|BFL_STOPPED;
				llSetTimerEvent(0);
				debugCommon("Stopping all");
			}
			stopAnim(CURRENT_ANIM);
        }else{
			llSetLinkPrimitiveParamsFast(0, set);
			ACTIVE_FRAMES = active;	// Overwrite active frames
			llSetTimerEvent(SPEED_CACHE);
		}
		
    }
    

    #include "xobj_core/_LM.lsl"
        if( method$isCallback )
			return;
		
		
		if( METHOD == MaskAnimMethod$forceInRange ){
		
			if((int)method_arg(0)){
				BFL = BFL|BFL_AGENTS_IN_RANGE_OVERRIDE;
			}else{
				BFL = BFL&~BFL_AGENTS_IN_RANGE_OVERRIDE;
				sens(BFL&BFL_AGENTS_IN_RANGE);
			}
			
		}
		
        else if(METHOD == MaskAnimMethod$start){
		
			debugUncommon("Start anim: "+method_arg(0));
			if( (integer)method_arg(2) )
				BFL = BFL&~BFL_STOPPED;
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
				string tx = texture;
				int alpha_mode = PRIM_ALPHA_MODE_MASK;
				float alpha = 1;
				float glow = 0;
				float texture_rot = 0;
				
				if(llJsonValueType(texture, []) == JSON_OBJECT){
					tx = j(texture, "tx");
					if(isset(j(texture, "alpha_mode")))
						alpha_mode = (int)j(texture, "alpha_mode");
					if(isset(j(texture, "alpha")))
						alpha = (float)j(texture, "alpha");
					if(isset(j(texture, "glow")))
						glow = (float)j(texture, "glow");
					if(isset(j(texture, "texture_rot")))
						texture_rot = (float)j(texture, "texture_rot");
				}
				
				frames = llDeleteSubList(frames, 0, 1);
				
				list idCache = []; 		// Stores link numbers
				integer x;
				
				// Fetch the nr of prims you need for this block
				integer maxFrame;  
				for(x=0; x<llGetListLength(frames); x++)
					if(llList2Integer(frames, x)>maxFrame)maxFrame = llList2Integer(frames,x);
				// Put the IDs into an array
				
				for(x=0; x<maxFrame/8+1 || x<1; x++)idCache+=0;
								
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
				//integer one = (3+llGetListLength(frames+idCache))<<10;
				// hide should be 0 at start so all we need is the nr of prims in the block
				list block = [tx, alpha_mode, alpha, glow, texture_rot]+[llGetListLength(idCache)]+idCache+frames; 
				block = [(1+llGetListLength(block))<<10]+block;
				package += block;
			}
						
			package = llListReplaceList(package, [llGetListLength(package)], 1, 1);
			MAIN_CACHE+=package;
			
			list set = toggleMask(method_arg(0), ~BFL&BFL_AGENTS_IN_RANGE);
			PP(0,set);
			
			raiseEvent(MaskAnimEvt$animInstalled, mkarr(([SENDER_SCRIPT, method_arg(0)])));
			refreshAnims(FALSE);
		}
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
    
       
} 
 



 

