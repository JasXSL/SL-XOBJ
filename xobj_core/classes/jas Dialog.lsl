/*
	This class makes it easy to tie dialogs to users
	The primary method is DialogMethod$spawn(key agent, string message, list buttons, integer menuID)
		Agent : key UUID of avatar to send the dialog to
		Message : str The message of the dialog box
		Buttons : array - Buttons to show "TEXTBOX" first element to use a textbox instead
		MenuID : int - An ID relative to your script signifying what menu you're in
	
	Which returns a callback with param 0: {"message":(str)message, "menu":(int)menu, "user":(key)clicker}
	
*/

// Available configs (set these before the script is included)
#ifndef DialogConf$ownerOnly
	#define DialogConf$ownerOnly 1		// Only spawn dialogs for script owner
#endif 
#ifndef DialogConf$timeout
	#define DialogConf$timeout 0		// Time before dialog is invalid, 0 = infinite
#endif
#ifndef DialogConf$nextButton
	#define DialogConf$nextButton "»"	// Button to go to next page (if nr buttons > 12)
#endif
#ifndef DialogConf$prevButton
	#define DialogConf$prevButton "«"	// Button to go to previous page (if nr buttons > 12)
#endif


// Methods //
// Methods should not be negative
#define DialogMethod$spawn 0			// key id, string message, list buttons, integer menuID

								
// Obj Member Vars //
// These are the member vars of this class' JSON objects
#define DialogVar$user "A"
#define DialogVar$script "B"
#define DialogVar$menu "C"
#define DialogVar$listener "D"
#define DialogVar$chan "E"
#define DialogVar$callback "F"
#define DialogVar$senderID "G"
#define DialogVar$page "H"
#define DialogVar$buttons "I"
#define DialogVar$message "J"



// Preprocessor shortcuts
// (key)user or "" for self, (str)message, (list)buttons, (int)menuID
#define Dialog$spawn(user, message, buttons, menuID, callback) runMethod((string)LINK_THIS, "jas Dialog", DialogMethod$spawn, [user, message, llList2Json(JSON_ARRAY, buttons), menuID], callback)
// Checks in LM callback section if a callback method is a dialog callback, ex if(Dialog$isCallback){}
#define Dialog$isCallback (SENDER_SCRIPT == "jas Dialog" && METHOD == DialogMethod$spawn)
// Creates the following vars inside the if(Dialog$isCallback) statement: integer menu; string message; key clicker;
#define Dialog$fetchCallback() integer menu = (integer)llJsonGetValue(PARAMS, ["menu"]); string message = llJsonGetValue(PARAMS, ["message"]); key clicker = llJsonGetValue(PARAMS, ["user"]);



 


