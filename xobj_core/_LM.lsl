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
link_message(integer link, integer nr, string s, key id){
	//if(llGetScriptName() == "dnp Status")
	//qd("("+llGetScriptName()+") "+(string)nr+" :: "+str+" :: "+(string)id);
	
	#ifdef LM_PRE
	LM_PRE
	#endif

	// HOTTASKS
	#ifdef USE_HOTTASKS
	if(nr == 0 && (string)id == llGetScriptName()){
		list dta = llJson2List(s);
		onHotTask(llList2String(dta,0), llDeleteSubList(dta,0,0));
	}
	#else
	if(nr >= 0){return;}
	#endif
	
	
#ifdef USE_DB2
	// DB2 legacy block - ROOT only
	#ifdef SCRIPT_IS_ROOT
	else if(nr == DB2_ADD){
		string sender = jVal(s, [0]);
		string script = jVal(s, [1]);
		if(llListFindList(DB2_CACHE, [script]) == -1){
			list prims; // Prim IDS
			list idx;	// Prim NR
			links_each(ln, n, 
				if(llGetSubString(db2$prefix,0,llStringLength(db2$prefix)-1) == llGetSubString(n,0,llStringLength(db2$prefix)-1)){
					prims+=ln;
					idx += (integer)llGetSubString(n,llStringLength(db2$prefix), -1);
				}	
			)
			integer i; list flat; // Flat is a list of prim IDs
			for(i=0; i<llGetListLength(idx); i++)flat += 0;
			for(i=0; i<llGetListLength(idx); i++)flat = llListReplaceList(flat, llList2List(prims,i,i), llList2Integer(idx,i),llList2Integer(idx,i));

			// DB now HAS to start with 0
			for(i=0; i<llGetListLength(flat); i++){
				integer x;
				for(x=0; x<9; x++){
					if(llListFindList(DB2_CACHE, [llList2Integer(flat,i), x]) == -1){
						DB2_CACHE += [script, llList2Integer(flat,i), x];
						list l = llJson2List(jVal(s, [2]));
						if(isset(jVal(s, [3])) || l != []){
							// Newly added, save data
							debugUncommon("SETTING NEW DATA @ root for script "+script+" at prim "+llList2String(flat, i)+" face "+(string)x);
							db2$rootSend();
							db2(DB2$SET, script, l, jVal(s, [3]));
							
							sendCallback(id, sender, stdMethod$setShared, mkarr(([script, jVal(s,[2])])), jVal(s, [4]));
						}
						#ifdef DB2_PRESERVE_ON_RESET

						if(llGetListLength(DB2_CACHE)/DB2$STRIDE <2){debugRare("Fatal error: if DB2_PRESERVE_ON_RESET is set, you must call db2$ini(); before trying to store data")}
						else db2(DB2$SET, "_INDEX_", [], mkarr(DB2_CACHE));
						
						#endif
						return;
					}
				}
			}
			debugRare("FATAL ERROR: Not enough DB prims to store this many shared items.")
			
		}else{
			db2$rootSend();
			db2(DB2$SET, script, llJson2List(jVal(s, [2])), jVal(s, [3]));
			sendCallback(id, sender, stdMethod$setShared, mkarr(([script, jVal(s,[2])])), jVal(s, [4]));
		}
		
	}else if(nr == DB2_DELETE){
		integer pos = llListFindList(DB2_CACHE, [s]);
		debugUncommon("Deleting shared: "+s+" @ pos: "+(string)pos);
		if(~pos){
			DB2_CACHE = llDeleteSubList(DB2_CACHE, pos, pos+2);
			db2$rootSend();
		}
	}else if(nr == DB2_REFRESHME){
		db2$rootSend();
		sendCallback(id, s, stdMethod$setShared, "[]", "");
	}
	// DB2 non-root
	#else 
		#ifdef USE_SHARED
	else if(nr == DB2_UPDATE){
			debugCommon("DB2 Update");
			list data = llJson2List(s);
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
#else
// DB2 legacy block end, DB3 start
	#ifdef SCRIPT_IS_ROOT
	else if(nr == DB3_ADD){
	// index all existing tables
	string sender = j(s, 0);
	list _to_create = llJson2List(j(s,1));
	list _index_tables;		// Names of tables
	list _index_db;			// [(int)db_nr, (int)prim, (int)occupied_faces]
	integer _i; integer nr;
	for(nr = 1; nr<=llGetNumberOfPrims(); nr++){
		string name = llGetLinkName(nr);
		if(llGetSubString(name, 0, 1) == "DB"){
			_index_db += [(int)llGetSubString(name, 2, -1), nr];
			integer _occupied; // Bitwise combination
			for(_i = 0; _i <llGetLinkNumberOfSides(nr); _i++){
				string _data = llList2String(llGetLinkMedia(nr, _i, [PRIM_MEDIA_HOME_URL]),0); // Only need home URL since names are limited
				string name = llGetSubString(_data, 0, llSubStringIndex(_data, "|")-1);
				// Occupied face
				if(name != "" && llListFindList(_index_tables, [name]) == -1){ 
					_index_tables += name;
					_occupied = _occupied | (int)llPow(2, _i);
				}
			}
			_index_db += _occupied;
		}
	}
	
	_index_db = llListSort(_index_db, 3, TRUE);
	for(_i = 0; _i<count(_to_create); _i++){
		string _tbl = llGetSubString(llList2String(_to_create, _i),0,29);
		if(llListFindList(_index_tables,[_tbl]) == -1){
			// We need to add a new table
			integer _x;
			// Cycle over DB prims
			for(_x = 0; _x<count(_index_db); _x+=3){
				integer _occupied = llList2Integer(_index_db, _x+2);
				integer _prim = llList2Integer(_index_db, _x+1);
				integer _y;
				for(_y = 0; _y<llGetLinkNumberOfSides(_prim); _y++){
					integer _n = (int)llPow(2, _y);
					if(~_occupied & _n){
						llSetLinkMedia(_prim, _y, [PRIM_MEDIA_HOME_URL, _tbl+"|[]"]);
						_index_db = llListReplaceList(_index_db, [_occupied|_n], _x+2, _x+2);
						// Continue adding tables
						jump _db4_add_continue;
					}
				}
			}
			llOwnerSay("FATAL ERROR: Not enough DB sides for DB3.");
			return;
			@_db4_add_continue;
		}
	}
	
	sendCallback(id, sender, stdMethod$setShared, mkarr(_to_create), "");
	}
	#endif
#endif
	
	// Run method
	else if(nr==RUN_METHOD || nr == METHOD_CALLBACK){
		list CB_DATA;
		string CB = JSON_NULL;
		
		string _mname = llGetScriptName();
		int _mnl = llStringLength(_mname);
		// Make sure this script is the receiver
		#ifndef SCRIPT_ALIASES 
		if(
			llGetSubString(s,0,_mnl) != _mname+"["
			#ifdef SCRIPT_IS_ROOT
				&& llGetSubString(s,0,8) != "__ROOTS__"
			#endif
		){
			return;
		}
		#else
		list l = SCRIPT_ALIASES+_mname;
		string _n = llGetSubString(s, 0, llSubStringIndex(s, "[")-1);
		if(llListFindList(l, [_n]) == -1)return;
		_mnl = llStringLength(_n);
		#endif
		
		
		// 
		list _s_DATA = llJson2List(llGetSubString(s, _mnl, -1));
		integer METHOD = llList2Integer(_s_DATA, 0);
		list PARAMS = llJson2List(llList2String(_s_DATA, 1));
		string SENDER_SCRIPT = llList2String(_s_DATA, 2);
		CB = llList2String(_s_DATA, 3);
		_s_DATA = [];
		
#else
		// Bottom goes here
		if(isset(CB) && !(method$isCallback)){
			sendCallback(id, SENDER_SCRIPT, METHOD, llList2Json(JSON_ARRAY, CB_DATA), CB)
		}
	}else if(nr == RESET_ALL && s != llGetScriptName()){
		llResetScript();
	}
	#ifdef USE_EVENTS
	else if(nr == EVT_RAISED){
		list dta = llJson2List(s);
		onEvt(llList2String(dta,0), (int)((str)id), llJson2List(llList2String(dta,1)));
	}
	#endif
	
}
#endif







