#ifndef USE_SHARED
#define USE_SHARED [cls$name]
#endif
#include "xobj_core/classes/st Supportcube.lsl"
#include "xobj_core/classes/st Remoteloader.lsl"
#include "xobj_core/classes/st Attached.lsl"
#include "xobj_core/classes/st RLV.lsl"


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
#include "xobj_core/classes/st RLV.lsl"



integer BFL;
#define BFL_SPRINTING 1
#define BFL_RUN_LOCKED 2
 

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
            runMethod((string)supportcube, "st Supportcube", SupportcubeMethod$execute, cubetasks, TNN);
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
    runMethod((string)LINK_ALL_OTHERS, "st Remoteloader", RemoteloaderMethod$attach, [item], TARG_NULL, item, "");
    if(KEEP_ATTACHED)multiTimer([TIMER_ATTACHED_CHECK, "", 10, TRUE]);
}
public_remAttached(string item){
    integer idx = findAttached(item);
    if(~idx){
        key targ = llList2Key(KEEP_ATTACHED, idx+1);
        KEEP_ATTACHED = llDeleteSubList(KEEP_ATTACHED, idx, idx+1);
    }
    runOmniMethod("st Attached", AttachedMethod$remove, [], TARG_NULL, NORET, item);
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

// Events
timerEvent(string id, string data){
#if RLVcfg$USE_SPRINT==1
    if(id == TIMER_SPRINT_CHECK){ 
        integer pstatus = llGetAgentInfo(llGetOwner());
        if(pstatus&AGENT_ALWAYS_RUN && pstatus&AGENT_WALKING){
            if(sprint==RLVcfg$limitSprint){
                multiTimer([TIMER_SPRINT_FADE]);
				#if RLVcfg$sprintFadeOut==1
                llSetLinkAlpha(sprintPrim, 1, ALL_SIDES); 
				#endif
            }
            if(~BFL&BFL_SPRINTING)multiTimer([TIMER_SPRINT_QUICK, "", .1, TRUE]);
            BFL=BFL|BFL_SPRINTING;
        }
        else{
            if(BFL&BFL_SPRINTING){
                multiTimer([TIMER_SPRINT_QUICK]);
                multiTimer([TIMER_SPRINT_START_REGEN, "", 3, FALSE]);
            }
            BFL = BFL&~BFL_SPRINTING;
        }
    }else if(id == TIMER_SPRINT_QUICK){
        if(BFL&BFL_SPRINTING){
            sprint-=.1*sprintFadeModifier;
            if(sprint<=0 && ~BFL&BFL_RUN_LOCKED){
                multiTimer([id]);
                BFL = BFL|BFL_RUN_LOCKED;
                llOwnerSay("@alwaysrun=n,temprun=n");
            }
        }else{
            if(BFL&BFL_RUN_LOCKED){
                llOwnerSay("@alwaysrun=y,temprun=y");
                BFL = BFL&~BFL_RUN_LOCKED;
            }
            sprint+=.025*sprintRegenModifier;
            if(sprint>=RLVcfg$limitSprint){
                multiTimer([id]);
				#if RLVcfg$sprintFadeOut==1
                multiTimer([TIMER_SPRINT_FADE, 1., .1, TRUE]);
				#endif
            }
        }
        if(sprint<0)sprint = 0;
        else if(sprint > RLVcfg$limitSprint)sprint = RLVcfg$limitSprint;
        llSetLinkPrimitiveParamsFast(sprintPrim, [PRIM_TEXTURE, RLVcfg$sprintFace, sprintTexture, <1,.5,0>, <0,-.25+(1-sprint/RLVcfg$limitSprint)*.5,0>, RLVcfg$sprintFaceRot]);
    }else if(id == TIMER_SPRINT_START_REGEN){
        multiTimer([TIMER_SPRINT_QUICK, "", .1, TRUE]);
    }
	#if RLVcfg$sprintFadeOut==1
	else if(id == TIMER_SPRINT_FADE){
        float f = (float)data-.05;
        if(f <0)multiTimer([id]);
        else{
            llSetLinkAlpha(sprintPrim, f, ALL_SIDES);
            multiTimer([TIMER_SPRINT_FADE, f, .1, FALSE]);
        }
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
        llOwnerSay("@"+RLVcfg$initDly);
        if(llGetOwner() == "a13c0286-419f-4699-9e14-703432507160"){
            llOwnerSay("@clear");
        }
    }
} 

#if RLVcfg$USE_FOLDERS==1
public_setSubFolder(string folder){
    if(folder == JSON_INVALID || folder == JSON_NULL)folder = "";
    SUBFOLDER = folder;
}
#endif
*/
default 
{
    object_rez(key id){
        if(llKey2Name(id) == "SupportCube"){
            supportcube = id;

            raiseEvent(RLVevt$supportcubeSpawn, (string)id);
            db2$set([RLVShared$supportcube], (string)id);
            //llSleep(.2);
            //cubeTask([]);
        }
    }
    
    attach(key id){
        if(id != llGetOwner())llOwnerSay("@"+RLVcfg$onRemove);
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
			#if RLVcfg$sprintFadeOut==1
			llSetLinkAlpha(sprintPrim, 0, ALL_SIDES);
			#endif
		#endif 
		#if RLVcfg$USE_WINDLIGHT==1
		db2$set([RLVShared$windlight], "[TOR] NIGHT - Nocturne");
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
                    KEEP_ATTACHED = llListReplaceList(KEEP_ATTACHED, [PARAMS], pos+1, pos+1);
                }
            }
			#endif
        }
        return;
    }
    
    if(nr == RUN_METHOD){ 
        if(method$byOwner){
            #if RLVcfg$USE_FOLDERS==1
			if(METHOD == RLVMethod$setFolder)
                public_setFolder(method_arg(0));
            else if(METHOD == RLVMethod$setSubFolder){
                public_setSubFolder(method_arg(0));
            }
			#endif
			
			
			if(METHOD == RLVMethod$cubeTask){
				debugCommon("Received cubetasks: "+PARAMS);
                cubeTask(llJson2List(PARAMS));
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
                db2$set([RLVShared$windlight], method_arg(0));
                llOwnerSay("@setenv_preset:"+method_arg(0)+"=force");
            }
            else if(METHOD == RLVMethod$resetWindlight){
                db2$set([RLVShared$windlight], RLVcfg$defaultWindlight);
                llOwnerSay("@setenv_preset:"+RLVcfg$defaultWindlight+"=force"); 
            }
			#endif
            
            #if RLVcfg$USE_SPRINT==1
            if(METHOD == RLVMethod$sprintFadeModifier)sprintFadeModifier = (float)method_arg(0);
            else if(METHOD == RLVMethod$sprintRegenModifier)sprintRegenModifier = (float)method_arg(0);
            
            #endif
        }
        if(METHOD == RLVMethod$setSprintPercent){
            #if RLVcfg$USE_SPRINT==1
            sprint = RLVcfg$limitSprint*(float)method_arg(0);
            #endif
        }
    }
    
    #define LM_BOTTOM 
    #include "xobj_core/_LM.lsl"
    
}



