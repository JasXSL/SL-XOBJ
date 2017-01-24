SL-XOBJ
=======

An LSL framework with methods, events, macros and prim DB

XOBJ is a framework for SL Firestorm in an attempt to make a more modular approach, allowing you to do more with less code and have, and making your code more portable!

xobj supports the following features:
* Events
* Methods with optional callbacks
* Prim DB
* Macros

**Don't forget to check the project Wiki for guides and script references!**
 

###Glossary
* Module - A script. Scripts in XOBJ are called by name.
* Header file - A file containing methods, events, config values, documentation etc for a module.
* Package file - A file that contains the actual code of the module.
* Method - A standard input for a particular module that causes it to execute code, potentially receive a callback, and can be sent and received from outside the linkset.
* Method macro - A shortcut of running a method such as Dialog$spawn() 
* Event - A linkset-internal way of sending data from a script to be parsed by other scripts.
* Prim DB/DB3/Shared Vars - A way of storing data on a prim that any script in the linkset can read synchronously.






#Update 0.3.0
DB2 has been replaced with DB3 and I have adopted a new philosophy on shared vars. DB3 will consume less memory and automatically preserve tables between script resets. But it runs a little slower and requires you to set up the tables in #ROOT.


#Install

###1. Set up preprocessing, download & install XOBJ
1. Create a folder for SL libraries on your drive (example C:\LSL)
2. Download XOBJ as zip and extract the contents of the master folder to your SL libraries directory (C:\LSL). The important part is that you now have C:\LSL\xobj_core & C:\LSL\xobj_toonie folders. If you are familiar with git, you can also git clone and add these folders as symlinks in your libraries directory.
3. Open a script window in your Firestorm viewer. Click the cogs icon at the top and check Enable LSL preprocessor. Then check **Script optimizer** and **#includes from local disk**. The other checkboxes are optional.
4. Click the ... button and navigate to your libraries directory (C:\LSL)
5. Close and re-open your script window. Then hit OK.
6. Click OK, you are done!
7. (Optional) To test if it works create a new default LSL script (hello avatar), and above default add #include "xobj_core/_ROOT.lsl" Then compile. If you get no errors, it worked!

###2. Creating a new project
1. Create a subfolder under your includes on disk. Ex: C:\LSL\MyFirstProject
2. Create a file in that folder and name it _core.lsl
3. In the first line of _core.lsl enter #include "xobj_core/_ROOT.lsl"
4. Hit enter. LSL include files must always end with a blank line
5. Save your file.
6. Create a new script in LSL and name it #ROOT. #ROOT will serve as the standard input. On the first line, enter #include "MyFirstProject/_core.lsl" and save. For root implementation examples, see the #ROOT implementations readme.


###3. Setting up DB3 (optional)
Shared vars are used to offload large chunks of data onto a prim-driven database. Ex a script that gets JSON data from a webserver might choose to put a large JSON object into the prim DB which can then be read synchronously by a different script.
    
    string species = db3$get("got Bridge", ["species"]);
    
To do so, you need one or more cubes added to the linkset to serve as a database. Each prim can serve up to 9 "tables" at a time, each with 3000 bytes of storage.

1. Create a new cube and name it DB0
2. Set the cube's path-cut to any value above 0
3. Set the cube's hollow to any value above 0
4. Make your object fully transparent and link it to your linkset (ex: your HUD)
5. Please note that textures on this prim will not be visible, so keep it hidden
(Protip: Setting the cube's physics shape to convex-hull will help you save prims if the linkset is rezzed)
    Note: If you get an error about DB being full, you can create additional database prims, just name them DB1, DB2 etc

1. At the first line of your #ROOT script add #define SCRIPT_IS_ROOT
2. In state_entry of the #ROOT script put something like
3. 
    list tables = [
	"#ROOT"
	"got Bridge"
    ];
    db3$addTables(tables); 

3. This will create tables for the #ROOT script and "got Bridge" script. You can also add custom names that can be written to with DB3$setOther(str script, list index, var data)
4. Before you can call any DB3$get/set commands on other scripts you need to wait for the code to be initialized. In the link message section of #ROOT you can put something like:

    if(method$isCallback){
	if(SENDER_SCRIPT == "#ROOT" && METHOD == stdMethod$setShared){
	    // Tables have been created here. Other scripts can now access these tables.
	    //qd("Tables created: "+PARAMS);
	    resetAllOthers();
	}
        return;
    }

####Best practices
* DB3 is slow. Its primary purpose is to offload large chunks of data. Do not rely on it to quickly share data between scripts. The events system is better used for this.
* Only have one script SET data on a table. Otherwise asynchronisity might overwrite your data. Let a script "own" a table if so to speak.




###4. Installing a premade "module"
Scripts in XOBJ can be called modules. A module ALWAYS consists of at least one header file which contains preprocessor definitions, and optionally one package file containing the actual code. You can write the code of the package file directly in SL if you don't intend on sharing it.

To add a pre-existing module you'll want to start by including your project core, then define any config definitions, and finally including the package file. Example, Install the dialog manager:

1. Create a new script in your project. Name it "jas Dialog". jas is a prefix that should identify the project or creator. In this case it's a generic module made by jasdac, so the prefix was named as "jas".
2. Open the script, delete all the code and add on the first line: #include "MyFirstProject/_core.lsl"
3. Next set any config definitions you want. Ex #define DialogConf$ownerOnly 0 if you do not want to limit the dialog to the script owner. And #define DialogConf$timeout 10 if you want the dialog to time out after 10 seconds.
4. Include the package file: #include "xobj_core/classes/packages/jas Dialog.lsl"
5. Compile. You can now utilize the dialog manager.


###5. Running methods
XOBJ uses a few standard functions to send or receive data:
  runMethod(string uuidOrLink, string script, integer method, list data, string callback)
  
This is the standard function to run a method on a script.

* uuidOrLink : Either a key of a prim or user to send to, or an integer prim in the linkset like (string)LINK_ROOT or (string)LINK_SET
* script : The name of the script to run the method on, by name. Ex: "jas Dialog"
* method : A method defined in the target script header file. Ex: DialogMethod$spawn
* data : Any parameters the method accepts, ex: [llGetOwner(), "A standard yes/no button", llList2Json(JSON_ARRAY, ["Yes", "No"]), 0]
* callback : A string you'd like to receive as a callback upon successfully running the method. Use the constants NORET, JSON_INVALID or TNN will prevent callbacks. An empty string "", " " etc will only do a callback if there's any data to callback. Anything else will return your callback string, even if there was no other data to return.
    
A lot of the header scripts have predefined shortcuts also, so you won't have to type out all of that. For an example, jas Dialog has predefined:

    Dialog$spawn(user, message, buttons, menuID, callback)

So in your script you can just run:

    Dialog$spawn(llGetOwner(), "Dialog message", ["Button1", "Button2"], 0, "D")

	
###6. Events  
Events are ways to send data to an entire linkset rather than just a single module. The event IDs for each script is defined in the script's header file. There are a few global events such as evt$SCRIPT_INIT, these are defined in _ROOT.lsl. Events are usually non-zero interger 0 defined like:

    #define ModuleNameEvt$eventname 1

To raise an event: 
    
    raiseEvent((int)event, (str)data)

####Capture events
1. Add at the top of the script #define USE_EVENTS
2. Create a function like onEvt(string module, integer evt, string data){}
3. Module is the sender, evt is the event ID, and data is any data sent along with the event.
4. Never rely on event IDs directly always verify the module it came from ex:

    if(module == "ModuleName" && evt == ModeulNameEvt$eventname)


###7. Create a module.
Please see the module creation readme.

