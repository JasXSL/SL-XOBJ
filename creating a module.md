Let's create our first module! A module is basically just a script, but follows a few rules:
1. A module needs a header file that can be included by other scripts to access your module's methods.
2. A module can be used as an object package for pseudo object oriented coding.

In this example we'll create a dialog that will output "hello world" when you select the Yes option.
Make sure you have read the original readme, as well as the #ROOT implementations readme.
You should have a "#ROOT" script and the "jas Dialog" module installed (see the SL-XOBJ original readme).

1. Add a new script to your project and name it "mfp Main". mfp stands for MyFirstProject. It should always be a short string to identify your project.
2. Navigate locally to your "myFirstProject" or whatever you named your project folder.
3. Create a new subfolder and name it "classes", so you'll have something like "c:\LSL\myFirstProject\classes"
4. Inside that folder, create a new file and name it "mfp Main.lsl"
5. Open the file in a text editor of choice (I recommend notepad++). Note: Make sure the notecard ends with a blank row, or the preprocessor will throw a fit.
6. Save the blank script for now, we'll use it later.
7. Open up your "mfp Main" script in SL.
8. On the first row enter #include "myFirstProject/_core.lsl"
9. On the second row enter #include "myFirstProject/classes/mfp Main.lsl"
10. On the third row enter #include "xobj_core/classes/jas Dialog.lsl"

Next we'll need to start listening to events. 
1. At the very top of the script add #define USE_EVENTS
2. After the #includes add the following code:
	onEvt(string module, integer evt, string data){
		if(module == "#ROOT" && evt == evt$TOUCH_START){
			integer prim = (integer)jVal(data, [0]);
			key clicker = (key)jVal(data, [1]);
			if(clicker == llGetOwner()){
				Dialog$spawn(llGetOwner(), "Would you like to output hello world?", (["Yes", "No"]), 0, "");
			}
		}
	}
Now you're listening to project events. In particular you are checking if the sender module was named "#ROOT" and the event was the standard event evt$TOUCH_START.

If it was, it reads the data of that event, [clicked_prim, clicker_key] and tells the dialog manager to create a new dialog for the user, using menu ID 0. If you need more menu IDs, you likely want to cast them into constants, but since there are no submenus in this script we can disregard it.

Next we'll add the link message event. Paste this into the default{} section of your script:

	#include "xobj_core/_LM.lsl" 
	/* 
	    Included in all these calls:
	    METHOD - (int)method
	    INDEX - (int)obj_index
	    PARAMS - (var)parameters
	    SENDER_SCRIPT - (var)parameters
	    CB - The callback you specified when you sent a task
	    CB_DATA - Array of params to return in a callback
	    id - (key)method_raiser_uuid
	*/
	    
	if(method$isCallback){
		return;
	}
	
	   
	#define LM_BOTTOM  
	#include "xobj_core/_LM.lsl"

That will set up the linkmessage handler. The code in if(method$isCallback) is run upon receiving a callback. The code after that is run if accessed directly.
Right now our module has no methods, but the dialog manager will send a callback, so we'll set up something to happen on receiving a dialog callback of "Yes"

Add the following code before the return in if(method$isCallback):

	if(method$byOwner){
		if(SENDER_SCRIPT == "cl Dialog" && METHOD == DialogMethod$spawn){
			integer menu = (integer)jVal(PARAMS, ["menu"]);
			string message = jVal(PARAMS, ["message"]);
			key user = id;
			if(message == "Yes" && menu == 0){
				llSay(0, llGetDisplayName(user)+" said Hello World!");
			}
		}
	}

- First off, this checks if the method was raised by owner. You can also check if(method$internal) to limit a method to being run only from the linkset the script is in.
- It then checks if the callback was sent from the "cl Dialog" script, and if the method run on that script was DialogMethod$spawn
- In that case it fetches the ID of the menu you opened, and the message received.
- If the message was yes and the menu was 0 (as we specified when we sent the call) we output the hello world message.

That's how to utilize another module from your own module.






Let's take a look at how you can let other modules access yours. Start off by opening your mfp Main.lsl file.
1. On the first line add: #define MainMethod$helloWorld 1	// (key)sender - Sends a hello world message with sender's display name
2. You have defined your first method identifier (1)! And it accepts 1 argument (key)sender
3. Save the file and go back to your mpf Main SL script.
4. After the if(method$isCallback) if statement (right above #define LM BOTTOM) add the following code:

	if(METHOD == MainMethod$helloWorld){
		llSay(0, llGetDisplayName(method_arg(0))+" said Hello World!");
		CB_DATA = [method_arg(0)];
	}

- The if statement checks if the method to run was your defined MainMethod$helloWorld
- method_arg(0) gets the first method argument as a string, in this case it's supposed to be the key of the sender.
- CB_DATA = [method_arg(0)]; lets you return the key of the sender in a callback.

Let's create an in-world box to run your method.

1. Create a box in world.
2. Create a new script in your box and name it #ROOT.
3. Copy+paste the root script you made earlier into the box #ROOT script.
4. On the first row enter #include "myFirstProject/_core.lsl"
5. Add to the top of the script: #include "myFirstProject/classes/mfp Main.lsl"
6. Add the following code into the new #ROOT script's default{}

```
	#include "xobj_core/_LM.lsl" 
	/* 
	    Included in all these calls:
	    METHOD - (int)method
	    INDEX - (int)obj_index
	    PARAMS - (var)parameters
	    SENDER_SCRIPT - (var)parameters
	    CB - The callback you specified when you sent a task
	    CB_DATA - Array of params to return in a callback
	    id - (key)method_raiser_uuid
	*/
	    
	if(method$isCallback){
	    if(SENDER_SCRIPT == "mfp Main" && METHOD == MainMethod$helloWorld){
		llSay(0, llGetDisplayName(method_arg(0))+"'s call was successful! Sender callback: "+CB);
	    }
	    return;
	}
	   
	#define LM_BOTTOM  
	#include "xobj_core/_LM.lsl"
```

This receives a callback from st Main and outputs that it was a success.

6. Replace the new #ROOT script's touch_start event with the following:
	touch_start(integer total){
		runOmniMethod("mfp Main", MainMethod$hellOWorld, [llDetectedKey(0)], "This is a callback message");
	}

7. Touch the box. If it's set up correctly it should output the hello world message, as well as the callback you specified in touch_start.
runOmniMethod is similar to runLimitMethod except it sends the command to any listeners within the region, except the linkset that sent the command. It's recommended that you use it sparingly.


Now check around in the files of the XOBJ project. Most of them have documentation of things that will make your life easier while scripting.
Enjoy!
