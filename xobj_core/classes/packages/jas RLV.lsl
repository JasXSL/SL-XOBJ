#include "xobj_core/classes/jas Supportcube.lsl"
#include "xobj_core/classes/jas Remoteloader.lsl"
#include "xobj_core/classes/jas Attached.lsl"
#include "xobj_core/classes/jas RLV.lsl"

#define outputSprint() llSetLinkPrimitiveParamsFast(sprintPrim, [PRIM_TEXTURE, RLVcfg$sprintFace, sprintTexture, <1,.5,0>, <0,-.25+(1-sprint/RLVcfg$limitSprint)*.5,0>, RLVcfg$sprintFaceRot])

#ifdef RLVcfg$USER_EVENTS
	#define USE_EVENTS
	#define onEvt RLVcfg$USER_EVENTS
#endif

// Conf
string CURRENT_FOLDER;
string SUBFOLDER;
#if RLVcfg$USE_KEEPATTACH==1
list KEEP_ATTACHED = []; // (str)itemName, (key)id
#endif

#if RLVcfg$USE_SPRINT==1
float sprint = RLVcfg$limitSprint;
string sprintTexture = "c0f942a2-46c3-2489-33ef-f072a6cb4e0d";
integer sprintPrim;
float sprintFadeModifier = 1;
float sprintRegenModifier = 1;
#endif

// Include the main file


// Include the general class functionality - Make a full include to grab any private stuff
#include "xobj_core/classes/jas RLV.lsl"

string WINDLIGHT;
string WINDLIGHT_OVERRIDE;

integer BFL;
#define BFL_SPRINTING 1
#define BFL_RUN_LOCKED 2
#define BFL_SPRINT_STARTED 0x4

#define TIMER_SPRINT_CHECK "a"
#define TIMER_SPRINT_QUICK "b"
#define TIMER_SPRINT_START_REGEN "c"
#define TIMER_SPRINT_FADE "d"
#define TIMER_ATTACHED_CHECK "e"
#define TIMER_INIT_DLY "f"

key supportcube;
list cubetasks;
cubeTask(list tasks){
    cubetasks+=tasks;
    if(cubetasks){
        
        if(llKey2Name(supportcube) != ""){
			debugUncommon("Running cube tasks on "+(string)playerChan(llGetOwner()));
            runMethod((string)supportcube, "jas Supportcube", SupportcubeMethod$execute, cubetasks, TNN);
            cubetasks = [];
        }else{
			debugUncommon("Spawning cube");
            llRezAtRoot("SupportCube", llGetPos()-<0,0,3>, ZERO_VECTOR, ZERO_ROTATION, 300);
        }
        
    }
}

#if RLVcfg$USE_KEEPATTACH==1
integer findAttached(string item){
    integer i;
    for(i=0; i<llGetListLength(KEEP_ATTACHED); i+=2){
        if(llList2String(KEEP_ATTACHED, i) == item)return i;
    }
    return -1;
}
public_addAttached(string item){
    integer idx = findAttached(item);
    if(idx == -1){
        KEEP_ATTACHED += [item, ""];
    }else if(llKey2Name(llList2Key(KEEP_ATTACHED, idx+1)) != "")return;
    // Attach
    runMethod((string)LINK_ALL_OTHERS, "jas Remoteloader", RemoteloaderMethod$attach, [item], item);
    if(KEEP_ATTACHED)multiTimer([TIMER_ATTACHED_CHECK, "", 10, TRUE]);
}
public_remAttached(string item){
    integer idx = findAttached(item);
    if(~idx){
        key targ = llList2Key(KEEP_ATTACHED, idx+1);
        KEEP_ATTACHED = llDeleteSubList(KEEP_ATTACHED, idx, idx+1);
    }
    runOmniMethod("jas Attached", AttachedMethod$remove, [item], "");
    if(KEEP_ATTACHED == [])multiTimer([TIMER_ATTACHED_CHECK]);
}
#endif


#if RLVcfg$USE_FOLDERS==1
public_setFolder(string folder){
    string pre = CURRENT_FOLDER;
    if(folder == pre)return;
    CURRENT_FOLDER = folder;
    list folders = RLVcfg$CLOTHLAYERS;
    string subfolder = SUBFOLDER;
    if(subfolder)subfolder = subfolder+"/";

    list_shift_each(folders,val, {
        if(val != folder)llOwnerSay("@detachAll:"+RLVcfg$FOLDER_ROOT+"/"+subfolder+val+"=force");
    });
    llOwnerSay("@attachAllOver:"+RLVcfg$FOLDER_ROOT+"/"+subfolder+folder+"=force");
}
#endif

