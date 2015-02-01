/*
	
	SharedVars is always included in xobj.
	It's a package module that lets you share variables for other scripts to read.
	Note that lag might affect getting the most recent data, so if you absolutely need to be sure that a script has proper data from another script, check for the SharedVarsEvt$changed event.
	
	Usage:
	Save a shared var bound to your script: _saveShared((list)index, (string)data);
	Read a shared var from another script: _shared((string)script, (list)index);
	Remove all shared vars in your script: _saveShared([], "");
	
	Check if an event is a shared var changed event:
	evt$eventIsSharedScriptChange((string)scriptToCheckForChanges)
	
	If you do not wish a script to utilize shared vars (saves a few bytes of memory) add #define DISREGARD_SHARED at the top of the script
	
*/

// Event raised when a shared var has changed.
// Quote it out if you do not wish it to raise an event (not recommended)
#ifndef SharedVarsConf$preventEvent
	#define SharedVarsConf$preventEvent 0
#endif
//#define SharedVarsEvt$includeData 1	// adds: o:(var)oldData, n:(var)newData to the above call. WARNING memory intensive

// Event raised when data is changed unless SharedVarsConf$preventEvent is 1
#define SharedVarsEvt$changed 0		// Raised when shared var is changed {v:(arr)index, s:(str)script}

// Methods
#define SharedVarsMethod$SET 0      // (list)index, (var)data - Script name is auto-fetched
#define SharedVarsMethod$otherSet 1 // (str)script, (list)index, (var)data - Use a custom script name

// Object member vars
#define SharedVarsVar$scriptName "A"
#define SharedVarsVar$prim "B"
#define SharedVarsVar$face "C"


#ifndef SharedVarsConst$dbPrimPrefix
	#define SharedVarsConst$dbPrimPrefix "DB"    // Prefix of the name of the prim you wish to use as DB
#endif                                        // Suffix is numerical so name your prims like. DB0, DB1...



// Default indexes
#ifndef INDEXES 
	#define INDEXES [SharedVarsVar$scriptName, SharedVarsVar$prim, SharedVarsVar$face]
#endif

// Needs to be in the head of every script
integer _SHARED_CACHE_ROOT;     // Contains cache included into the head of every script

#ifndef initShared
	#ifndef DISREGARD_SHARED
	#define initShared() links_each(prim, ln, {if(llGetSubString(ln,0,llStringLength(SharedVarsConst$dbPrimPrefix)-1)==SharedVarsConst$dbPrimPrefix && llGetSubString(ln,-1,-1) == "0")_SHARED_CACHE_ROOT = prim;})
	#else
	#define initShared() 
	#endif
#endif


#define _saveShared(index, val) runMethod((string)LINK_ROOT, "cl SharedVars", SharedVarsMethod$SET, [llList2Json(JSON_ARRAY, index), val], TNN);
#define _saveSharedScript(script, index, val) runMethod((string)LINK_ROOT, "cl SharedVars", SharedVarsMethod$otherSet, [script, llList2Json(JSON_ARRAY, index), val], TNN);
#define _shared(script, index) getSharedVar(script, index)
#define evt$eventIsSharedScriptChange(sc) (script == "cl SharedVars" && evt == SharedVarsEvt$changed && jVal(data, ["s"]) == sc)

// Only use this for a script to set it's own variables when inter-script synchronisity is REQUIRED
// It will cost a lot more script memory, generally cost more script time and not fire events
// It will not be able to spawn new tables either. So only use it if you are CERTAIN your script has been assigned a
// Prim and face from cl SharedVars. You can do this by _saveShared with a non-null value
// This will not unset data either
_saveSharedOverride(string script, list index, string data){
	string indexes = (string)llGetLinkMedia(_SHARED_CACHE_ROOT, 0, [PRIM_MEDIA_HOME_URL, PRIM_MEDIA_CURRENT_URL]);
	list names = llJson2List(llJsonGetValue(indexes, [SharedVarsVar$scriptName]));
    integer pos = llListFindList(names,[script]);
	if(~pos){
		integer prim = (integer)llJsonGetValue(indexes, [SharedVarsVar$prim, pos]);
		integer face = (integer)llJsonGetValue(indexes, [SharedVarsVar$face, pos]);
		string out = llJsonSetValue((string)llGetLinkMedia(
            prim, 
            face, 
            [PRIM_MEDIA_HOME_URL, PRIM_MEDIA_CURRENT_URL]
        ), index, data);
		llSetLinkMedia(prim, face, [PRIM_MEDIA_HOME_URL, llGetSubString(out,0,1023), PRIM_MEDIA_CURRENT_URL, llGetSubString(out,1024,2047), PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_NONE, PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_NONE]);
    }else llOwnerSay("UNABLE TO SAVE OVERRIDE. "+script+" NOT SET.");
}

string getSharedVar(string script, list index){
    string indexes = (string)llGetLinkMedia(_SHARED_CACHE_ROOT, 0, [PRIM_MEDIA_HOME_URL, PRIM_MEDIA_CURRENT_URL]);
	list names = llJson2List(llJsonGetValue(indexes, [SharedVarsVar$scriptName]));
    integer pos = llListFindList(names,[script]);
	if(~pos){
		string dta = (string)llGetLinkMedia(
            (integer)llJsonGetValue(indexes, [SharedVarsVar$prim, pos]), 
            (integer)llJsonGetValue(indexes, [SharedVarsVar$face, pos]), 
            [PRIM_MEDIA_HOME_URL, PRIM_MEDIA_CURRENT_URL]
        );
        return llJsonGetValue(dta, index);
    }
    return "";
}
