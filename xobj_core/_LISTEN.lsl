/*
	This is the listen manager for standard communications.
	In your CORE file you'll want to modify the getToken(key senderKey, key recipient, string saltrand) function
	It generates a hash specific to your project. You can replace it with any algorithm you want to help make your game more secure.
	
	Don't forget to run initiateListen() wherever you want to initiate the listener (usually state_entry)
	The following are definitions you can define right above your #include "xobj_core/_LISTEN.lsl"
	
	#define REQUIRE_INIT - Will not raise events until BFL_INIT is set
	#define ALLOW_USER_DEBUG 2=anyone - Lets anyone/owner raise events by saying debug script, method, arg1, arg2...
	#define ALLOW_USER_DEBUG_KEY (key)id - Limit to a specific key
	#define LISTEN_LIMIT_FREETEXT - Lets you define freetext code to be injected into _LISTEN
	
*/

// Special cases that removes the listener event if you need to set it up yourself
#ifndef LISTEN_IGNORE_EVENT
listen(integer chan, string name, key id, string message){
#endif
	//debugCommon("COM received:\n"+message);
	
	#ifdef LISTEN_LIMIT_FREETEXT
	LISTEN_LIMIT_FREETEXT
	#endif
	
	#ifdef REQUIRE_INIT
	if(~BFL&BFL_INIT)
		return;
	#endif
	
	#ifdef ALLOW_USER_DEBUG
    if(chan == 0){
		#ifdef ALLOW_USER_DEBUG_KEY
		if(llGetOwnerKey(id) != ALLOW_USER_DEBUG_KEY)return;
		#endif
		#if ALLOW_USER_DEBUG != 2
		if(llGetOwnerKey(id) != llGetOwner())return;
		#endif
        if(llGetSubString(message, 0, 5) == "debug " || llGetSubString(message, 0, 6) == "debugj "){ // script, method, param1, param2...
			list split = llCSV2List(llGetSubString(message, 6, -1));
			int task = l2i(split, 1);
			string script = l2s(split, 0);
			split = llDeleteSubList(split, 0, 1);
            if( llGetSubString(message, 0, 6) == "debugj " )
				split = llJson2List(implode(",", split));
			list op = [task, llList2Json(JSON_ARRAY, split), ""];
			
            llMessageLinked(LINK_SET, RUN_METHOD, script+llList2Json(JSON_ARRAY, op), id);
        }
        return;
    }
	#endif
	
	#ifndef DISREGARD_TOKEN
	string expected = getToken(id, llGetOwner(), llGetSubString(message,0,15));
	if(llGetSubString(message, 0, llStringLength(expected)-1) != getToken(id, llGetOwner(), llGetSubString(message,0,15))){
		debugUncommon("Token rejected, call: "+message+" expected "+expected);
		return;
    } 
	message = llDeleteSubString(message, 0,llStringLength(expected)-1);
	#endif
	
	
	debugCommon("COM passed: "+llGetSubString(message, llSubStringIndex(message, ":")+1, -1));
	//qd("COM passed: "+llGetSubString(message, llSubStringIndex(message, ":")+1, -1));
	
	//integer targ = LINK_SET;
	llMessageLinked(LINK_SET, (integer)llGetSubString(message, 0,llSubStringIndex(message, ":")-1), llGetSubString(message, llSubStringIndex(message, ":")+1, -1), id);
	//qd("Sent com");
#ifndef LISTEN_IGNORE_EVENT
}
#endif
