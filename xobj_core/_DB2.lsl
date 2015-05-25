#ifdef SCRIPT_IS_ROOT
#ifndef USE_SHARED
	#define USE_SHARED ["*"]
#endif
#endif


list DB2_CACHE;

#ifndef db2$prefix
#define db2$prefix "DB"
#endif

#define db2$rootSend() llMessageLinked(LINK_SET, DB2_UPDATE, mkarr(DB2_CACHE), "")
#define db2$get(script, sub) db2(DB2$GET, script, sub, "")
#define db2$set(sub, val) db2(DB2$SET, llGetScriptName(), sub, val)
#define db2$setOther(script, sub, val) db2(DB2$SET, script, sub, val)


#define DB2$get(script, sub) db2$get(script, sub)
#define DB2$set(sub, val) db2$set(sub, val)
#define DB2$setOther(script, sub, val) db2$setOther(script, sub, val)

#define DB2_NAME 0
#define DB2_PRIM 1
#define DB2_FACE 2

#define DB2$GET 0
#define DB2$SET 1
string db2(integer task, string script, list sub, string val){
	#ifndef SCRIPT_IS_ROOT
	debugCommon("Data to save: "+val);
	#endif
	integer pos = llListFindList(DB2_CACHE, [script]); 
	string dta = (string)llGetLinkMedia(llList2Integer(DB2_CACHE, pos+1), llList2Integer(DB2_CACHE, pos+2), [PRIM_MEDIA_HOME_URL, PRIM_MEDIA_CURRENT_URL]);
	if(task == DB2$GET){
		if(pos==-1){
			debugRare("Unable to get data. "+script+" not found in "+llList2CSV(DB2_CACHE));
			return "";
		}
		return jVal(dta, sub);
	}
	string set = llJsonSetValue(dta,sub,val);
	if(!isset(val) && sub == []){
		if(pos == -1){
			debugRare("Trying to delete unset shared: "+script);
			return "";
		}
		llClearLinkMedia(llList2Integer(DB2_CACHE, pos+1), llList2Integer(DB2_CACHE, pos+2));
		llMessageLinked(LINK_SET, DB2_DELETE, script, "");
		debugCommon("Deleting shared: "+script);
		return "0";
	}
	// Create new
	if(pos==-1){
		llMessageLinked(LINK_SET, DB2_ADD, mkarr(([llGetScriptName(), script, mkarr(sub), val])), "");
		#ifndef SCRIPT_IS_ROOT
		debugCommon("Saving shared delayed");
		#endif
		return "0";
	}else{
		#ifndef SCRIPT_IS_ROOT
		debugCommon("Saving instantly onto "+llGetLinkName(llList2Integer(DB2_CACHE, pos+1))+" face: "+llList2String(DB2_CACHE, pos+2)+" data: "+val);
		#endif
		llSetLinkMedia(llList2Integer(DB2_CACHE, pos+1), llList2Integer(DB2_CACHE, pos+2), [PRIM_MEDIA_HOME_URL, llGetSubString(set,0,1023), PRIM_MEDIA_CURRENT_URL, llGetSubString(set,1024,2047), PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_NONE, PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_NONE]);
	}
	return "1";
}

#define clearDB2() links_each(ln, n, {if(llGetSubString(db2$prefix,0,llStringLength(db2$prefix)-1) == llGetSubString(n,0,llStringLength(db2$prefix)-1)){integer i;for(i=0; i<llGetLinkNumberOfSides(ln); i++){llClearLinkMedia(ln, i);}}})

