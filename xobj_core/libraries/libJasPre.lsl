// This here is the JasX preprocessor shortcut library
// They're basically just ways of using the preprocessor to let you do more in less code


// FOREACH LOOPS //
// Iterate an lsl list getting index and val, leaving the list as it is
	#define list_each(input, int, val, fnAction)  integer int; for(int=0; int<llGetListLength(input); int++){ string val=llList2String(input, int); fnAction}
	// Ex: list_each(myList, k, v, {llSay(0, (string)k+" => "+v);})

// Iterate  an lsl list, deleting each value after it's been run
	#define list_shift_each(input, val, fnAction) while(llGetListLength(input)){string val = llList2String(input,0); input = llDeleteSubList(input,0,0); fnAction}
	// Ex: list_shift_each(myList, v, {llSay(0, v+" has been iterated over and is now removed");})

// Iterate over a JSON OBJECT ARRAY
	#define objarr_each(input, num, k, val, fnAction) {integer num; for(num; num<llGetListLength(input); num+=2){ string k=llList2String(input,num); string val=llList2String(input, num+1); fnAction}}
	// Ex: list myList = llJson2List(jsonObject); objarr_each(myList, num, k, v, {llSay(0, (string)k+" => "+v+" on index: "+(string)(num/2));})

// Iterate over a JSON OBJECT STRING
	#define obj_each(input, k, val, fnAction) {list L = llJson2List(input); while(llGetListLength(L)){ string k=llList2String(L,0); string val=llList2String(L, 1); L = llDeleteSubList(L,0,1); fnAction}}
	// Ex: obj_each(jsonObject, k, v, {llSay(0, k+" => "+v);});
	
// Iterate over links with link nr and link name
	#define links_each(linknum, linkname, fnAction)  integer linknum; for(linknum=1; linknum<=llGetNumberOfPrims(); linknum++){ string linkname=llGetLinkName(linknum); fnAction}
	// Ex: links_each(num, name, {llSay(0, "Link #"+(string)num+" is called: "+name);});
	
	
	
	
	
	
// LISTS //
// Set a value of a [key, val, key, val] list by key. If key is not set, it's added to the list.
	#define objarr_set(input, k, val) {integer _p = llListFindList(input, [k]); if(~_p){input = llDeleteSubList(input,_p,_p+1);} input = llListInsertList(input, [k, val], _p); }
	// Ex: list l = ["jas","cat", "toonie","panda"]; objarr_set(l, "toonie", "red_panda"); -> ["jas","cat", "toonie","red_panda"]

// Get a single random element from a list
	#define randElem(l) llList2String(l, llFloor(llFrand(llGetListLength(l))))

// Remove all items form a list by name - Cannot be run as a parameter or in an if statement.
	#define remByVal(lst, val) {integer pos;while(~(pos=llListFindList(lst, [val]))){lst = llDeleteSubList(lst,pos,pos);}}
	// Ex: list l = ["a", "a", "b"]; remByVal(l, "a"); llList2CSV(l) => ["b"]

// Quickly split a string into a list
	#define explode(delim, str) llParseString2List(str, [delim], [])

// Removes the first element of a list and returns it - Cannot be run as a parameter or in a statement
#define shift(lst) llList2String(lst,0); lst=llDeleteSubList(lst,0,0)
	// Ex: list l = ["a", "b"]; string first = shift(l); first => "a" - l => ["b"]

// Removes the last element of a list and returns it - Cannot be run as a parameter or in a statement
#define pop(lst) llList2String(lst,-1); lst=llDeleteSubList(lst,-1,-1)
	// Ex: list l = ["a", "b"]; string last = pop(l); last => "b" - l => ["a"]
	

	
	
	
	
	
// STRING //
// Quickly combine a list into a string
	#define implode(delim, lst) llDumpList2String(lst, delim)
// Shorter way to trim a string
	#define tr(input) llStringTrim(input, STRING_TRIM)
// Check if a string is not "" or JSON_INVALID
	#define isset(input) ((string)input!="" && (string)input!=JSON_INVALID)
	
	
	
	
// JSON //
// Add an item to the end of a JSON ARRAY . Cannot be run as a parameter or in a statement
	#define json_push(input, val) input = llJsonSetValue(input, [-1], val);
	// Ex: string json = "[\"Rawr\", \"Meow\"]"; json_push(json, "Hiss"); - json = [\"Rawr\",\"Meow\",\"Hiss\"];



	
	
// GENERAL PSEUDONYMS //
// Lets you use elseif or elif instead of "else if"
#define elseif else if
#define elif else if

// Lets you use lowercase true or false
#define true TRUE
#define false FALSE

// Shortcut for llJsonGetValue
#define jVal(obj, index) llJsonGetValue(obj, index)

// Quickly set memory limit to a multiplier of current memory used
#define memLim(multi) llSetMemoryLimit(llCeil((float)llGetUsedMemory()*multi))





// PRIM FUNCTIONS //
// Gets prim info by a uuid
#define prPos(prim) llList2Vector(llGetObjectDetails(prim, [OBJECT_POS]),0)
#define prDesc(prim) (string)llGetObjectDetails(prim, [OBJECT_DESC])
#define prLinkedToMe(prim) (llList2Key(llGetObjectDetails(prim, [OBJECT_ROOT]),0) == llGetKey())
#define prRoot(prim) llList2Key(llGetObjectDetails(prim, [OBJECT_ROOT]),0)

// "Shortcuts" to set bitfield flags
#define setFlag(bitfield, flag) bitfield = bitfield|flag
#define unsetFlag(bitfield, flag) bitfield = bitfield&~flag