#if RLVcfg$USE_SPRINT==1
damageSprint(float amount){
	sprint-=llFabs(amount);
    if(sprint<=0){
		sprint = 0;
        
		if(~BFL&BFL_RUN_LOCKED){
			BFL = BFL|BFL_RUN_LOCKED;
			llOwnerSay("@alwaysrun=n,temprun=n");
		}
    }
	
	if(~BFL&BFL_SPRINT_STARTED){
		multiTimer([TIMER_SPRINT_START_REGEN]);
		BFL = BFL|BFL_SPRINT_STARTED;
	}
	
	
	outputSprint();
}
#endif

// Events
timerEvent(string id, string data){
#if RLVcfg$USE_SPRINT==1
    if(id == TIMER_SPRINT_CHECK){ 
        integer pstatus = llGetAgentInfo(llGetOwner());
        if(pstatus&AGENT_ALWAYS_RUN && pstatus&AGENT_WALKING){
            if(sprint==RLVcfg$limitSprint){
                multiTimer([TIMER_SPRINT_FADE]);
				#ifdef RLVcfg$sprintFadeOut
					#ifdef RLVCfg$sprintPrimConf
						llSetLinkPrimitiveParams(sprintPrim, RLVCfg$sprintPrimConf);
					#endif
					llSetLinkAlpha(sprintPrim, 1, RLVcfg$sprintFace); 
				#endif
            }
            if(~BFL&BFL_SPRINTING)multiTimer([TIMER_SPRINT_QUICK, "", .1, TRUE]);
            BFL=BFL|BFL_SPRINTING;
        }
        else{
            if(BFL&BFL_SPRINT_STARTED){
                multiTimer([TIMER_SPRINT_QUICK]);
                multiTimer([TIMER_SPRINT_START_REGEN, "", RLVCfg$sprintGracePeriod, FALSE]);
				BFL = BFL&~BFL_SPRINT_STARTED;
            }
            BFL = BFL&~BFL_SPRINTING;
        }
    }
	
	else if(id == TIMER_SPRINT_QUICK){
        if(BFL&BFL_SPRINTING){
            damageSprint(.1*sprintFadeModifier);
			return;
        }
        
		if(BFL&BFL_RUN_LOCKED){
			llOwnerSay("@alwaysrun=y,temprun=y");
			BFL = BFL&~BFL_RUN_LOCKED;
		}
		
		sprint+=.025*sprintRegenModifier;
		if(sprint>=RLVcfg$limitSprint){
			multiTimer([id]);
			#ifdef RLVcfg$sprintFadeOut
			multiTimer([TIMER_SPRINT_FADE, 1., .1, TRUE]);
			#endif
		}
	
        if(sprint<0)sprint = 0;
        else if(sprint > RLVcfg$limitSprint)sprint = RLVcfg$limitSprint;
        outputSprint();
    }
	
	else if(id == TIMER_SPRINT_START_REGEN){
        multiTimer([TIMER_SPRINT_QUICK, "", .1, TRUE]);
    }
	
	#ifdef RLVcfg$sprintFadeOut
	else if(id == TIMER_SPRINT_FADE){
		float f = 0;
		if(RLVcfg$sprintFadeOut > 0)
			f = (float)data-(.05/RLVcfg$sprintFadeOut);
			
        llSetLinkAlpha(sprintPrim, f, ALL_SIDES);
        multiTimer([TIMER_SPRINT_FADE, f, .1, FALSE]);
        if(f <0)multiTimer([id]);
    }
	#endif
	else
#endif

#if RLVcfg$USE_KEEPATTACH==1
    if(id == TIMER_ATTACHED_CHECK){
        objarr_each(KEEP_ATTACHED, i, k, val, {
            public_addAttached(k);
        })
    }
#endif
	if(id == TIMER_INIT_DLY){
        llOwnerSay("@alwaysrun=y,temprun=y");
		llOwnerSay("@"+RLVcfg$initDly);
		
        /*
		if(llGetOwner() == "a13c0286-419f-4699-9e14-703432507160"){
            //llOwnerSay("@clear");
        }
		*/
    }
} 

#if RLVcfg$USE_FOLDERS==1
public_setSubFolder(string folder){
    if(folder == JSON_INVALID || folder == JSON_NULL)folder = "";
    SUBFOLDER = folder;
}
#endif

