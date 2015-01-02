

#ifndef LM_BOTTOM
// Top goes here
link_message(integer link, integer nr, string str, key id){
	if(nr==RUN_METHOD || nr == METHOD_CALLBACK){
		list CB_DATA;
		
		string CB = JSON_NULL;
	
		// Make sure this script is the receiver
		integer s_LEN = llStringLength(llGetScriptName());
		if(llGetSubString(str,0,s_LEN-1) != llGetScriptName())return;
		
		
		list s_DATA = llJson2List(llGetSubString(str, s_LEN, -1));
		integer METHOD = llList2Integer(s_DATA, 0);
		
		string SEARCH = llList2String(s_DATA, 1); 	// Searchstring
		string IN = llList2String(s_DATA, 2);	// Property
		
		#ifdef SCRIPT_IS_PACKAGE
		list WORK_OBJS = __search(SEARCH, IN);
		if(nr == METHOD_CALLBACK)WORK_OBJS = [];
		#endif
		string PARAMS = llList2String(s_DATA, 3);
		string SENDER_SCRIPT = llList2String(s_DATA, 4);
		if(llGetListLength(s_DATA)>4){
			CB = llList2String(s_DATA, 5);
		}
		s_DATA = [];
	#ifdef SCRIPT_IS_PACKAGE
		while(llGetListLength(WORK_OBJS)){
			cls$setIndex(llList2Integer(WORK_OBJS, 0));
			WORK_OBJS = llDeleteSubList(WORK_OBJS, 0, 0);
			
			// StdMethods
			if(METHOD == stdMethod$remove){
				if(!UNINITIALIZED){ 
					this$remove();
					CB_DATA= llListReplaceList(CB_DATA, [llList2Integer(CB_DATA,0)+1], 0, 0);
					#ifdef DEBUG
					llOwnerSay("Removed an object, remaining: "+llDumpList2String(_OBJECTS, "\n"));
					#endif
				}
			}else{

	#endif

#else
			// Bottom goes here
	#ifdef SCRIPT_IS_PACKAGE
			}
		}
		if(METHOD == stdMethod$insert){
			CB_DATA = [__add(llJson2List(PARAMS))];
		}
	#endif
		
		if(CB != JSON_NULL && CB != "" && !(method$isCallback)){
			#ifdef DEBUG
			llOwnerSay("Sending callback. CB is: "+CB+" DATA: "+llList2Json(JSON_ARRAY, CB_DATA)+" and targ is: "+(string)llKey2Name(id));
			#endif
			sendCallback(id, SENDER_SCRIPT, METHOD, SEARCH, IN, llList2Json(JSON_ARRAY, CB_DATA), CB);
		}
		
	}else if(nr == RESET_ALL && str != llGetScriptName()){
		llResetScript();
	}
	else if(nr == EVT_RAISED){
		#ifndef DISREGARD_EVENTS
			string scr = llJsonGetValue(str, [0]);
			integer evt = (integer)((string)id);
			#ifndef DISREGARD_SHARED
			if(_SHARED_CACHE_ROOT == 0){
				initShared();
			}
			#endif
			onEvt(scr, evt, llJsonGetValue(str, [1]));
		#endif
	}
	
	
}
#endif








