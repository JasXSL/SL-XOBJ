SL-XOBJ
=======

A modular approach to LSL with support for pseudo-object orientation

XOBJ is a framework for SL in an attempt to make a more modular approach.
xobj treats each script like a module, using events and "methods" to easily let you drop in any module into any project, making code easy to reuse
xobj supports the following features:
- Script events
- Standardized script methods with callbacks
- Linkset-wide shared variables
- Ability to create and modify objects in a pseudo-object-oriented fashion
- A general library for preprocessor shortcuts (like lowercase true/false and foreach loops)

Note: xobj_core requires the firestorm viewer

Create your first project:
		1. Enable preprocessing
Open a script window, click the cogs icon at the top and check Enable LSL preprocessor, Script optimizer and #includes from local disk.
The other checkboxes are optional.
Select a path to where you want your root include folder to be. Ex: C:\LSL
Extract the xobj_core folder (and xobj_toonie if you want to use that) into your newly created folder. Ex: C:\LSL\xobj_core
Close and re-open your script window.
Now you have installed the core and will not have to re-install it for future projects.

		2. Creating a new project
Create a subfolder under your includes on disk. Ex: C:\LSL\MyFirstProject
Create a file in that folder and name it _core.lsl (The name doesn't really matter, just remember it for now)
In the first line of _core.lsl enter #include "xobj_core/_ROOT.lsl"
Hit enter. LSL include files must always end with a blank line
Save your file.
Create a new script in LSL and name it #ROOT or anything you like really, that script in particular will serve as the standard input and does not neccessarily have to be accessed directly. On the first line, enter #include "MyFirstProject/_core.lsl" and save. For root implementation examples, see the #ROOT implementations readme.
Note that a #ROOT script is not needed if you don't need a linkset to accept external commands (like touch_start, listen, control etc)


    	3. Setting up shared vars (optional)
Shared vars are used for scripts to get variables from another script. Ex a script called "st User" might choose to share an object containing user info like {(key)id:(string)species}
This could then be accessed by "st UserInfo" that could call something like:
    string species = _shared("st User", ["userData", "cf2625ff-b1e9-4478-8e6b-b954abde056b"]);

To do so, you need one or more cubes added to the linkset to serve as a database. Each prim can serve up to 9 scripts at a time (-1 for the first cube as it's needed for indexing) allocating 2048 bytes of data.
1. Create a new cube and name it DB0
2. Set the cube's path-cut to any value above 0
3. Set the cube's hollow to any value about 0
4. Make your object fully transparent and link it to your linkset (ex: your HUD)
5. Please note that textures on this prim will not be visible, so keep it hidden
(Protip: Setting the cube's physics shape to convex-hull will help you save prims if the linkset is rezzed)
Note: If you get an error about DB being full, you can create additional database prims, just name them DB1, DB2 etc
Create a new script in the root prim of your linkset and name it exactly "cl SharedVars"
In your cl SharedVars script, put only one line: #include "xobj_core/classes/packages/cl SharedVars.lsl"
Compile that script.
You can now save or read shared vars in any script of the linkset.

Constants:
  If you wish to prevent a script from using shared vars (conserving a little memory) enter at the top of the script:
    #define DISREGARD_SHARED
  If you wish to use a different prefix of your DB cubes (default DB0, DB1 etc) enter at the top ex:
    #define SharedVarsConst$dbPrimPrefix "newPrefix"
Functions:
  These functions can be used at any time:
    initShared(); <- Recommended that you put in state_entry. Shared vars will try to initialize once the project starts, but due to delay might be dropped.
    _saveShared(list index, string val); <- Saves a variable by index to the running script's shared vars.
      Ex: _saveShared(["users", "cf2625ff-b1e9-4478-8e6b-b954abde056b"], "lynx")
    _saveSharedScript(string script, list index, string val) - Same as above but lets you specify a specific script's shared vars to modify, use with caution
    _shared(string script, list index) <- Lets you read shared vars from a script
      Ex: _shared("st Users", ["users", "cf2625ff-b1e9-4478-8e6b-b954abde056b"]) <- Returns "lynx"
Events:
  SharedVars raises the following Events:
    0: SharedVarsEvt$changed <- {o:(var)oldData, n:(var)newData, v:(arr)index, s:(str)script}
    
    
    	4. Adding a module
Scripts in XOBJ can be called modules. A module ALWAYS consists of at least one header file which contains preprocessor definitions, and optionally one package file (if you want to share it) containing the actual code. You can always write the code of the package file directly in SL if you don't intend on sharing it.

To add a pre-existing module you'll want to start by including your project core, then define any config definitions, and finally including the package file. Install the dialog manager:
1. Create a new script in your project. Name it exactly "cl Dialog"
2. Open the script, delete all the code and add on the first line: #include "MyFirstProject/_core.lsl"
3. Next set any config definitions you want. Ex #define DialogConf$ownerOnly 0 if you do not want to limit the dialog to the script owner. And #define DialogConf$timeout 10 if you want the dialog to time out after 10 seconds.
4. Add the package file: #include "xobj_core/classes/packages/cl Dialog.lsl"
5. Compile. You can now utilize the dialog manager.

	5. Running methods
XOBJ uses a few standard functions to send or receive data:
  runMethod(string uuidOrLink, string className, integer method, list data, string findObj, string in, string callback, string customTarg)
    This is the standard function to run a method on a script.
    - uuidOrLink : Either a key of a prim or user to send to, or an integer prim in the linkset like (string)LINK_ROOT or (string)LINK_SET
    - className : The script to run the method on, by name. Ex: "cl Dialog"
    - method : A method defined in the recipient's header file. Ex: DialogMethod$spawn
    - data : Any parameters the method accepts, ex: [llGetOwner(), "A standard yes/no button", llList2Json(JSON_ARRAY, ["Yes", "No"]), 0]
    - findObj : (Obj package scripts only) - A parameter value
    - in : (Obj package scripts only) - A parameter key
    - callback : A string you'd like to receive as a callback upon successfully running the method.
    - customTarg : (exteral coms only) Limits a method to objects by name. Like if you are using the attachment package to attach multiple objects to yourself, you can send a method to llGetOwner() with AttachedMethod$remove and limit it to "Attachment1" which would only detach any attachments named "Attachment1"
    
    Since the three last parameters are situational, you can use the constant TNN to shorten your code. Ex:
  runmethod((string)LINK_THIS, "cl Dialog", DialogMethod$spawn, [llGetOwner(), "DialogText", llList2Json(JSON_ARRAY, ["Button1" "Button2"]), 0], TNN);

A lot of the header scripts have predefined shortcuts also, so you won't have to type out all of that. For an example, cl Dialog has predefined:
  Dialog$spawn(user, message, buttons, menuID, callback)
So in your script you can just run:
  Dialog$spawn(user, message, buttons, menUID, callback)
  
Please note that you need to include a module's header file if you wish to access it. So if you want to utilize the dialog manager in a script, you need to start by #include "cl Dialog.lsl"

    6. Create a module.
Please see the module creation readme.

