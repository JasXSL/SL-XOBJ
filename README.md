SL-XOBJ
=======

A modular approach to LSL with support for pseudo-object orientation

XOBJ is a framework for SL in an attempt to make a more modular approach.
xobj treats each script like a module, using events and "methods" to easily let you drop in any module into any project, making code easy to reuse
xobj supports the following features:
- Script events
- Standardized script methods with callbacks
- Linkset-wide shared variables
- ~~Ability to create and modify objects in a pseudo-object-oriented fashion~~
- A general library for preprocessor shortcuts (like lowercase true/false and foreach loops)

Note: xobj_core requires the firestorm viewer

##Update 0.2.0##
0.2.0 is not entirely backwards compatible. The will likely be a lot of bugs to fix, so please report them.
- Object orientation has been removed. cl-scripts are no longer supported because they were slow and memory intensive
- Naming convention has changed. Instead of cl/st, please prefix your scripts with a shorthand for your project or the developer.
- Listen limit by name has been removed. Insead I suggest you just use a method parameter if you need to check names.


### Old updates ###
=======
DB2 has been added to replace cl SharedVars
Features:
- Faster
- Lower memory cost
- No separate script needed
- Synchronous (after the first save per script)

At the top of your #ROOT script, add: #define SCRIPT_IS_ROOT
At the top of any script that needs to either get or set shared vars #define USE_SHARED ["*"]
Note: It's generally better and faster to limit #define USE_SHARED ["#ROOT", "st Status", cls$name...]

Set a shared var:
db2$set(["toonie"], "panda"); <- The first call takes a few sec to save as #ROOT needs to add this script to cache. Once done (usually a second or 2), db2$set will be INSTANT and SYNCHRONOUS
db2$get(cls$name, ["toonie"]) <- Gets data as usual




###Create your first project###
		1. Enable preprocessing
Open a script window, click the cogs icon at the top and check Enable LSL preprocessor, Script optimizer and #includes from local disk.
The other checkboxes are optional.
Select a path to where you want your root include folder to be. Ex: C:\LSL
Extract the xobj_core folder (and xobj_toonie if you want to use that) into your newly created folder. Ex: C:\LSL\xobj_core
Close and re-open your script window.
Now you have installed the core and will not have to re-install it for future projects.

		2. Creating a new project
Create a subfolder under your includes on disk. Ex: C:\LSL\MyFirstProject
Create a file in that folder and name it _core.lsl
In the first line of _core.lsl enter #include "xobj_core/_ROOT.lsl"
Hit enter. LSL include files must always end with a blank line
Save your file.
Create a new script in LSL and name it #ROOT. #ROOT will serve as the standard input. On the first line, enter #include "MyFirstProject/_core.lsl" and save. For root implementation examples, see the #ROOT implementations readme.


    	3. Setting up shared vars (optional)
Shared vars are used for scripts to get variables from another script. Ex a script called "st User" might choose to share an object containing user info like {(key)id:(string)species}
This could then be accessed by "st UserInfo" that could call something like:
	string species = db2$get("st User", ["cf2625ff-b1e9-4478-8e6b-b954abde056b"]);
	
