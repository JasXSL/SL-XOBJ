/*
	This is the root file, it ties together xobj core
	Whereas you probably don't want to change anything in this file in particular
	I'll still try to explain what things do
	
*/

#define DEBUG_ALL 100
#define DEBUG_USER 10
#define DEBUG_RARE 20
#define DEBUG_UNCOMMON 30
#define DEBUG_COMMON 40

// For now. USE_DB3 will be preferred unless you specify USE_DB4.
// Later this will be reversed.
#ifndef USE_DB4
	#define USE_DB3 	// use undef if you do not want to use this
#endif

#ifndef DEBUG
	#define qd(text) _dbg(text)
	#define _dbg(text) llOwnerSay(llGetSubString(llList2String(llParseString2List(llGetTimestamp(), ["T"],[]), 1),0,-5)+" "+__SHORTFILE__+" @ "+(string)__LINE__+": "+(string)(text))
	#define debug(text)
	#define debugLv(text, lv)
	#define debugCommon(text)
	#define debugUncommon(text)
	#define debugRare(text)
#else
	#define _dbg(text, level) if(level<=DEBUG){llOwnerSay(llGetSubString(llList2String(llParseString2List(llGetTimestamp(), ["T"],[]), 1),0,-5)+" "+__SHORTFILE__+" @ "+(string)__LINE__+": "+(string)(text));}
	#define qd(text) _dbg(text, 0)
	#define debugLv(text, lv) _dbg(text, lv)
	#define debugRare(text) _dbg(text, DEBUG_RARE)
	#define debugUncommon(text) _dbg(text, DEBUG_UNCOMMON)
	#define debugCommon(text) _dbg(text, DEBUG_COMMON)
	#define debug(text) _dbg(text, DEBUG_USER)
#endif



// xobj_core comes with a couple of libraries, they are included
#include "xobj_core/libraries/libJasPre.lsl"
#include "xobj_core/libraries/libJas.lsl"

#include "xobj_core/libraries/partiCat.lsl"
#include "xobj_core/_CLASS_STATIC.lsl"


/*
	Header vars that you can use in each script:
	#define SCRIPT_IS_ROOT <- Always define this on top of #ROOT
	#define USE_EVENTS <- Add to top of a script that should be listening to events
	#define USE_SHARED (DEPRECATED) (list)scripts <- Add to top of a script that should be reading or setting shared vars. Ex: #define USE_SHARED [cls$name, "#ROOT"] or #define USE_SHARED ["*"]
	#define OVERRIDE_TOKEN <- Should be set if you want to define getToken as a preprocessor definition in your _core.lsl file
	#define SCRIPT_ALIASES [] <- Alias names the script can be run as. Array of names. Like if you have a script named "got LevelLite" and you want it to also be callable with "got Level", then define this as ["got Level"]
	#define USE_WATCHDOG <- Enables the ping command
	
*/


// These constants should be overwritten and defined in your _core.lsl file for each project
#ifndef PC_SALT
	// Define and set to any integer in your _core.lsl file, it will offset your playerchan. It's not recommended to use the same number for multiple projects.
	#define PC_SALT 0
#endif
#ifndef TOKEN_SALT
	// This is a secret code used to generate a hash. Define and set it to any string in your _core.lsl file
	#define TOKEN_SALT ""
#endif

// This generates a channel for each agent's scripts
#define playerChan(id) (-llAbs((integer)("0x7"+llGetSubString((string)id, -7,-1))+PC_SALT))

#ifndef OVERRIDE_TOKEN
	#ifndef DISREGARD_TOKEN
// This generates a salted hash for your project. Feel free replace the content of this function with an algorithm of your own.
string getToken(key senderKey, key recipient, string saltrand){
	if(saltrand == "")saltrand = llGetSubString(llGenerateKey(),0,15);
	return saltrand+llGetSubString(llSHA1String((string)senderKey+(string)llGetOwnerKey(recipient)+TOKEN_SALT+saltrand),0,15);
}
	#else
#define getToken(a,b,c) ""
	#endif
	
#endif
// Returns "" on fail, else returns data


// Global events

