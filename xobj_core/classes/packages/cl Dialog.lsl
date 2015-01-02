// Include the main file


// Include the general class functionality - Make a full include to grab any private stuff
#include "xobj_core/classes/cl Dialog.lsl"
#include "xobj_core/_CLASS_PACKAGE.lsl"


integer BFL;
//#define BFL_QUERYING 1

//#define TIMER_QUERY "a"




                            // STD
integer __construct(list args){  // senderKey, targetId, menu, script, callback, buttons, message
    
    key id = (key)fn_arg(1);
    if(id == "")id = llGetOwner(); 
    #if DialogConf$ownerOnly == 1
    if(id != llGetOwner())return FALSE;
    #endif
    integer chan = -llCeil(llFrand(0xFFFFFFF));
    cls$push(([
        DialogVar$senderID, fn_arg(0),
        DialogVar$user, id,
        DialogVar$menu, (integer)fn_arg(2),
        DialogVar$script, fn_arg(4),
        DialogVar$listener, llListen(chan, "", id, ""),
        DialogVar$chan, chan,
        DialogVar$callback, fn_arg(3),
        DialogVar$page, 0,
        DialogVar$buttons, fn_arg(5),
        DialogVar$message, fn_arg(6)
    ]));
    #if DialogConf$timeout > 0
    multiTimer([id, "", DialogConf$timeout, FALSE]);
    #endif
    return TRUE;
} 








                            // Methods
public_spawn(key sender, key id, string message, string buttons, integer menuid, string callback, string script){
    // Find user
    private_setCurUser(id);
    if(!UNINITIALIZED)private_removeListener(id);
    __add([sender, id, menuid, callback, script, buttons, message]);
    cls$setLast();

    private_loadPage(0); // loads current page
}







                            // Private
integer private_setCurUser(key id){ // Sets active object to user
    if(id == "")id = llGetOwner();
    cls$each(index, obj, {
        if(llJsonGetValue(obj, [DialogVar$user]) == (string)id){
            cls$setIndex(index);
            return TRUE;
        }
    });
    return FALSE;
}
private_removeListener(key id){
    if(id != ""){
        if(!private_setCurUser(id))return;
    }
    llListenRemove((integer)this(DialogVar$listener));
    this$remove();
}
// Loads a dialog with a page offset
private_loadPage(integer offset){
    integer page = (integer)this(DialogVar$page)+offset;
    list buttons = llJson2List(this(DialogVar$buttons));
    
    if(llGetListLength(buttons)<=12)page = 0;
    else{
        if(page>llFloor((float)llGetListLength(buttons)/10))page = 0;
        else if(page<0)page = llFloor((float)llGetListLength(buttons)/10);
        buttons = [DialogConf$prevButton, DialogConf$nextButton]+llList2List(buttons, page*10, page*10+9);
        this$setProperty(DialogVar$page, page); 
    }
    
    integer chan = (integer)this(DialogVar$chan);
    key targ = (key)this(DialogVar$user);
    string msg = this(DialogVar$message);
    if((string)buttons == "TEXTBOX")llTextBox(targ, msg, chan);
    else llDialog(targ, msg, buttons, chan);
}

                            // Events 

timerEvent(string id, string data){
    private_removeListener(id);
}







default 
{
    
    state_entry()
    {
        // ALWAYS init shared vars - Made this way to speed things up
        initShared();
    }

    listen(integer chan, string name, key id, string message){
        if(private_setCurUser(id)){
            if(message == DialogConf$nextButton)private_loadPage(1);
            else if(message == DialogConf$prevButton)private_loadPage(-1);
            else{
                key senderID = this(DialogVar$senderID);
                sendCallback(
                    senderID, 
                    this(DialogVar$script), 
                    DialogMethod$spawn, 
                    id, 
                    DialogVar$user, 
                    llList2Json(JSON_OBJECT, [
                        "message", message,  
                        "menu", this(DialogVar$menu),
						"user", id
                    ]), 
                    this(DialogVar$callback)
                )  
                private_removeListener(""); 
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
    
    if(nr == RUN_METHOD){
        if(METHOD == DialogMethod$spawn){
			
            public_spawn(
                id,
                (key)method_arg(0),
                method_arg(1),
                method_arg(2),
                (integer)method_arg(3), 
                CB,
                SENDER_SCRIPT
            );
            return; // Prevent default callback
        }
    }
        
    else if(nr == METHOD_CALLBACK){
        
        
        return; // Prevent recursion
    }
    
    #define LM_BOTTOM 
    #include "xobj_core/_LM.lsl"
}

