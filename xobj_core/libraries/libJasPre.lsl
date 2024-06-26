#ifndef _libJasPre
#define _libJasPre
// This here is the JasX preprocessor shortcut library
// They're basically just ways of using the preprocessor to let you do more in less code

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
#define parseInt(input) ((integer)(input))
#define floor(input) parseInt(input)
#define str string
#define int integer
#define count(input) (input != [])	// Sorcery!
#define Infinity 340282356779733642748073463979561713664.00000000
#define NaN ((float)"nan")
#define ONE_VECTOR <1.0,1.0,1.0>
#define MAXINT 0x7FFFFFFF
#define fabs(X) X*(-1*((X<0.0)-(X>0.0)))

// Ternary operation that works for floats, ints and vectors
#define ternaryNum(statement, a, b) (a*((statement)!=0))+(b*(!(statement)))

// Max and Min Functions and Unit Tests
// Emilie (Hermit Barber in World)
// Creative Commons: Attribution, Share-alike, Non Commecial
#define max2(x,y) \
	( ( llAbs( (x) >= (y) ) ) * (x) ) + ( ( llAbs( (x)<(y) ) ) * (y) )
#define min2(x,y) \
	( ( llAbs( (x) >= (y) ) ) * (y) ) + ( ( llAbs( (x)<(y) ) ) * (x) )


#define l2i(input, index) llList2Integer(input, index)
#define l2v(input, index) llList2Vector(input, index)
#define l2f(input, index) llList2Float(input, index)
#define l2s(input, index) llList2String(input, index)
#define l2k(input, index) llList2Key(input, index)
#define l2r(input, index) llList2Rot(input, index)

#define translateStop() llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP])
#define inRange(id, range) (llVecDist(llList2Vector(llGetObjectDetails(id,[OBJECT_POS]),0),llGetRootPosition())<range)
#define alnum(text) (~llSubStringIndex(llEscapeURL(text), "%"))

// FOREACH LOOPS //
// Iterate an lsl list getting index and val, leaving the list as it is
	#define list_each(input, n, val, fnAction)  {integer n; for(n=0; n<llGetListLength(input); n++){ string val=llList2String(input, n); fnAction}}
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
	
	
	
#define integerLizeKey(id, salt) ((integer)("0x1"+llGetSubString(id, 0, 6))+salt)
	
	
// LISTS //
// Set a value of a [key, val, key, val] list by key. If key is not set, it's added to the list.
	#define objarr_set(input, k, val) {integer _p = llListFindList(input, [k]); if(~_p){input = llDeleteSubList(input,_p,_p+1);} input = llListInsertList(input, [k, val], _p); }
	// Ex: list l = ["jas","cat", "toonie","panda"]; objarr_set(l, "toonie", "red_panda"); -> ["jas","cat", "toonie","red_panda"]

// Get a single random element from a list
	#define randElem(l) llList2String(l, floor(llFrand(llGetListLength(l))))

// Remove all items form a list by name - Cannot be run as a parameter or in an if statement.
	#define remByVal(lst, val) {integer pos;while(~(pos=llListFindList(lst, [val]))){lst = llDeleteSubList(lst,pos,pos);}}
	// Ex: list l = ["a", "a", "b"]; remByVal(l, "a"); llList2CSV(l) => ["b"]

// Quickly split a string into a list
	#define explode(delim, input) llParseStringKeepNulls(input, [delim], [])

// Quickly set a value of an array
	#define set(arr, pos, val) arr = llListReplaceList(arr, [val], pos, pos)
	
// Removes the first element of a list and returns it - Cannot be run as a parameter or in a statement
#define shift(lst) llList2String(lst,0); lst=llDeleteSubList(lst,0,0)
	// Ex: list l = ["a", "b"]; string first = shift(l); first => "a" - l => ["b"]

// Removes the last element of a list and returns it - Cannot be run as a parameter or in a statement
#define pop(lst) llList2String(lst,-1); lst=llDeleteSubList(lst,-1,-1)
	// Ex: list l = ["a", "b"]; string last = pop(l); last => "b" - l => ["a"]

