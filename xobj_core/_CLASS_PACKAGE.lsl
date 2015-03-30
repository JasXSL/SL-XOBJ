/*
	
	A package module extends the static module, adding pseudo-object-oriented features.
	A package module contains a list of objects, and an index for those objects
	When running a method on a package module, you will need to include a key and value pair to search for in the object list
	If those objects are found, that object it set to ACTIVE and the functions inside the package module will work on the ACTIVE object
	
	At the top of the package module script you'll want to define an index
	Whereas you can search through object member vars without an index, it will be a lot slower
	Defining an index is as simple as #define INDEXES [varName, varName2...]
	Ex if you have a charkey member in the object: #define INDEXES ["charkey"]
	
	I suggest using constants also. So if you want to create a class that contains species and name of an agent and name your script "cl Agents" you'd want to do something like:
	
	#define AgentsVar$name "a"
	#define AgentsVar$species "b"
	#define AgentsVar$key "c"
	
	#define INDEXES [AgentsVar$name, AgentsVar$key]
	
	You could make your construct function like (make sure to wrap lists in additional parentheses in preprocessor functions or the preprocessor will bug out):
	integer __construct(list args){	// (key)id, (string)name, (string)species
		cls$push(([
			AgentsVar$key, llList2Key(args,0),
			AgentsVar$name, llList2String(args,1),
			AgentsVar$species, llList2String(args,2)
		]));
	}
	
	Then add an object like
	runMethod((string)LINK_ROOT, "cl Agents", stdMethod$insert, ["cf2625ff-b1e9-4478-8e6b-b954abde056b", "Jasdac", "Lynx"], TNN);
	
	
	As an example if you want a function to output the agent's species you could do:
	outputSpecies(){
		if(UNINITIALIZED){llOwnerSay("Player not found."); return;}
		llOwnerSay(this(AgentsVar$species));
	}
	
	Then define a method for it
	#define AgentsMethod$outputSpecies 1 // Cannot be negative
	
	And from another script you'd call it by
	runMethod((string)LINK_ROOT, "cl Agents", AgentsMethod$outputSpecies, [], "Jasdac", AgentsVar$name, "", "");
	
	Jasdac is the object to search for and AgentsVar$name is the key to find Jasdac in.
	
*/



// These are globals needed to store objects and track the current index. An index of -1 means no object is set to work on
list _OBJECTS;
list _INDEX;
list _INDEX_VARS = INDEXES;
integer CURRENT_WORK_OBJECT = -1;	// Index
#define UNINITIALIZED (CURRENT_WORK_OBJECT == -1)






// A package allows you to use this$ to work on the ACTIVE object
	// Get a member of the current object
	#define this(param) llJsonGetValue(llList2String(_OBJECTS, CURRENT_WORK_OBJECT), [param])
	// Replace the entire object with a new one
	#define this$replace(data)if(~CURRENT_WORK_OBJECT){ _OBJECTS = llListReplaceList(_OBJECTS, data, CURRENT_WORK_OBJECT, CURRENT_WORK_OBJECT); __rebuildIndex();}
	// Sets a property of the current object
	#define this$setProperty(var, val) _OBJECTS = llListReplaceList(_OBJECTS, [llJsonSetValue(llList2String(_OBJECTS, CURRENT_WORK_OBJECT), [var], (string)val)], CURRENT_WORK_OBJECT, CURRENT_WORK_OBJECT); __rebuildIndex()
	// Remove the current object
	#define this$remove() if(~CURRENT_WORK_OBJECT){__remove(CURRENT_WORK_OBJECT); __rebuildIndex();}
	// Get the current work object as a string
	#define this$data llList2String(_OBJECTS, CURRENT_WORK_OBJECT)


// Class methods are methods that are run on the package module, manipulating the index or adding new objects
	// Sets the last added object as ACTIVE
	#define cls$setLast() CURRENT_WORK_OBJECT = llGetListLength(_OBJECTS)-1
	// Sets the ACTIVE object using an integer representing the object's index in the _OBJECTS list
	#define cls$setIndex(index) CURRENT_WORK_OBJECT = (integer)index
	// Cycles through all objects in the package module
	#define cls$each(index, obj, fnAction)  integer index; for(index=0; index<llGetListLength(_OBJECTS); index++){ string obj=llList2String(_OBJECTS, index); fnAction}
	// Adds a new object to the end of the object list
	#define cls$push(arr) _OBJECTS+=llList2Json(JSON_OBJECT, arr); __rebuildIndex()
	// Sets the ACTIVE object to NONE
	#define cls$clear() CURRENT_WORK_OBJECT = -1
	// Gets the list index of the current ACTIVE object
	#define cls$index CURRENT_WORK_OBJECT

// Class properties
	// Gets nr of objects in the package module
	#define cls$length llGetListLength(_OBJECTS)




// Default methods - You'll want to expand and overwrite these in each package module script.
// Standard constructor
integer __construct(list args){return FALSE;}
#define fn_arg(index) llList2String(args, index) // Shortcut to get an argument from a construct
__destruct(){} // Raised before current object is deleted
__indexed(){}	// Raised after re-indexed


// Automated, do not edit these

// Rebuilds the index, making reads/writes a lot faster
__rebuildIndex(){
	#ifdef INDEXES
	_INDEX = [];
	integer i;
	for(i; i<llGetListLength(_INDEX_VARS); i++)_INDEX+="[]";
	cls$each(index, obj, {
		list_each(_INDEX_VARS, k, v, {
			string dta = llList2String(_INDEX, k);
			json_push(dta, llJsonGetValue(obj, [v]));
			_INDEX = llListReplaceList(_INDEX, [dta], k, k);
		});
	});
	__indexed();
	#endif
}
// 
__remove(integer index){
	if(CURRENT_WORK_OBJECT < 0)return;
	__destruct();
	_OBJECTS = llDeleteSubList(_OBJECTS, CURRENT_WORK_OBJECT, CURRENT_WORK_OBJECT);
	CURRENT_WORK_OBJECT = -1;
	#ifdef INDEXES
	__rebuildIndex();
	#endif
}
integer __add(list args){
	integer ret = __construct(args); 
	__rebuildIndex(); 
	return ret;
}
list __search(string SEARCH, string IN){
    list WORK_OBJS = [-1];
    if(SEARCH != "" && IN != ""){
        WORK_OBJS = [];
        integer pos = llListFindList(_INDEX_VARS, [IN]); // Data 2 is index
        if(~pos){
            list idx = llJson2List(llList2String(_INDEX, pos));
            list_each(idx, i, val, {
                if(val == SEARCH)WORK_OBJS+=i;
            });
        }else{
            // Deep scan
            cls$each(idx, obj, {
                if(llJsonGetValue(obj, [IN]) == SEARCH)WORK_OBJS+=idx;
            });
        }
    }
    return WORK_OBJS;
}