// These are events that are project-wide, module events and methods can NOT be negative integers. As they are reserved for project-wide ones.
#define evt$SCRIPT_INIT -1		// NULL - Should be raised when a module is initialized
#define evt$TOUCH_START -2		// [(int)prim, (key)id] - Raised when an agent clicks the prim
#define evt$TOUCH_END -3		// [(int)prim, (key)id] - Raised when an agent release the click
#define evt$BUTTON_PRESS -4		// (int)level&edge - Raised when a CONTROL button is pressed down. The nr is a bitfield containing the CONTROL_* buttons that were pressed.
#define evt$BUTTON_RELEASE -5	// (int)~level&edge - Raised when a CONTROL button is released. The nr is a bitfield containing the CONTROL_* buttons that were released.
#define evt$BUTTON_DOUBLE_PRESS -6	// (int)level&edge - If a button has been double tapped
#define evt$BUTTON_HELD_SEC -7		// [(int)level, (float)sec] - After a button has been held for x time
#define evt$TOUCH_HELD_SEC -8	// [(int)prim, (key)id, (int)sec] - After a click event has been held for x seconds


// nr Task definitions
// These are put into the nr field of llMessageLinked. Do NOT use negative integers if you're going to send your own link messages manually.
#define RUN_METHOD -1			// Basically what the runMethod() function does, use that
#define METHOD_CALLBACK -2		// == || == pretty much the same but sent as a callback
#define EVT_RAISED -3			// str = (string)data, id = (string)event - An event was raised. Runs the onEvt() function
#define RESET_ALL -4			// NULL - Resets all scripts in the project
#define DB2_ADD -5				// [(str)sender, (str)script[, (obj)data]] = (str)script - Data is passed along if this is the first time the script is seen
#define DB2_UPDATE -6			// str = (arr)data
#define DB2_DELETE -7			// str = (str)script
#define DB2_REFRESHME -8		// refreshes db2 on the script and sends a callback
#define DB3_ADD -5				// (str)sender_script, (arr)tableNames - Adds a table to DB3 - Sends stdMethod$setShared as a callback to the script on completion, params containing an array of tables added
#define DB3_TABLES_ADDED -6		// (arr)tables
#define DB4_ADD -7				// (str)sender_script, (arr)tableNames - Adds tables to DB4. Sends stdMethod$setShared as a callback to the script on completion, params containing an array of tables added

#define WATCHDOG_PING -10		// Pings all scripts
#define WATCHDOG_PONG -11		// str = (string)script



// Standard methods
// These are standard methods used by package modules. Do not define module-specific methods as negative numbers between -1 and -1000. Use -1000 if you need project wide generic STD Methods
#define stdMethod$setShared -3	/*
	Sent as a callback after creating tables
	DB2: [(str)table_name, (arr)table_key] DB2 Shared has been set from root. Note that this is only sent when db2 return "0" for asynchronous
	DB3: [(str)table1, (str)table2...] - Tables have been created.
	DB4: == || ==
*/

// General methods.
// Putting CALLBACK_NONE in the callback field will prevent callbacks from being sent when raising a method
#define CALLBACK_NONE JSON_INVALID
// Synonyms
#define NORET CALLBACK_NONE
#define TNN CALLBACK_NONE

// Initiates the standard listen event, put it in state_entry of #ROOT script
#ifndef ALLOW_USER_DEBUG
	#define initiateListen() llListen(playerChan(llGetOwner()), "", "", ""); debugRare("Listening on playerChan: "+(str)playerChan(llGetOwner()))
#else
	#define initiateListen() llListen(playerChan(llGetOwner()), "", "", ""); llListen(0, "", "", ""); debugRare("Listening on 0 and playerChan: "+(str)playerChan(llGetOwner()))
#endif


// NOTE: you can target all scripts with SCRIPT_IS_ROOT by using the recipient "__ROOTS__". Useful for things that need to be updated in ALL spawned items in a region.
// Disregard these, they're just preprocessor shortcuts
#define stdObjCom(methodType, uuidOrLink, className, data) llRegionSayTo(uuidOrLink, playerChan(llGetOwnerKey(uuidOrLink)), getToken(llGetKey(), uuidOrLink, "")+(string)methodType+":"+className+llList2Json(JSON_ARRAY, data)) 
#define stdOmniCom(chan, methodType, className, data) \
	llRegionSay(chan, getToken(llGetKey(), sender, "")+(string)methodType+":"+className+llList2Json(JSON_ARRAY, data)) 