// input is a list, start is an index, and length is how many elements to return
#define subarr(input, start, length) llList2List(input, start, start+length-1)
// Same as above but uses delete
#define subarrDel(input, start, length) llDeleteSubList(input, start, start+length-1)


// BITWISE OPERATIONS
#define getBitArr(n, index, bytesize) ((n>>(bytesize*index))&((integer)llPow(2, bytesize)-1))
#define remBitArr(n, index, bytesize) (n&~(((integer)llPow(bytesize,2)-1)<<(bytesize*index)))
#define setBitArr(n, set, index, bytesize) (remBitArr(n, index, bytesize)|(set<<(bytesize*index)))
#define addBitArr(n, set, bytesize) ((n<<bytesize)|set)
// Moves all values left, removing any 0 values
integer flattenBitArr(integer n, integer bytesize){
    integer i; integer right;
    for(i=0; i<(int)(32./bytesize); i++){
        integer b = getBitArr(n, i, bytesize);
        if(right){
            n = setBitArr(n, b, (i-right), bytesize);
            n = remBitArr(n, i, bytesize);
        }
        if(b == 0)right++;
    } 
    return n;
}
integer indexOfBitArr(integer n, integer find, integer bytesize){
    integer i;
    for(i=0; i<(int)(32./bytesize);i++){
        if(getBitArr(n, i, bytesize) == find)return i;
    }
    return -1;
}
list bitArrToList(integer n, integer bytesize){
    list out;
    integer i; 
    for(i=0; i<(int)(32./bytesize); i++)out+=getBitArr(n, i, bytesize);
    return out;
}

#define setFlag(bitfield, flag) bitfield = bitfield|flag
#define unsetFlag(bitfield, flag) bitfield = bitfield&~flag

// Debug outputs all bits set in flags
#define debugBitSplit(flags) \
	integer i; for(i=0; i<32; ++i){ \
		if(flags&(int)llPow(2, i)){ \
			qd((str)flags+" Has bit: "+(str)((int)(llPow(2,i)))+" [0x"+bits2nybbles((int)llPow(2,i))+"]"); \
	}}
	
// STRING //
// Quickly combine a list into a string
	#define implode(delim, lst) llDumpList2String(lst, delim)
// Shorter way to trim a string
	#define tr(input) llStringTrim(input, STRING_TRIM)
	#define trim(input) tr(input)
// Check if a string is not "" or JSON_INVALID
	#define isset(input) ((string)input!="" && (string)input!=JSON_INVALID)
	// Returns string length
	#define strlen(input) llStringLength(input)
	// Returns true if string starts with
	#define startsWith(input, check) (llGetSubString(input, 0, strlen(check)-1) == check)
	// Returns the input characters after begins string length
	#define strAfter(input, begins) llGetSubString(input, strlen(begins), -1)



// INVENTORY //
	#define stopAllObjectAnimations() {list l = llGetObjectAnimationNames(); integer i; for(;i<count(l);++i)llStopObjectAnimation(l2s(l,i));}
	#define invAnim(index) llGetInventoryName(INVENTORY_ANIMATION, index)
	#define invObj(index) llGetInventoryName(INVENTORY_OBJECT, index)
	
	
// ANIMESH //
	#define restartObjectAnimation(animation) \
		llStopObjectAnimation(animation);\
		llStartObjectAnimation(animation)
	
	
// NUMBER //
// Round a float to a decimal and return a string
	#define roundTo(number, decimals) llGetSubString((string)(llRound(number*llPow(10, decimals))/llPow(10, decimals)), 0, -7+decimals)
	#define max(values) l2i(llListSort(values, 1, FALSE),0)
	#define min(values) l2i(llListSort(values, 1, TRUE),0)
	
// JSON //
// Add an item to the end of a JSON ARRAY . Cannot be run as a parameter or in a statement
	#define json_push(input, val) input = llJsonSetValue(input, [-1], val);
	// Ex: string json = "[\"Rawr\", \"Meow\"]"; json_push(json, "Hiss"); - json = [\"Rawr\",\"Meow\",\"Hiss\"];
	
	#define mkobj(data) llList2Json(JSON_OBJECT, data)
	#define mkarr(data) llList2Json(JSON_ARRAY, data)
	


