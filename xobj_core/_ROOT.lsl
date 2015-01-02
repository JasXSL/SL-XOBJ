#include "xobj_core/libraries/libJas.lsl"
#include "xobj_core/libraries/libJasPre.lsl"
#include "xobj_core/libraries/partiCat.lsl"

#include "xobj_core/classes/cl SharedVars.lsl" // SV headers
#include "xobj_core/classes/st RLV.lsl" // SV headers
#include "xobj_core/classes/st Supportcube.lsl" // SV headers



// CONSTANTS THAT SHOULD BE SET IN PROJECT 

#ifndef PC_SALT
	#define PC_SALT 31298
#endif
#ifndef TOKEN_SALT
	#define TOKEN_SALT "c9as8v6as0phgfkdnfosd"
#endif


integer playerChan(key id){
    return -llAbs((integer)("0x7"+llGetSubString((string)id, -7,-1))+PC_SALT);
}

string getToken(key senderKey, key recipient, string saltrand){
	if(saltrand == "")saltrand = llGetSubString(llGenerateKey(),0,15);
	return saltrand+llGetSubString(llSHA1String((string)senderKey+(string)llGetOwnerKey(recipient)+TOKEN_SALT+saltrand),0,15);
}

// Returns "" on fail, else returns data


//#define verifyToken(token, sender) 


// Global events
#define evt$SCRIPT_INIT -1		// NULL
#define evt$TOUCH_START -2		// [(int)prim, (key)id]
#define evt$TOUCH_END -3		// [(int)prim, (key)id]
#define evt$BUTTON_PRESS -4		// (int)level&edge
#define evt$BUTTON_RELEASE -5	// (int)~level&edge


// nr Task definitions
#define RUN_METHOD -1			// str = method, findObj, in, data, sender_class, callback, id = sender
#define METHOD_CALLBACK -2		// == || == 
#define EVT_RAISED -3			// str = (string)data, id = (string)event
#define RESET_ALL -4			// NULL

// Standard methods
#define stdMethod$insert -1		// [cl*] cbData = (int)success
#define stdMethod$remove -2		// [cl*] cbData = (int)amount_removed
#define stdMethod$interact -3	// [st Interact] - To sent an interact call to a prim

// HELPER DEFINITIONS that can be used in coms
#define CALLBACK_NONE JSON_NULL
#define NORET CALLBACK_NONE
#define TARG_NULL "", ""
#define TNN "", "", CALLBACK_NONE, ""


initiateListen(){
	llListen(playerChan(llGetOwner()), "", "", "") ;
	#ifdef LISTEN_OVERRIDE 
	llListen(LISTEN_OVERRIDE,"","","");
	#endif
}
#define stdObjCom(methodType, uuidOrLink, customTarg, className, data) llRegionSayTo(uuidOrLink, playerChan(llGetOwnerKey(uuidOrLink)), customTarg+getToken(llGetKey(), uuidOrLink, "")+(string)methodType+":"+className+llList2Json(JSON_ARRAY, data)) 
#define stdOmniCom(methodType, customTarg, className, data) llRegionSay(playerChan(llGetOwner()), customTarg+getToken(llGetKey(), llGetOwner(), "")+(string)methodType+":"+className+llList2Json(JSON_ARRAY, data)) 

#define stdIntCom(methodType, uuidOrLink, className, data) llMessageLinked((integer)uuidOrLink, methodType, className+llList2Json(JSON_ARRAY, data), "");
#define sendCallback(sender, senderScript, method, search, in, cbdata, cb) list CB_OP = [method, search, in, cbdata, llGetScriptName(), cb]; if(llStringLength(sender)!=36){stdIntCom(METHOD_CALLBACK,LINK_SET, senderScript, CB_OP);}else{ stdObjCom(METHOD_CALLBACK,sender, "*", senderScript, CB_OP);}


// Target null no-callback
runMethod(string uuidOrLink, string className, integer method, list data, string findObj, string in, string callback, string customTarg){
	list op = [method, findObj, in, llList2Json(JSON_ARRAY, data), llGetScriptName()];
	if(callback != JSON_NULL)op+=[callback];
	string pre = customTarg;
	if(pre == "")pre = "*";
	if((key)uuidOrLink){stdObjCom(RUN_METHOD, uuidOrLink, pre, className, op);}
	else{ stdIntCom(RUN_METHOD, uuidOrLink, className, op)}
}

runLimitMethod(string className, integer method, list data, string findObj, string in, string callback, string customTarg, float range){
	string pre = customTarg;
	if(pre == "")pre = "*";
	list op = [method, findObj, in, llList2Json(JSON_ARRAY, data), llGetScriptName()];
	if(callback != JSON_NULL)op+=[callback];
	if(range>96)stdOmniCom(RUN_METHOD, pre, className, op);
	else if(range>20)llShout(playerChan(llGetOwner()), pre+getToken(llGetKey(), llGetOwner(), "")+(string)RUN_METHOD+":"+className+llList2Json(JSON_ARRAY, op));
	else if(range>10)llSay(playerChan(llGetOwner()), pre+getToken(llGetKey(), llGetOwner(), "")+(string)RUN_METHOD+":"+className+llList2Json(JSON_ARRAY, op));
	else llSay(playerChan(llGetOwner()), pre+getToken(llGetKey(), llGetOwner(), "")+(string)RUN_METHOD+":"+className+llList2Json(JSON_ARRAY, op));
}

runOmniMethod(string className, integer method, list data, string findObj, string in, string callback, string customTarg){
	string pre = customTarg;
	if(pre == "")pre = "*";
	list op = [method, findObj, in, llList2Json(JSON_ARRAY, data), llGetScriptName()];
	if(callback != JSON_NULL)op+=[callback];
	stdOmniCom(RUN_METHOD, pre, className, op);
}

insert(integer link, string className, list data, string callback){
	runMethod((string)link, className, stdMethod$insert, data, TARG_NULL, callback);
}
remove(integer link, string className, string search, string in, string callback){
	runMethod((string)link, className, search, in, callback);
}

onEvt(string script, integer evt, string data){
	
}

raiseEvent(integer evt, string data){
	llMessageLinked(LINK_SET, EVT_RAISED, llList2Json(JSON_ARRAY, [llGetScriptName(), data]), (string)evt);
}

#define resetAllOthers() llMessageLinked(LINK_SET, RESET_ALL, llGetScriptName(), "")
#define resetAll() llMessageLinked(LINK_SET, RESET_ALL, llGetScriptName(), ""); llResetScript()




 

 