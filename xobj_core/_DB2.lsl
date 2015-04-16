list DB2_CACHE;

#ifndef db2$prefix
#define db2$prefix "DB"
#endif

#define db2$rootSend() llMessageLinked(LINK_THIS, DB2_UPDATE, mkarr(DB2_CACHE), "")
#define db2$get(script, sub) db2(DB2$GET, script, sub, "")
#define db2$set(sub, val) db2(DB2$SET, llGetScriptName(), sub, val)
#define DB2$get(script, sub) db2$get(script, sub)
#define DB2$set(sub, val) db2$set(sub, val)

#define DB2_NAME 0
#define DB2_PRIM 1
#define DB2_FACE 2

#define DB2$GET 0
#define DB2$SET 1
string db2(integer task, string script, list sub, string val){
	integer pos = llListFindList(DB2_CACHE, [script]); 
	string dta = (string)llGetLinkMedia(llList2Integer(DB2_CACHE, pos+1), llList2Integer(DB2_CACHE, pos+2), [PRIM_MEDIA_HOME_URL, PRIM_MEDIA_CURRENT_URL]);
	if(task == DB2$GET){
		if(pos==-1)return "";
		return jVal(dta, sub);
	}
	string set = llJsonSetValue(dta,sub,val);
	// Create new
	if(pos==-1)
		llMessageLinked(LINK_ROOT, DB2_ADD, mkarr(([llGetScriptName(), mkarr(sub), val])), "");
	else{
		debug("Saving instantly onto "+llGetLinkName(llList2Integer(DB2_CACHE, pos+1))+" face: "+llList2String(DB2_CACHE, pos+2));
		llSetLinkMedia(llList2Integer(DB2_CACHE, pos+1), llList2Integer(DB2_CACHE, pos+2), [PRIM_MEDIA_HOME_URL, llGetSubString(set,0,1023), PRIM_MEDIA_CURRENT_URL, llGetSubString(set,1024,2047), PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_NONE, PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_NONE]);
	}
	return "1";
}

clearDB2(){
	links_each(ln, n, {
		if(llGetSubString(db2$prefix,0,llStringLength(db2$prefix)-1) == llGetSubString(n,0,llStringLength(db2$prefix)-1)){
			integer i;
			for(i=0; i<llGetNumberOfSides(); i++)llClearLinkMedia(ln, i);
		}
	})
}