// Get+set material macros for use like llSetLinkPrimitiveParamsFast(gsmColor(link, face, color))
// alternative to PRIM_COLOR for materials. Note that using more than one face at a time is destructive if there's more than one material
#define gsmColor(link, face, color, alpha) (list)PRIM_GLTF_BASE_COLOR + face + llListReplaceList(llGetLinkPrimitiveParams(link, (list)PRIM_GLTF_BASE_COLOR + face), (list)(color) + (alpha), 4,5)
#define gsmTexture(link, face, texture) (list)PRIM_GLTF_BASE_COLOR + face + llListReplaceList(llGetLinkPrimitiveParams(link, (list)PRIM_GLTF_BASE_COLOR + face), (list)(texture), 0,0)
#define gsmFullbright(link, face, color) (list)PRIM_GLTF_EMISSIVE + face + llListReplaceList(llGetLinkPrimitiveParams(link, (list)PRIM_GLTF_EMISSIVE + face), (list)(color), 4,4)

// Show or hide object by using materials. Show expects the material to have no alpha
#define hideMaterial(link, face) llSetLinkPrimitiveParams(link, (list)PRIM_GLTF_BASE_COLOR + face + l2k(llGetLinkPrimitiveParams(link, (list)PRIM_GLTF_BASE_COLOR + face), 0) + "" + "" + "" + "" + 0 + PRIM_GLTF_ALPHA_MODE_MASK + 1.0 + FALSE)
#define showMaterial(link, face) llSetLinkPrimitiveParams(link, (list)PRIM_GLTF_BASE_COLOR + face + l2k(llGetLinkPrimitiveParams(link, (list)PRIM_GLTF_BASE_COLOR + face), 0) + "" + "" + "" + "" + 1 + 0 + 0 + FALSE)


//#define gsmNormalOffset(link, face, repeats, offsets, rot) PRIM_GLTF_NORMAL + face + llListReplaceList(llGetLinkPrimitiveParams(link, (list)PRIM_GLTF_BASE_COLOR + face), (list)alpha, 5,5)


#define PP(link, params) llSetLinkPrimitiveParamsFast(link, params)

// Put on top of detected key and listen respectively to limit to owner
#define detOwnerCheck if(llDetectedKey(0) != llGetOwner())return;
#define idOwnerCheck if(llGetOwnerKey(id) != llGetOwner())return;

// Shortcut function that creates a 9 figure unix timestamp integer with 1/10th of a second precision
#define timeSnap() ((llGetUnixTime()%100000000)*10+(int)llGetSubString(llGetTimestamp(),-7,-7))

// Shortcut for llJsonGetValue
#define jVal(obj, index) llJsonGetValue(obj, index)
#define j(obj, var) llJsonGetValue(obj, (list)var)
#define js(obj, index, val) llJsonSetValue(obj, [index], (str)val)

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
#define prSpawner(prim) llList2Key(llGetObjectDetails(prim, [OBJECT_REZZER_KEY]), 0)
#define prPhantom(prim) llList2Integer(llGetObjectDetails(prim, [OBJECT_PHANTOM]), 0)


// Returns prim that spawned this
#define mySpawner() llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0)

//#define prAngle(object, var, fwd) float var; {list odata =llGetObjectDetails(object, [OBJECT_POS]); var = llRot2Angle(llRotBetween(llVecNorm(fwd * llGetRot()), llVecNorm(llList2Vector(odata, 0)-llGetRootPosition())));} 
//#define prAngle(object, var, fwd) float var; {list odata =llGetObjectDetails(object, [OBJECT_POS]); var = llRot2Angle(llRotBetween(fwd * llGetRot(), llList2Vector(odata, 0)-llGetRootPosition()));} 
// Check if prim is in front of me
#define prAngleOn(object, var, rotOffset) vector temp = (prPos(object)-llGetRootPosition())/llGetRootRotation()*rotOffset; var = llAtan2(temp.y,temp.x)
#define prAngle(object, var, rotOffset) float var; {vector temp = (prPos(object)-llGetRootPosition())/llGetRootRotation()*rotOffset; var = llAtan2(temp.y,temp.x);}
#define prAngX(object, var) prAngle(object, var, ZERO_ROTATION)
#define prAngZ(object, var) prAngle(object, var, llEuler2Rot(<0,PI_BY_TWO,0>))
// Checks if I am in front of prim
#define myAng(object, var, rotOffset) float var; {vector temp = (llGetRootPosition()-prPos(object))/prRot(object)*rotOffset; var = llAtan2(temp.y,temp.x);}
#define myAngX(object, var) myAng(object, var, ZERO_ROTATION)
#define myAngZ(object, var) myAng(object, var, llEuler2Rot(<0,PI_BY_TWO,0>))