#define stdIntCom(methodType, uuidOrLink, className, data) fwdIntCom(methodType, uuidOrLink, className, data, "")
#define fwdIntCom(methodType, uuidOrLink, className, data, sender) llMessageLinked((integer)uuidOrLink, methodType, className+llList2Json(JSON_ARRAY, data), sender)
#define sendCallback(sender, senderScript, method, cbdata, cb) list CB_OP = [method, cbdata, llGetScriptName(), cb]; if(llStringLength(sender)!=36){stdIntCom(METHOD_CALLBACK,LINK_SET, senderScript, CB_OP);}else{ stdObjCom(METHOD_CALLBACK,sender, senderScript, CB_OP);}
//#define sendCallback(sender, senderScript, method, cbdata, cb) llOwnerSay("Deleteme");

#define fwdMethod(link, className, method, data, sender) fwdIntCom(RUN_METHOD, link, className, [method, mkarr(data), llGetScriptName()], sender)

#define runMethod _rm
// This is the standard way to run a method on a module. See the readme files on how to use it properly.
_rm( string uuidOrLink, string className, integer method, list data, string callback ){

	list op = (list)(method) + mkarr(data) + llGetScriptName() + callback;
	if( (key)uuidOrLink )
		return stdObjCom(RUN_METHOD, uuidOrLink, className, op);
	stdIntCom(RUN_METHOD, uuidOrLink, className, op);
	
}


#define runOmniMethod(className, method, data, callback) stdOmniCom(playerChan(llGetOwner()), RUN_METHOD, className, (list)(method) + mkarr(data) + llGetScriptName() + (callback))
#define runChanOmniMethod(chan, className, method, data, callback) stdOmniCom(chan, RUN_METHOD, className, (list)(method) + mkarr(data) + llGetScriptName() + (callback))
#define runOmniMethodOn(targ, className, method, data, callback) stdOmniCom(playerChan(targ), RUN_METHOD, className, (list)(method) + mkarr(data) + llGetScriptName() + (callback))

// Same as above, but adds an optional , tokenSender should by default be llGetOwner but can be changed if you need to AOE on another person's channel
runLimitMethod(string tokenSender, string className, integer method, list data, string callback, float range){
	
	list op = [method, llList2Json(JSON_ARRAY, data), llGetScriptName()];
	if( callback )
		op+=[callback];
	
	integer chan = (int)tokenSender;
	if( (key)tokenSender )
		chan = playerChan(tokenSender);

	if(range>96)llRegionSay(chan, getToken(llGetKey(), tokenSender, "")+(string)RUN_METHOD+":"+className+llList2Json(JSON_ARRAY, op));
	else if(range>20)llShout(chan, getToken(llGetKey(), tokenSender, "")+(string)RUN_METHOD+":"+className+llList2Json(JSON_ARRAY, op));
	else if(range>10)llSay(chan, getToken(llGetKey(), tokenSender, "")+(string)RUN_METHOD+":"+className+llList2Json(JSON_ARRAY, op));
	else llWhisper(chan, getToken(llGetKey(), tokenSender, "")+(string)RUN_METHOD+":"+className+llList2Json(JSON_ARRAY, op));
}

// Placeholder function for events. Copy paste this and fill it with code in each module that needs to listen to events.
// onEvt(string script, integer evt, list data){}

// Standard function to raise an event.
#define raiseEvent(evt, data) llMessageLinked(LINK_SET, EVT_RAISED, llList2Json(JSON_ARRAY, ([llGetScriptName(), data])), (string)evt)

// Code used to reset the linkset's scripts
#define resetAllOthers() llMessageLinked(LINK_SET, RESET_ALL, llGetScriptName(), "")
#define resetAll() llMessageLinked(LINK_SET, RESET_ALL, llGetScriptName(), ""); llResetScript()




// Database management
#ifdef USE_DB2
	#include "xobj_core/_DB2.lsl"
#elif defined USE_DB4
	#include "xobj_core/_DB4.lsl"
#else
	// DB2 & 3 needs you to define the scripts you want to use
	// #define USE_SHARED [Script1, Script2...]
	#include "xobj_core/_DB3.lsl"
#endif



 

 