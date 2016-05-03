/*
	
	A static module is basically just a script that utilizes the framework. It has a few rudimentary features and leaves the rest of the development up to you.
	If you're not looking into storing a bunch of JSON objects to work on, this is the recommended type.
	Static modules are extended by package modules, so everything you can use in a static module can be used in a package module, but not vice versa
	
*/

// Shortcut to get the script name
	#define cls$name llGetScriptName()

// Shortcut to get a method argument
	#define method_arg(index) llList2String(PARAMS, index)

// Check if a method is called by a script within the same linkset, OR by the object's owner
	#define method$byOwner (id == "" || llGetOwnerKey(id) == llGetOwner())

// Check if a method is called by a script within the same linkset
	#define method$internal id == ""

// Check if a method was a callback
	#define method$isCallback nr == METHOD_CALLBACK



