// Include this class basic definition file
//#include "xobj_core/classes/class SharedVars.lsl"
// Note: SharedVars is a required class for xobj to work  

#warning Old shared vars are deprecated.
// Static : These are non preprocessor definitions that should not be shared with other scripts
list DB_CACHE;  // Contains linknums of databases


// Include the general class functionality - Make a full include to grab any private stuff
#include "xobj_core/classes/cl SharedVars.lsl"
#include "xobj_core/_CLASS_PACKAGE.lsl" 


                                // Methods
// Note: The code makes no distinction between public/private/static. The categories are just to keep your code easier to read 


                                // Built-in
integer __construct(list args){  // name
    string n = fn_arg(0);    
    list pdata = private_getPrim(n, FALSE);
    if(pdata != [])return FALSE;
    
    list taken; 
    cls$each(index, obj, {
        taken+=(integer)(llJsonGetValue(obj, [SharedVarsVar$prim])+llJsonGetValue(obj, [SharedVarsVar$face]));
    });
    
    for(index = 0; index<llGetListLength(DB_CACHE); index++){
        integer i;
        for(i=0; i<9; i++){
            integer num = (integer)(llList2String(DB_CACHE,index)+(string)i);
            if(llListFindList(taken, [num]) == -1){
                list obj = [
                    SharedVarsVar$scriptName, n,
                    SharedVarsVar$prim, llList2Integer(DB_CACHE,index),
                    SharedVarsVar$face, i 
                ];
                cls$push(obj);
                return TRUE; 
            }   
        }
    }
    llOwnerSay("Error: Database full.");
    return FALSE; 
}

__indexed(){
    // Store index
    list out;
    list_each(_INDEX_VARS, k, v, {
        out+=([v, llList2String(_INDEX, k)]);
    }); 
    public_set(cls$name, [], llList2Json(JSON_OBJECT, out));
}


indexByName(string name){
	cls$each(nr, obj, {
		if(jVal(obj, [SharedVarsVar$scriptName]) == name){
			cls$setIndex(nr);
			return;
		}
	})
	cls$clear();
}

                             // Public
public_set(string script, list index, string data){
    list primData = private_getPrim(script, TRUE);  
    string cur = _shared(script, []);
    if(llStringLength(cur) <=1)cur = "{}";

    cur = llJsonSetValue(cur, index, data);
    string two;
    if(llStringLength(cur)>1024){
        two = llGetSubString(cur, 0, 1023);
        cur = llDeleteSubString(cur, 0, 1023);
    }
    
	if(data == "" && index == []){
		indexByName(script);
		if(cls$index != -1){
			this$replace([]);
		}
		llClearLinkMedia(llList2Integer(primData, 0), llList2Integer(primData, 1));
		return;
	}
    llSetLinkMedia(llList2Integer(primData, 0), llList2Integer(primData,1), [PRIM_MEDIA_HOME_URL, cur, PRIM_MEDIA_CURRENT_URL, two, PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_NONE, PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_NONE]);
	
	#if SharedVarsConf$preventEvent!=1
	raiseEvent(SharedVarsEvt$changed, llList2Json(JSON_OBJECT, [ 
		#ifdef SharedVarsEvt$includeData
        "o", llJsonGetValue(cur, index),
        "n", data,
		#endif
        "v", llList2Json(JSON_ARRAY, index),
        "s", script
    ]));
    #endif
}



                                        // Private
// These methods should work on the current object, but not be accessable from outside this script

// Returns [(int)prim, (int)face]
list private_getPrim(string script, integer prep){ 
    
    cls$each(index, obj, 
        if(llJsonGetValue(obj, [SharedVarsVar$scriptName]) == script){
            return [(integer)llJsonGetValue(obj, [SharedVarsVar$prim])]+ 
                (integer)llJsonGetValue(obj, [SharedVarsVar$face]);
        }
    ); 
    if(prep){
        __add([script]);
        return private_getPrim(script, FALSE);
    }
    return [];
}


default
{

    state_entry()
    {
        // ALWAYS init shared vars - Made this way to speed things up
        initShared();
        
		list dbc = [];
        links_each(id, ln, {
            if(llGetSubString(ln,0,1) == "DB"){
                dbc+=([(integer)llGetSubString(ln,2,-1), id]);
                integer i;
                for(i=0; i<9; i++)llClearLinkMedia(id, i);
            }
        });
		dbc = llListSort(dbc, 2, TRUE);
		DB_CACHE= llList2ListStrided(llDeleteSubList(dbc,0,0), 0, -1, 2);
		
        __add([llGetScriptName()]);
		raiseEvent(evt$SCRIPT_INIT, "");
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
    
    if(nr == RUN_METHOD){
        if(METHOD == SharedVarsMethod$SET){
            public_set(
                SENDER_SCRIPT, 
                llJson2List(llJsonGetValue(PARAMS, [0])),
                llJsonGetValue(PARAMS, [1]) 
            );
        }else if(METHOD == SharedVarsMethod$otherSet){
			public_set(
                method_arg(0), 
                llJson2List(method_arg(1)),
                method_arg(2) 
            );
		}
    }
        
    else if(nr == METHOD_CALLBACK){
        
    }
    
    #define LM_BOTTOM 
    #include "xobj_core/_LM.lsl"
}