To do so, you need one or more cubes added to the linkset to serve as a database. Each prim can serve up to 9 scripts at a time allocating 2048 bytes of data per script.
1. Create a new cube and name it DB0
2. Set the cube's path-cut to any value above 0
3. Set the cube's hollow to any value above 0
4. Make your object fully transparent and link it to your linkset (ex: your HUD)
5. Please note that textures on this prim will not be visible, so keep it hidden
(Protip: Setting the cube's physics shape to convex-hull will help you save prims if the linkset is rezzed)
Note: If you get an error about DB being full, you can create additional database prims, just name them DB1, DB2 etc

At the first line of your #ROOT script add #define SCRIPT_IS_ROOT

In any script that you want to be able to read and/or set shared vars (except #ROOT which already caches all script) add on top of the script #define USE_SHARED ["st script1", "st script2", cls$name] etc or just #define USE_SHARED ["*"] if you want to be able to use all scripts. Keep in mind the second alternative will be slightly slower and use more memory.

You can now save or read shared vars in any script of the linkset.
**The first time you call db2$set(idx, data) it will take a second or a few (depending on lag) for the data to be readable.**
Any db2$set(idx, data) called after this first first call will be **SYNCHRONOUS**.
You can get data with db2$get(script, idx)


Constants:
(advanced) If you wish to use a different prefix of your DB cubes (default DB0, DB1 etc) enter at the top ex:
    #define db2$prefix "newPrefix"
Functions:
  These functions can be used at any time (but will not work properly without a USE_SHARED definition:
    - db2$set((list)idx, (str)data) <- Idx is a list of where in the JSON to search like ["tonaie"], data is the data you want to save to that index, like "Panda". db2$set will return "1" if it was synchronous, otherwise "0". If the request was asynchronous the root script will send a callback with the method stdMethod$setShared, arguments [(str)tableName, (arr)json_specifiers] and CB is the data you wanted to set
    - db2$get((str)script, (list)idx) <- Script is the name of the script to read from. idsx is a json pointer like ["tonaie"]
    - clearDB2() <- Drops all stored data in the entire linkset
    
Events:
  DB2 Updated events have been removed in DB2. Will see if I need to later as it would increase memory cost.
    
    	4. Adding a module
Scripts in XOBJ can be called modules. A module ALWAYS consists of at least one header file which contains preprocessor definitions, and optionally one package file (if you want to share it) containing the actual code. You can always write the code of the package file directly in SL if you don't intend on sharing it.

To add a pre-existing module you'll want to start by including your project core, then define any config definitions, and finally including the package file. Install the dialog manager:
1. Create a new script in your project. Name it "jas Dialog". jas is a prefix that should identify the project or creator. In this case it's a generic module made by jasdac, so the prefix was named as "jas".
2. Open the script, delete all the code and add on the first line: #include "MyFirstProject/_core.lsl"
3. Next set any config definitions you want. Ex #define DialogConf$ownerOnly 0 if you do not want to limit the dialog to the script owner. And #define DialogConf$timeout 10 if you want the dialog to time out after 10 seconds.
4. Add the package file: #include "xobj_core/classes/packages/jas Dialog.lsl"
5. Compile. You can now utilize the dialog manager.

	5. Running methods
XOBJ uses a few standard functions to send or receive data:
  runMethod(string uuidOrLink, string className, integer method, list data, string callback)
    This is the standard function to run a method on a script.
    - uuidOrLink : Either a key of a prim or user to send to, or an integer prim in the linkset like (string)LINK_ROOT or (string)LINK_SET
    - className : The script to run the method on, by name. Ex: "jas Dialog"
    - method : A method defined in the recipient's header file. Ex: DialogMethod$spawn
    - data : Any parameters the method accepts, ex: [llGetOwner(), "A standard yes/no button", llList2Json(JSON_ARRAY, ["Yes", "No"]), 0]
    - callback : A string you'd like to receive as a callback upon successfully running the method. Use the constants NORET, JSON_INVALID or TNN will prevent callbacks. An empty string "", " " etc will only do a callback if there's any data to callback. Anything else will return your callback string, even if there was no other data to return.
    
A lot of the header scripts have predefined shortcuts also, so you won't have to type out all of that. For an example, jas Dialog has predefined:
  Dialog$spawn(user, message, buttons, menuID, callback)
So in your script you can just run:
  Dialog$spawn(llGetOwner(), "Dialog message", ["Button1", "Button2"], 0, "D")

	
	6. Events  
Events are ways to send data to an entire linkset rather than just a single module.
Each module that sends events has an event defined on top of the script.
Events are usually integers above 0 defined like #define ModuleNameEvt$eventname 1
To raise an event use raiseEvent((int)event, (str)data)
To capture events, define at the top of the script #define USE_EVENTS
Then create a function like onEvt(string module, integer evt, string data)
Module is the sender, evt is the event ID, and data is any data sent along with the event.
Never rely on event IDs directly always verify the module it came from ex:
if(module == "ModuleName" && evt == ModeulNameEvt$eventname)


    	7. Create a module.
Please see the module creation readme.

