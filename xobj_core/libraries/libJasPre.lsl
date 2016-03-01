// This here is the JasX preprocessor shortcut library
// They're basically just ways of using the preprocessor to let you do more in less code



// FOREACH LOOPS //
// Iterate an lsl list getting index and val, leaving the list as it is
	#define list_each(input, int, val, fnAction)  {integer int; for(int=0; int<llGetListLength(input); int++){ string val=llList2String(input, int); fnAction}}
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
	#define links_each(linknum, linkname, fnAction)  {integer linknum; for(linknum=llGetNumberOfPrims()>1; linknum<=llGetNumberOfPrims(); linknum++){ string linkname=llGetLinkName(linknum); fnAction}}
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

// Quickly set a value of an array
	#define set(arr, pos, val) arr = llListReplaceList(arr, [val], pos, pos)
	
// Removes the first element of a list and returns it - Cannot be run as a parameter or in a statement
#define shift(lst) llList2String(lst,0); lst=llDeleteSubList(lst,0,0)
	// Ex: list l = ["a", "b"]; string first = shift(l); first => "a" - l => ["b"]

// Removes the last element of a list and returns it - Cannot be run as a parameter or in a statement
#define pop(lst) llList2String(lst,-1); lst=llDeleteSubList(lst,-1,-1)
	// Ex: list l = ["a", "b"]; string last = pop(l); last => "b" - l => ["a"]
	


// BITWISE OPERATIONS
#define getBitArr(int, index, bytesize) ((cds>>(bytesize*index))&((integer)llPow(bytesize, 2)-1))
#define remBitArr(int, index, bytesize) (int&~(((integer)llPow(bytesize,2)-1)<<(bytesize*index)))
#define setBitArr(int, set, index, bytesize) (remBitArr(int, index, bytesize)|(set<<(bytesize*index)))
#define addBitArr(int, set, bytesize) ((int<<bytesize)|set)
// Moves all values left, removing any 0 values
integer flattenBitArr(integer int, integer bytesize){
    integer i; integer right;
    for(i=0; i<llFloor(32./bytesize); i++){
        integer b = getBitArr(int, i, bytesize);
        if(right){
            int = setBitArr(int, b, (i-right), bytesize);
            int = remBitArr(int, i, bytesize);
        }
        if(b == 0)right++;
    } 
    return int;
}
integer indexOfBitArr(integer int, integer find, integer bytesize){
    integer i;
    for(i=0; i<llFloor(32./bytesize);i++){
        if(getBitArr(int, i, bytesize) == find)return i;
    }
    return -1;
}
list bitArrToList(integer int, integer bytesize){
    list out;
    integer i; 
    for(i=0; i<llFloor(32./bytesize); i++)out+=getBitArr(int, i, bytesize);
    return out;
}

#define setFlag(bitfield, flag) bitfield = bitfield|flag
#define unsetFlag(bitfield, flag) bitfield = bitfield&~flag
	
	
// STRING //
// Quickly combine a list into a string
	#define implode(delim, lst) llDumpList2String(lst, delim)
// Shorter way to trim a string
	#define tr(input) llStringTrim(input, STRING_TRIM)
	#define trim(input) tr(input)
// Check if a string is not "" or JSON_INVALID
	#define isset(input) ((string)input!="" && (string)input!=JSON_INVALID)
	
	#define algo(math, vars) mathToFloat(math, 0, vars)
	
	
	
// JSON //
// Add an item to the end of a JSON ARRAY . Cannot be run as a parameter or in a statement
	#define json_push(input, val) input = llJsonSetValue(input, [-1], val);
	// Ex: string json = "[\"Rawr\", \"Meow\"]"; json_push(json, "Hiss"); - json = [\"Rawr\",\"Meow\",\"Hiss\"];
	
	#define mkobj(data) llList2Json(JSON_OBJECT, data)
	#define mkarr(data) llList2Json(JSON_ARRAY, data)
	

	
	
// GENERAL PSEUDONYMS //
// Lets you use elseif or elif instead of "else if"
#define elseif else if
#define elif else if

// Lets you use lowercase true or false
#define true TRUE
#define false FALSE
#define null ""
#define NULL null

#define bool integer
#define parseInt(input) (integer)(input)
#define str string
#define int integer
#define count(input) llGetListLength(input)

#define PP(link, params) llSetLinkPrimitiveParamsFast(link, params)

