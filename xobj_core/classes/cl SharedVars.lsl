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
#define SharedVarsEvt$changed 0		// Raised when shared var is changed {o:(var)oldData, n:(var)newData, v:(arr)index, s:(str)script}					

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
#define evt$eventIsSharedScriptChange(sc) (script == "cl SharedVars" && evt == evt$SHARED_CHANGED && jVal(data, ["s"]) == sc)


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
