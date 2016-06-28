// Include the main file
#include "xobj_core/classes/jas Dialog.lsl"


// senderKey, menu, script, callback, buttons, message, listener, chan, page, (int/id)senderObj
list objects = [];
#define OBJSTRIDE 10

integer findByKey(string id){
	integer i;
	for(i=0; i<llGetListLength(objects); i+=OBJSTRIDE){
		if(llList2String(objects, i) == id)return i;
	}
	return -1;
}


// Methods
spawn(key senderObj, key id, string message, list buttons, integer menu, string callback, string script){
    if(id == "")id = llGetOwner(); 
    // Remove previous
    remove(id);
	
	#if DialogConf$ownerOnly == 1
    if(id != llGetOwner())return;
    #endif
	
	integer chan = -llCeil(llFrand(0xFFFFFFF));
	objects+=[id, menu, script, callback, mkarr(buttons), message, llListen(chan, "", id, ""), chan, 0, senderObj];

    #if DialogConf$timeout > 0
    multiTimer([id, "", DialogConf$timeout, FALSE]);
    #endif
	
    loadPage(id, 0); // loads current page
}

remove(key id){
	integer pos = findByKey(id);
	if(pos == -1)return;
	llListenRemove(llList2Integer(objects, pos+6));
	objects = llDeleteSubList(objects, pos, pos+OBJSTRIDE-1);
}

loadPage(key id, integer offset){
    integer pos = findByKey(id);
	if(pos == -1)return;
	
	integer page = llList2Integer(objects, pos+8)+offset;
    list buttons = llJson2List(llList2String(objects, pos+4));
    
    if(llGetListLength(buttons)<=12)page = 0;
    else{
        if(page>floor((float)llGetListLength(buttons)/10))page = 0;
        else if(page<0)page = floor((float)llGetListLength(buttons)/10);
        buttons = [DialogConf$prevButton, DialogConf$nextButton]+llList2List(buttons, page*10, page*10+9);
        objects = llListReplaceList(objects, [page], pos+8, pos+8);
    }
	
	integer i;
	for(i=0; i<llGetListLength(buttons); i++){
		string b = llList2String(buttons, i);
		if(llStringLength(b)>23)buttons = llListReplaceList(buttons, [llGetSubString(b,0,23)], i, i);
	}
    
    integer chan = llList2Integer(objects, pos+7);
    key targ = (key)llList2String(objects, pos);
    string msg = llList2String(objects, pos+5);
    if(buttons == [])llTextBox(targ, msg, chan);
    else llDialog(targ, msg, buttons, chan);
}

// Events 
timerEvent(string id, string data){
    remove(id);
}

default 
{
    listen(integer chan, string name, key id, string message){
		integer pos = findByKey(id);
		if(~pos){
            if(message == DialogConf$nextButton)loadPage(id, 1);
            else if(message == DialogConf$prevButton)loadPage(id, -1);
            else{
                key senderID = llList2String(objects, pos+9);
                sendCallback(
                    senderID, 							// UUID to send callback to (or link)
                    llList2String(objects, pos+2), 		// Script to send the callback to
                    DialogMethod$spawn, 				// Method
                    llList2Json(JSON_ARRAY, [			// CBData
                        message,  
                        llList2Integer(objects, pos+1),
                        id
                    ]), 
                    llList2String(objects, pos+3)			// Callback
                )  
                remove(id); 
            }
        }
    } 
    
    timer(){multiTimer([]);}

    #include "xobj_core/_LM.lsl"
    /*
        Included in all these calls:
        METHOD - (int)method
        INDEX - (int)obj_index
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters
        CB_DATA - This is where you set any callback data you have
    */
	if(method$isCallback)return;
    
    if(METHOD == DialogMethod$spawn){
        spawn(
            id,
            (key)method_arg(0),
            method_arg(1),
            llJson2List(method_arg(2)),
            (integer)method_arg(3), 
            CB,
            SENDER_SCRIPT
        );
        return; // Prevent default callback
    }
        

    
    #define LM_BOTTOM 
    #include "xobj_core/_LM.lsl"
}