// Shortcut function that creates a 9 figure unix timestamp integer with 1/10th of a second precision
#define timeSnap() ((integer)(llGetSubString((string)llGetUnixTime(), -8, -1)+llGetSubString(llGetTimestamp(),-7,-7)))

// Shortcut for llJsonGetValue
#define jVal(obj, index) llJsonGetValue(obj, index)
#define j(obj, var) llJsonGetValue(obj, [var])

// Quickly set memory limit to a multiplier of current memory used
#define memLim(multi) llSetMemoryLimit(llCeil((float)llGetUsedMemory()*multi))

#define triggerSoundOn(id, sound, vol) {vector pos = llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0); llTriggerSoundLimited(sound, vol, pos + <0.1,0.1,0.1>, pos - <0.1,0.1,0.1>);}



// PRIM FUNCTIONS //
// Gets prim info by a uuid
#define prPos(prim) llList2Vector(llGetObjectDetails(prim, [OBJECT_POS]),0)
#define prRot(prim) llList2Rot(llGetObjectDetails(prim, [OBJECT_ROT]),0)
#define prDesc(prim) (string)llGetObjectDetails(prim, [OBJECT_DESC])
#define prLinkedToMe(prim) (llList2Key(llGetObjectDetails(prim, [OBJECT_ROOT]),0) == llGetKey())
#define prRoot(prim) llList2Key(llGetObjectDetails(prim, [OBJECT_ROOT]),0)
#define prAttachPoint(prim) llList2Integer(llGetObjectDetails(prim, [OBJECT_ATTACHED_POINT]), 0)

//#define prAngle(object, var, fwd) float var; {list odata =llGetObjectDetails(object, [OBJECT_POS]); var = llRot2Angle(llRotBetween(llVecNorm(fwd * llGetRot()), llVecNorm(llList2Vector(odata, 0)-llGetPos())));} 
//#define prAngle(object, var, fwd) float var; {list odata =llGetObjectDetails(object, [OBJECT_POS]); var = llRot2Angle(llRotBetween(fwd * llGetRot(), llList2Vector(odata, 0)-llGetPos()));} 
// Check if prim is in front of me
#define prAngle(object, var, rotOffset) float var; {vector temp = (prPos(object)-llGetRootPosition())/llGetRootRotation()*rotOffset; var = llAtan2(temp.y,temp.x);}
#define prAngX(object, var) prAngle(object, var, ZERO_ROTATION)
#define prAngZ(object, var) prAngle(object, var, llEuler2Rot(<0,PI_BY_TWO,0>))

#define myAng(object, var, rotOffset) float var; {vector temp = (llGetPos()-prPos(object))/prRot(object)*rotOffset; var = llAtan2(temp.y,temp.x);}
#define myAngX(object, var) myAng(object, var, ZERO_ROTATION)
#define myAngZ(object, var) myAng(object, var, llEuler2Rot(<0,PI_BY_TWO,0>))

// Check if I am in front of prim if VAR > PI_BY_TWO
#define myAngle(object, var) float var; {list odata =llGetObjectDetails(object, [OBJECT_POS, OBJECT_ROT]); vector vrot = llRot2Euler(llList2Rot(odata, 1)); rotation bet = llRotBetween(llVecNorm(<1,0,0> * llEuler2Rot(<0,0,vrot.z>)), llVecNorm(llGetPos()-llList2Vector(odata, 0))); var = llRot2Angle(bet);} 

// use in a list for llSetPrimitiveParams
#define linkAlpha(link, alpha, side) PRIM_LINK_TARGET, link, PRIM_COLOR, side, llList2Vector(llGetLinkPrimitiveParams(link, [PRIM_COLOR, side]), 0), alpha


#define boundsHeight(obj, var) float var; {list _bounds = llGetBoundingBox(obj); vector _a =llList2Vector(_bounds, 0); vector _b = llList2Vector(_bounds,1); var = (llFabs(_a.z)+llFabs(_b.z));}





// Vectors
#define vecBetween(a, b, distance) a-(llVecNorm(a-b)*distance)
// For on_rez position - uses 13+8+8 bits, leaving 3 for config
#define int2vec(input) <((input>>21)&255), ((input>>13)&255), (input&8191)>
#define vecFloor(input) <llFloor(input.x), llFloor(input.y), llFloor(input.z)>
#define vec2int(input) ((integer)input.x<<21)|((integer)input.y<<13)|(integer)input.z