default 
{
    object_rez(key id){
        if(llKey2Name(id) == "SupportCube"){
            supportcube = id;

            raiseEvent(RLVevt$supportcubeSpawn, (string)id);
            //llSleep(.2);
            //cubeTask([]);
        }
    }
    
    attach(key id){
        if(id != llGetOwner())llOwnerSay("@"+RLVcfg$onRemove);
		else llResetScript();
    }
    
    state_entry()
    {
        integer chan = llAbs(playerChan(llGetOwner())+133);
        llListen(chan, "", llGetOwner(), "");
        if(llGetAttached())llOwnerSay("@versionnum="+(string)chan);
        #if RLVcfg$USE_SPRINT==1
        links_each(num, ln, {
            if(ln == RLVcfg$sprintName){sprintPrim = num;}
        })
		
		#ifdef RLVcfg$sprintFadeOut
			llSetLinkAlpha(sprintPrim, 0, ALL_SIDES);
		#endif
		
		#endif 
		#if RLVcfg$USE_CAM==1
		if(llGetAttached())
			llRequestPermissions(llGetOwner(), PERMISSION_CONTROL_CAMERA);
		#endif
		memLim(1.5);
    }
    
    listen(integer chan, string name, key id, string message){
        if((integer)message){
            raiseEvent(evt$SCRIPT_INIT, llList2Json(JSON_OBJECT, ["s", cls$name]));
            llOwnerSay("@"+RLVcfg$onInit);
            multiTimer([TIMER_INIT_DLY, "", 1, FALSE]);
            #if RLVcfg$USE_SPRINT==1
            multiTimer([TIMER_SPRINT_CHECK, "", .5, TRUE]);
            #endif
        }
    }

    timer(){multiTimer([]);}
    
    
    #include "xobj_core/_LM.lsl"
    /*
        Included in all these calls:
        METHOD - (int)method
        INDEX - (int)obj_index
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters
        CB_DATA - This is where you set any callback data you have
    */
    if(method$isCallback){
        if(method$byOwner){
			#if RLVcfg$USE_KEEPATTACH==1
            if(METHOD == RemoteloaderMethod$attach){
                integer pos = findAttached(CB);
                if(~pos){
                    KEEP_ATTACHED = llListReplaceList(KEEP_ATTACHED, [mkarr(PARAMS)], pos+1, pos+1);
                }
            }
			#endif
        }
        return;
    }
	
	if(method$internal && METHOD == RLVMethod$reset){
		llOwnerSay("@setenv_preset:midday=force");
		llResetScript();
	}
    
	#ifndef RLVcfg$NO_RESTRICT
    if(method$byOwner){
	#endif
	
        #if RLVcfg$USE_FOLDERS==1
		if(METHOD == RLVMethod$setFolder)
            public_setFolder(method_arg(0));
        else if(METHOD == RLVMethod$setSubFolder){
            public_setSubFolder(method_arg(0));
        }
		#endif
		
		#if RLVcfg$USE_CAM==1
		if(METHOD == RLVMethod$staticCamera){
			if(~llGetPermissions()&PERMISSION_CONTROL_CAMERA)return;
			vector pos = (vector)method_arg(0);
			rotation rot = (rotation)method_arg(1);
            if(pos == ZERO_VECTOR){
				raiseEvent(RLVevt$cam_unset, "");
				return llClearCameraParams();
			}
			raiseEvent(RLVevt$cam_set, mkarr([pos]));
			llSetCameraParams([
				CAMERA_ACTIVE, 1, // 1 is active, 0 is inactive
				CAMERA_FOCUS, pos+llRot2Fwd(rot), // region relative position
				CAMERA_FOCUS_LOCKED, TRUE, // (TRUE or FALSE)
				CAMERA_POSITION, pos, // region relative position
				CAMERA_POSITION_LOCKED, TRUE // (TRUE or FALSE)
			]);
		}
		#endif
			
		if(METHOD == RLVMethod$cubeTask){
			debugCommon("Received cubetasks: "+PARAMS);
            cubeTask(PARAMS);
        }
			
		#if RLVcfg$USE_KEEPATTACH==1
		if(METHOD == RLVMethod$keepAttached)
			public_addAttached(method_arg(0));
        else if(METHOD == RLVMethod$remAttached)
			public_remAttached(method_arg(0)); 
		#endif
           			
		if(METHOD == RLVMethod$cubeFlush){
			cubeTask([]);
        }else if(METHOD == RLVMethod$sitOn){
            string add = "";
            if((integer)method_arg(1))add = ",unsit=n";
            llOwnerSay("@sit:"+method_arg(0)+"=force"+add);
        }else if(METHOD == RLVMethod$unsit){
            string add = "";
            if((integer)method_arg(0))add="unsit=y,";
			//qd("Unsit received from "+SENDER_SCRIPT);
            llOwnerSay("@"+add+"unsit=force");
        }else if(METHOD == RLVMethod$limitCamDist){
			if((float)method_arg(0)<0)llOwnerSay("@camdistmax=y");
				else llOwnerSay("@camdistmax:"+method_arg(0)+"=n");
			}
		else if(METHOD == RLVMethod$preventTP){
			string app = "y";
			if(!(integer)method_arg(0))app = "n";
			llOwnerSay("@tploc="+app+",tplure="+app);
		}
		else if(METHOD == RLVMethod$preventFly){
			string app = "y";
			if(!(integer)method_arg(0))app = "n";
			llOwnerSay("@fly="+app);
		}

		#if RLVcfg$USE_WINDLIGHT==1
		if(METHOD == RLVMethod$windlightPreset){
			integer override = (int)method_arg(1);
			string wl = method_arg(0);
			if(override)WINDLIGHT_OVERRIDE = wl;
			else WINDLIGHT = wl;
            llOwnerSay("@setenv_preset:"+wl+"=force");
        }
        else if(METHOD == RLVMethod$resetWindlight){
			WINDLIGHT_OVERRIDE = "";
            llOwnerSay("@setenv_preset:"+WINDLIGHT+"=force");
		}
		
		else if(METHOD == RLVMethod$setWindlight){
			list allowed = [
				"ambient", "RGB",				
				"bluedensity", "RGB",				
				"bluehorizon", "RGB",
				"cloudcolor", "RGB",
				"cloudcoverage", "",
				"cloud", "XYD",
				"clouddetail", "XYD",
				"cloudscale", "",
				"cloudscroll", "XY",				
				"densitymultiplier", "",
				"distancemultiplier", "",
				"hazedensity", "",
				"hazehorizon", "",
				"maxaltitude", "",
				"scenegamma", "",
				"sunglowfocus", "",
				"sunglowsize", "",
				"starbrightness", "",
				"sunmooncolorr", "RGB",
				"sunmoonposition", ""
			];
			string d = method_arg(0);
			
			list dump;
			
			integer i;
			for(i=0; i<count(allowed); i+= 2){
				list add; string v = j(d, l2s(allowed, i));
				
				if(v != JSON_INVALID){
					string type = l2s(allowed, i+1);
					
					// RGB
					if(type == "RGB"){
						vector vec = (vector)v;
						add += "setenv_"+l2s(allowed,i)+"r:"+(string)vec.x+"=force";
						add += "setenv_"+l2s(allowed,i)+"g:"+(string)vec.y+"=force";
						add += "setenv_"+l2s(allowed,i)+"b:"+(string)vec.z+"=force";
					}
					
					// XYD or XY
					else if(type == "XYD" || type == "XY"){
						vector vec = (vector)v;
						add += "setenv_"+l2s(allowed,i)+"x:"+(string)vec.x+"=force";
						add += "setenv_"+l2s(allowed,i)+"y:"+(string)vec.y+"=force";
						if(type == "XYD")
							add += "setenv_"+l2s(allowed,i)+"d:"+(string)vec.z+"=force";
					}

					// Float
					else
						add += "setenv_"+l2s(allowed,i)+":"+(string)((float)v)+"=force";
					
					if(llStringLength(implode(",",dump))+1+llStringLength(implode(",",add)) > 1000){
						llOwnerSay("@"+implode(",",dump));
						dump = [];
					}
					dump+= add;
				}
			}
			
			if(dump){
				llOwnerSay("@"+implode(",",dump));
			}
		}
		
		
		#endif
            
        #if RLVcfg$USE_SPRINT==1
        if(METHOD == RLVMethod$sprintFadeModifier)sprintFadeModifier = (float)method_arg(0);
        else if(METHOD == RLVMethod$sprintRegenModifier)sprintRegenModifier = (float)method_arg(0);
        else if(METHOD == RLVMethod$addSprint){
			float a = (float)method_arg(0);
			if(a<0){
				damageSprint(a*RLVcfg$limitSprint);
				return;
			}
				
			sprint+=a*RLVcfg$limitSprint;
			if(sprint>RLVcfg$limitSprint)sprint = RLVcfg$limitSprint;
			outputSprint();
		}
        #endif
		
		if(METHOD == RLVMethod$turnTowards){
			vector vec = (vector)method_arg(0)-llGetPos();
            vector fwd = vec * <0.0, 0.0, -llSin(PI_BY_TWO * 0.5), llCos(PI_BY_TWO * 0.5)>;
            fwd.z = 0.0;
            fwd = llVecNorm(fwd);
             vector left = fwd * <0.0, 0.0, llSin(PI_BY_TWO * 0.5), llCos(PI_BY_TWO * 0.5)>;
            rotation rot = llAxes2Rot(fwd, left, fwd % left);
            vector euler = -llRot2Euler(rot);
            llOwnerSay("@setrot:"+(string)euler.z+"=force");
		}
	#ifndef RLVcfg$NO_RESTRICT	
    }
	#endif
	
	#if RLVcfg$USE_SPRINT==1
    if(METHOD == RLVMethod$setSprintPercent){
        sprint = RLVcfg$limitSprint*(float)method_arg(0);
		outputSprint();
	}
	#endif
	
    
    #define LM_BOTTOM 
    #include "xobj_core/_LM.lsl"
    
}