// Checks if obj is in front of targ using positive X from targ rotation
#define angInFrontOfObj( obj, targ, var ) \
	float var; {vector temp = (prPos(obj)-prPos(targ))/prRot(targ); var = llAtan2(temp.y,temp.x);}

// Checks if position A is in front of pos Bp rot Br and assigns the value to var C
#define posAngX( A, Bp, Br, C ) {vector temp = (A-Bp)/Br; C = llAtan2(temp.y,temp.x);}


#define pointBetween(a, b, distance) \
        (a+llVecNorm(b-a)*distance)

// Check if I am in front of prim if VAR > PI_BY_TWO
#define myAngle(object, var) float var; {list odata =llGetObjectDetails(object, [OBJECT_POS, OBJECT_ROT]); vector vrot = llRot2Euler(llList2Rot(odata, 1)); rotation bet = llRotBetween(llVecNorm(<1,0,0> * llEuler2Rot(<0,0,vrot.z>)), llVecNorm(llGetRootPosition()-llList2Vector(odata, 0))); var = llRot2Angle(bet);} 

// use in a list for llSetPrimitiveParams
#define linkAlpha(link, alpha, side) PRIM_LINK_TARGET, link, PRIM_COLOR, side, llList2Vector(llGetLinkPrimitiveParams(link, [PRIM_COLOR, side]), 0), alpha


#define boundsHeight(obj, var) float var; {list _bounds = llGetBoundingBox(obj); vector _a =llList2Vector(_bounds, 0); vector _b = llList2Vector(_bounds,1); var = (fabs(_a.z)+fabs(_b.z));}

#define norm2rot(normal, axis) llAxes2Rot(llVecNorm(normal % axis) % normal, llVecNorm(normal % axis), normal)

#define rotMag( rot ) llSqrt(rot.x*rot.x+rot.y*rot.y+rot.z*rot.z+rot.s*rot.s)
#define rotDiv( rot, div ) <rot.x/div, rot.y/div, rot.z/div, rot.s/div>

// Returns a vector based on the global Z axis rotation of targ, with angle (radians) added
// Good for getting a position based on an avatar. Like rotation rot = prRot(targ); vector offs = zRotNorm(PI, rot) gets a vector pointing 1m behind targ
// zRotMag is a helper
#define zRotMag( rot ) \
	llSqrt(rot.z*rot.z+rot.s*rot.s)
// 
// Returns a vector based on angle multiplied by zrot. PI = right behind you. 0 = right in front
#define zRotNorm( angle, rot ) \
	 (<llCos(angle),llSin(angle),0>*<0,0,rot.z/zRotMag(rot),rot.s/zRotMag(rot)>)


#define xLookAt(pos) llRotLookAt(llRotBetween(<1,0,0>, llVecNorm(pos-llGetPos())), 1, 1)
#define xLookAtLinked(link, pos) llSetLinkPrimitiveParamsFast(link, (list)PRIM_ROTATION + llRotBetween(<1,0,0>, llVecNorm(pos-llGetPos())))


// Vectors
#define vecBetween(a, b, distance) a-(llVecNorm(a-b)*distance)
// For on_rez position - uses 13+8+8 bits, leaving 3 for config
#define int2vec(input) <((input>>21)&255), ((input>>13)&255), (input&8191)>
#define vecFloor(input) <floor(input.x), floor(input.y), floor(input.z)>
#define vec2int(input) ((integer)input.x<<21)|((integer)input.y<<13)|(integer)input.z
// Reflects a direction based on a surface normal. Normal must be normalized
#define reflect(dir, norm) (llVecNorm(dir) - norm*(2*(llVecNorm(dir)*norm)))*llVecMag(dir)


#endif
