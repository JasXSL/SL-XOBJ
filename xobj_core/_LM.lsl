// You shouldn't need to bother with this script
// If you came here looking for info on how to add the standard com system. Here's a template:
/*

#include "xobj_core/_LM.lsl" 

//    Included in all these calls:
//    METHOD - (int)method
//    INDEX - (int)obj_index
//    PARAMS - (var)parameters
//    SENDER_SCRIPT - (var)parameters
//    CB - The callback you specified when you sent a task
//    CB_DATA - Array of params to return in a callback
//    id - (key)method_raiser_uuid

    
if(method$isCallback){
    // Received a callback
	
    return;
}
// Received a method call

   
#define LM_BOTTOM  
#include "xobj_core/_LM.lsl"

You can use LM_PRE to inject code at the top of link_message


*/

#ifndef LM_BOTTOM
// Top goes here
link_message(integer link, integer nr, string str, key id){
	//if(llGetScriptName() == "dnp Status")
	//qd("("+llGetScriptName()+") "+(string)nr+" :: "+str+" :: "+(string)id);
	
	#ifdef LM_PRE
	LM_PRE
	#endif

	#ifdef USE_HOTTASKS
	if(nr == 0 && (string)id == llGetScriptName()){
		list dta = llJson2List(str);
		onHotTask(llList2String(dta,0), llDeleteSubList(dta,0,0));
	}
	#else
	if(nr >= 0){return;}
	#endif

	#ifdef SCRIPT_IS_ROOT
	else if(nr == DB2_ADD){
		string sender = jVal(str, [0]);
		string script = jVal(str, [1]);
		debugCommon("Shared Save request received @ root from script "+script);
		if(llListFindList(DB2_CACHE, [script]) == -1){
			list prims; // Prim IDS
			list idx;	// Prim NR
			links_each(ln, n, 
				if(llGetSubString(db2$prefix,0,llStringLength(db2$prefix)-1) == llGetSubString(n,0,llStringLength(db2$prefix)-1)){
					prims+=ln;
					idx += (integer)llGetSubString(n,llStringLength(db2$prefix), -1);
				}	
			)
			integer i; list flat;
			for(i=0; i<llGetListLength(idx); i++)flat += 0;
			
			for(i=0; i<llGetListLength(idx); i++)flat = llListReplaceList(flat, llList2List(prims,i,i), llList2Integer(idx,i),llList2Integer(idx,i));
			if(llList2Integer(flat,0) == 0)flat = llDeleteSubList(flat,0,0);
			// DB can start with 0 or 1
			for(i=0; i<llGetListLength(flat); i++){
				integer x;
				for(x=0; x<9; x++){
					if(llListFindList(DB2_CACHE, [llList2Integer(flat,i), x]) == -1){
						DB2_CACHE += [script, llList2Integer(flat,i), x];
						list l = llJson2List(jVal(str, [2]));
						if(isset(jVal(str, [3])) || l != []){
							// Newly added, save data
							debugUncommon("SETTING NEW DATA @ root for script "+script+" at prim "+llList2String(flat, i)+" face "+(string)x);
							db2$rootSend();
							db2(DB2$SET, script, l, jVal(str, [3]));
							sendCallback(id, sender, stdMethod$setShared, mkarr(([script, jVal(str,[2])])), jVal(str, [4]));
						}
						return;
					}
				}
			}
			debugRare("FATAL ERROR: Not enough DB prims to store this many shared items.");
			
		}else{
			db2$rootSend();
			db2(DB2$SET, script, llJson2List(jVal(str, [2])), jVal(str, [3]));
			sendCallback(id, sender, stdMethod$setShared, mkarr(([script, jVal(str,[2])])), jVal(str, [4]));
		}
		
	}else if(nr == DB2_DELETE){
		integer pos = llListFindList(DB2_CACHE, [str]);
		debugUncommon("Deleting shared: "+str+" @ pos: "+(string)pos);
		if(~pos){
			DB2_CACHE = llDeleteSubList(DB2_CACHE, pos, pos+2);
			db2$rootSend();
		}
	}
	#else 
		#ifdef USE_SHARED
	else if(nr == DB2_UPDATE){
			debugCommon("DB2 Update");
			list data = llJson2List(str);
			list d = USE_SHARED; DB2_CACHE = [];
			
			if((string)d == "*"){
				DB2_CACHE = data;
				return;
			}
			debugCommon("Cycling shared: "+mkarr(d));
			list_shift_each(d, v, 
				integer pos = llListFindList(data, [v]);
				if(~pos)DB2_CACHE += llList2List(data, pos, pos+2);
			)
			return;
		}
		#endif
	#endif
	else if(nr==RUN_METHOD || nr == METHOD_CALLBACK){
		list CB_DATA;
		string CB = JSON_NULL;
		integer s_LEN = llStringLength(llGetScriptName());
		// Make sure this script is the receiver
		if(llGetSubString(str,0,s_LEN-1) != llGetScriptName())return;
		
		
		list s_DATA = llJson2List(llGetSubString(str, s_LEN, -1));
		integer METHOD = llList2Integer(s_DATA, 0);
		
		string PARAMS = llList2String(s_DATA, 1);
		string SENDER_SCRIPT = llList2String(s_DATA, 2);
		CB = llList2String(s_DATA, 3);
		s_DATA = [];
		
		
#else
		// Bottom goes here
		
		if(CB != "" && !(method$isCallback)){
			debugCommon("Sending callback. CB is: "+CB+" DATA: "+llList2Json(JSON_ARRAY, CB_DATA)+" and targ is: "+(string)llKey2Name(id));
			sendCallback(id, SENDER_SCRIPT, METHOD, llList2Json(JSON_ARRAY, CB_DATA), CB);
		}
		
	}else if(nr == RESET_ALL && str != llGetScriptName()){
		llResetScript();
	}
	#ifdef USE_EVENTS
	else if(nr == EVT_RAISED){
		#ifdef EVENTS_NOT_SELF
		if(llGetSubString(str, 2, llStringLength(llGetScriptName())+1) == llGetScriptName())return;
		#endif
		string scr = llJsonGetValue(str, [0]);
		integer evt = (integer)((string)id);
		#ifdef USE_LEGACY_DB
			#ifndef DISREGARD_SHARED
			if(SHARED_CACHE_ROOT == 0){
				initShared();
			}
			#endif
		#endif
		onEvt(scr, evt, llJsonGetValue(str, [1]));
		
	}
	#endif
	
}
#endif







