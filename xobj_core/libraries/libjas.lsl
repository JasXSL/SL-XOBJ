/*
Very rudimentary and can probably be written better.
You cant do a number immediately followed by a parentheses, ex: "3(4+6)". Use "3*(4+6)" instead.

Usage example:
string variables = llList2Json(JSON_OBJECT, ["x", 4]);
string algorithm = "10+RAND(x*2)/2";
llSay(0, algorithm+" (Where: "+variables+")  = "+(string)algo(algorithm, 0, variables));
*/

float algo(string al, integer part, string varObj){
    list parts = [
        "(,)",              // Parentheses work different in that they are calculated separately
        "RAND",             // This is the math order inverse
        "+,-",              // AS
        "*,/",              // MD
        "^"                 // E
    ];
    list exp = llCSV2List(llList2String(parts,part));
    float val;
    integer i; 
    
    list split = llParseString2List(al, [], exp);

    if(part == 0){
        for(i=0; i<llGetListLength(split); i++){
            string str = llStringTrim(llList2String(split,i), STRING_TRIM);
            if(str == "("){
                integer x; integer ps = 1; list out;
                for(x = i+1; x<llGetListLength(split); x++){
                    if(llList2String(split,x) == "(")ps++;
                    else if(llList2String(split,x) == ")") ps--;
                    out+=llList2String(split, x);
                    if(ps == 0 || x>=llGetListLength(split)){
                        float nr = algo((string)llDeleteSubList(out, -1, -1), 0, varObj); 
                        split = llListReplaceList(split, [nr], i, x);
                        x = llGetListLength(split);
                    }
                }
            }
        }
        

        return algo((string)split, 1, varObj);
    }

    string action = "+";
    for(i=0; i<llGetListLength(split); i++){
        string str = llStringTrim(llList2String(split, i), STRING_TRIM);
        
        if(~llListFindList(exp, [str])){
            action = str;
        }
        
        else{
            float v;
            
            if(llJsonValueType(varObj, [str]) != JSON_INVALID)v = (float)llJsonGetValue(varObj, [str]);
            else if(part < llGetListLength(parts)-1)v = algo(str, part+1, varObj);
            else v = (float)str;

            if(action == "+")val+=v;
            else if(action == "-")val-=v;
            else if(action == "*")val*=v;
            else if(action == "/")val/=v;
            else if(action == "^")val = llPow(val, v);
            else if(action == "RAND")val+=llFrand(v);
        }
    }
    return val;
}
integer alphaNumeric(string str){
    if(~llSubStringIndex(llEscapeURL(str), "%"))return FALSE;
    return TRUE;
}
rotation baserot(){
    return llList2Rot(llGetObjectDetails(llList2Key(llGetObjectDetails(llGetOwner(), [OBJECT_ROOT]),0), [OBJECT_ROT]),0);   
}
string dateformat(integer utime){
    string output;
    float temp = (float)utime/(60*60*24);
    if(llFloor(temp) > 0){
        output+=(string)llFloor(temp)+" day";
        if(temp>=2)output+="s";
        output += " ";
    }
    temp -= llFloor(temp);
    temp*=24;
    if(llFloor(temp) > 0){
        output+=(string)llFloor(temp)+" hour";
        if(temp>=2)output+="s";
        output += " ";
    }
    temp -= llFloor(temp);
    temp*=60;
    if(llFloor(temp) > 0){
        output+=(string)llFloor(temp)+" minute";
        if(temp>=2)output+="s";
        output += " ";
    }
    temp -= llFloor(temp);
    temp*=60;
    if(llFloor(temp) > 0){
        output+=(string)llFloor(temp)+" second";
        if(temp>=2)output+="s";
        output += " ";
    }
    return output;
}

integer descmatch(key id)
{
    if(llList2String(llGetObjectDetails(id,[OBJECT_DESC]),0) == llGetObjectDesc())return TRUE;
    return FALSE;
}
integer gameInRange(key id, float range){
    if(llVecDist(llList2Vector(llGetObjectDetails(id,[OBJECT_POS]),0),llGetPos())<range)return TRUE;
    else{
        string name = llGetObjectName();
        llSetObjectName("You");
        llRegionSayTo(id, 0, "/me are out of range.");
        llSetObjectName(name);
        return FALSE;
    }
}
//Searches for HEADER in INPUT and returns the value
//If header isnt found, returns an empty string

string getHeaderVar(string input, string header){
    integer hlength = llStringLength(header);
    integer startscan = llSubStringIndex(input, header+"=");
    if(startscan != -1){
        string output = llGetSubString(input, startscan+hlength+1, -1);
        integer andpos;
        if(~(andpos = llSubStringIndex(output, "&"))){
            output = llGetSubString(output,0, andpos-1);
        }
        return output;
    }else{
        return "";
    }
}
integer inFront(vector axis, key object, key infrontof){
    list odata = llGetObjectDetails(object, [OBJECT_POS, OBJECT_ROT]);
    list ifdata = llGetObjectDetails(infrontof, [OBJECT_POS, OBJECT_ROT]);
    rotation bet = llRotBetween(llVecNorm(axis * llList2Rot(ifdata, 1)), llVecNorm(llList2Vector(odata, 0)-llList2Vector(ifdata, 0))); 
    return ((llRot2Angle(bet)*RAD_TO_DEG)<45);
}
integer inRange(key id, float range){
    if(llVecDist(llList2Vector(llGetObjectDetails(id,[OBJECT_POS]),0),llGetPos())<range)return TRUE;
    return FALSE;
}
integer integerLizeKey(string id, integer salt)
{
    return (integer)("0x1"+llGetSubString(id, 0, 6))+salt;
}
integer isDay()
{
    vector sun = llGetSunDirection();
    if(sun.z < 0)return FALSE;
    return TRUE;
}
string jsonTypeName(string value){
    string t = llJsonValueType(value,[]);
    if(t == JSON_INVALID)return "Invalid";
    if(t == JSON_OBJECT)return "Object";
    if(t == JSON_NULL)return "Null";
    if(t == JSON_ARRAY)return "Array";
    if(t == JSON_NUMBER)return "Number";
    if(t == JSON_STRING)return "String";
    if(t == JSON_TRUE)return "TRUE";
    return "FALSE";
}
// Removes a value from a json string
string jsonUnset(string json, list ident){
    if(llJsonValueType(json, ident)!=JSON_INVALID)
        json = llJsonSetValue(json,ident,JSON_DELETE);
    return json;
}
//Attempts to sort a strided list, you can chose any start-entry to sort by
list listSort(list input, integer stride, integer ascending, integer startEntry){
if(llGetListLength(input)%stride == 0){
	list stridedfirst = input;
        if(startEntry)stridedfirst = llDeleteSubList(stridedfirst, 0, startEntry-1);
        stridedfirst = llList2ListStrided(stridedfirst, 0, -1, stride);
        list sortlist;
        integer i;
        for(i=0; i<llGetListLength(stridedfirst); i++)sortlist += llList2List(stridedfirst, i, i)+[i];
        sortlist = llListSort(sortlist, 2, ascending);
        stridedfirst = [];
        for(i=0; i<llGetListLength(sortlist); i+=2)stridedfirst += llList2List(input, llList2Integer(sortlist, i+1)*stride, llList2Integer(sortlist, i+1)*stride+(stride-1));
        return stridedfirst;
    }else{
        return input;
    }
}
string mergeJson(string input, string MERGE){
	integer i; list js = llJson2List(MERGE);
	for(i=0; i<llGetListLength(js); i+=2)input = llJsonSetValue(input, llList2List(js,i,i), llList2String(js,i+1));
	return input;
}
/*
SETUP INSTRUCTIONS
1. Do not use functions that reset script time or rely on script time in sync with these functions.
2. Set your timer event like this:
timer(){timersRefresh();}
3. The function that allows you to trigger things on events is defined like this:
multiTimerEvent(string identifier){}
Identifier is the identifier of your timer.
4. This function relies on the global list "timers", so don't define a variable with that name.
5. This timer is not 100% accurate, and might go out of sync if the sim lags or if use is very heavy

Examples:
Set a timer: setMultiTimer(string identifier, float timeout, integer loop);
Identifier should be a unique ID for your timer, if you call 2 timers with the same name, the old will be overwritten.
Timeout is how long before the timer triggers.
Loop is if it should loop or not

Remove a timer:
removeMultiTimer(string identifier);

Checking a timer's existence:
multiTimerExists(string identifier);

Getting info about a timer
multiTimerInfo(string identifier);
Returns the following list: [(float)triggertime, (string)identifier, (int)looping, (float)duration]
triggertime is when it will next trigger in script time, if you want the exact time remaining, do triggertime-llGetScriptTime()
identifier is the ID of the timer
looping is 1 or 0 if it loops or not
duration is how long the timer was initially set for
*/

/* REQUIRED FUNCTIONS */
// This is where the timer executes
multiTimerEvent(string identifier){}

list timers; 
setMultiTimer(string identifier, float timeout, integer loop){
    if(!llGetListLength(timers)){llResetTime();}
    if(~llListFindList(realStride(timers, 4, 1),[identifier]))removeMultiTimer(identifier);
    timers+=[llGetTime()+timeout, identifier, loop, timeout];
    timers = llListSort(timers, 4, TRUE);
    timersRefresh();
}
 
removeMultiTimer(string identifier){
    integer pos;
    if(~(pos = llListFindList(realStride(timers, 4, 1), [identifier]))){
	integer start = pos*4; integer end = pos*4+3;
	timers = llDeleteSubList(timers, start, end);
    }
}



timersRefresh(){
	float gtime = llGetTime();
    if(timers == [])llSetTimerEvent(0);
    else if(llList2Float(timers, 0)<=gtime){
        string id = llList2String(timers, 1);
        integer loop = llList2Integer(timers, 2);
        if(!loop){timers = llDeleteSubList(timers, 0, 3); }
        else{
            float time = gtime+llList2Float(timers, 3);
            timers = llListReplaceList(timers, [time], 0, 0);
            if(llList2Float(timers, 4)<time){
                timers = llListSort(timers, 4, TRUE);
            }
        }
	
        multiTimerEvent(id);
        timersRefresh();
    }else{
		llSetTimerEvent(llList2Float(timers, 0)-gtime);
	}
}


/* OPTIONAL FUNCTIONS */
integer multiTimerExists(string id){
    if(~llListFindList(realStride(timers, 4, 1), [id]))return TRUE;
    else return FALSE;
}

list multiTimerInfo(string id){
    integer pos;
    if(~(pos = llListFindList(realStride(timers, 4, 1), [id]))){
        return llList2List(timers, pos*4, pos*4+3);
    }else return [];
}


// USAGE
// multiTimer([id]) deletes timer with id
// multiTimer([id, data, timeout, repeating]) to set a timer
// id is always an integer
// data can be anything but a list, type is preserved
// if repeating is TRUE, the timer will keep triggering until it's manually removed
// You'll also need timer(){multiTimer([]);}
// Timeouts are raised in timerEvent(integer id, list data)

list _TIMERS;// timeout, id, data, looptime, repeating
multiTimer(list data){
    integer i;
    if(data != []){
        integer pos = llListFindList(llList2ListStrided(llDeleteSubList(_TIMERS,0,0), 0, -1, 5), llList2List(data,0,0));
        if(~pos)_TIMERS = llDeleteSubList(_TIMERS, pos*5, pos*5+4);
        if(llGetListLength(data)==4){
            if(_TIMERS==[])llResetTime();
            _TIMERS+=[llGetTime()+llList2Float(data,2)]+data;
        }
    }
    for(i=0; i<llGetListLength(_TIMERS); i+=5){
        if(llList2Float(_TIMERS,i)<=llGetTime()){
            string t = llList2String(_TIMERS, i+1);
            string d = llList2String(_TIMERS,i+2);
            if(!llList2Integer(_TIMERS,i+4))_TIMERS= llDeleteSubList(_TIMERS, i, i+4);
            else _TIMERS= llListReplaceList(_TIMERS, [llGetTime()+llList2Float(_TIMERS,i+3)], i, i);
            timerEvent(t, d);
            i-=5;
        }
    }
    if(_TIMERS== []){llSetTimerEvent(0); return;}
    _TIMERS= llListSort(_TIMERS, 5, TRUE);
    float t = llList2Float(_TIMERS,0)-llGetTime();
    if(t<.01)t=.01;
    llSetTimerEvent(t);
}

timerEvent(string id, string data){
    
}
// Credits to Adeon Writer
// Updated 2012-05-12
// Normal = normal passed from raycast
// Axis = axis that should be pointing outwards I think
// Example:
/*
list ray1 = llCastRay(llGetPos(), llGetPos()+llRot2Fwd(llGetRot())*15, [RC_REJECT_TYPES, RC_REJECT_AGENTS|RC_REJECT_PHYSICAL, RC_DATA_FLAGS, RC_GET_NORMAL]);
llRezObject(objname, llList2Vector(ray1, 1), ZERO_VECTOR, norm2rot(llList2Vector(ray1, 2), <0,0,1>), 1);
*/
rotation norm2rot(vector normal, vector axis){
    vector left = llVecNorm(normal % axis);
    return llAxes2Rot(left % normal, left, normal);
}
//Sets objects name to NAME, then says MESSAGE and sets name to its previous name.
outputAs(string name, string message){
string o = llGetObjectName();
llSetObjectName(name);
llSay(0, message);
llSetObjectName(o);
}
//Example: You want to rez an object at an agent's location. If that agent is too far away >10m, rez it as close to him as you can.
//Put the rezzer's position at A, Agents position at B, and distance to 9.99
//Which would look something like pointBetween(llGetPos(), agentPos, 9.99);
vector pointBetween(vector a, vector b, float distance){
        vector offset = a-b;
        return a-(llVecNorm(offset)*distance);
}
list realStride(list input, integer stride, integer start){
    if(start>0)input = llDeleteSubList(input, 0,start-1);
    return llList2ListStrided(input,0,-1,stride);
}
//replaceStringEntry(string source, string remove, string replacement);
//Replaces all "remove" with "replacement" in "source"
string replaceStringEntry(string input, string remove, string replace){
    integer strlen = llStringLength(remove);
    integer pos;
    while(~(pos=llSubStringIndex(input, remove))){
        input = llDeleteSubString(input, pos, pos+strlen-1);
        input = llInsertString(input, pos, replace);
    }
    return input;
}
// Set stride to 0 or 1 to not use stride
list reverseList(list input, integer stride){
    if(stride == 0)stride = 1;
    integer i;
    list output;
    for(i=llGetListLength(input)/stride-1; i>=0; i--){
        output+= llList2List(input, i*stride, i*stride+stride-1);
    }
    return output;
}
rotation rootRot(key id){
    return llList2Rot(llGetObjectDetails(llList2Key(llGetObjectDetails(id, [OBJECT_ROOT]),0), [OBJECT_ROT]),0);   
}
// Speed/steps must be >.1 or you'll get an error
rotDoor(float angle, float speed, integer steps){
    speed /=steps;
    list output;
    vector prepos; integer i; vector scale = llGetScale();
    for(i=1; i<=steps; i++){
        float strot = angle*DEG_TO_RAD/steps;
        vector vpos = (<scale.x/2*llCos(strot*i)-scale.x/2, scale.x/2*llSin(strot*i), 0>)*llGetRot();
        vector v = vpos-prepos;
        prepos = vpos;
        output+=[v, llEuler2Rot(<0,0,angle/steps>*DEG_TO_RAD), speed];
    }
    llSetKeyframedMotion(output, [KFM_MODE,KFM_FORWARD, KFM_DATA, KFM_TRANSLATION|KFM_ROTATION]);
}
// Rounds off value to precision decimals
string round(float value, integer precision){
    if(!precision)return (string)llRound(value);
    integer int = llFloor(value);
    integer dec = llRound((1+value-int)*llPow(10, precision));
    integer ex = (integer)llGetSubString((string)dec, 0, 0);
    if(ex>1){int+=ex-1;}
    return (string)int+"."+(string)llGetSubString((string)dec, 1,-1);
}
// total is how many x/y frames you have, like if you have 4x2 frames on an animation you put <4, 2,0>
// frame is the frame of the animation you want
// texture is either UUID or name of a texture in inventory
// side is the side of the prim, you can use ALL_SIDES
// rot is rotation of the texture in radians
setFrame(vector total, integer frame, key texture, integer side, float rot){
    float width = 1/total.x; float height = 1/total.y;
    integer row = llFloor((float)frame/total.x);
    llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEXTURE, side, texture, <width, height, 0>, <-llFloor(total.x/2)*width+width/2+width*(frame-row*total.x), llFloor(total.y/2)*height-height/2-height*row, 0>, rot]);
}
// total is how many x/y frames you have, like if you have 4x2 frames on an animation you put <4, 2,0>
// frame is the frame of the animation you want
// texture is either UUID or name of a texture in inventory
// side is the side of the prim, you can use ALL_SIDES
// rot is rotation of the texture in radians
setLinkedFrame(integer link, vector total, integer frame, key texture, integer side, float rot){
    float width = 1/total.x; float height = 1/total.y;
    integer row = llFloor((float)frame/total.x);
    llSetLinkPrimitiveParamsFast(link, [PRIM_TEXTURE, side, texture, <width, height, 0>, <-llFloor(total.x/2)*width+width/2+width*(frame-row*total.x), llFloor(total.y/2)*height-height/2-height*row, 0>, rot]);
}
string str_replace(string replace, string with, string source){
    list l = llParseStringKeepNulls(source, [replace], []);
    return llDumpList2String(l,with);
}
integer superScanx(vector pos, vector mypos, rotation mrot, integer limit){
    if(pos != ZERO_VECTOR){
        vector mpos = mypos;
        list rotations;
        if(limit & 1){
            rotations += [llVecDist(pos, mpos+llRot2Fwd(mrot)*.001), 0];
            rotations += [llVecDist(pos, mpos-llRot2Fwd(mrot)*.001), 1];
        }
        if(limit & 2){
            rotations += [llVecDist(pos, mpos+llRot2Left(mrot)*.001), 2];
            rotations += [llVecDist(pos, mpos-llRot2Left(mrot)*.001), 3];
        }
        if(limit & 4){
            rotations += [llVecDist(pos, mpos+llRot2Up(mrot)*.001), 4];
            rotations += [llVecDist(pos, mpos-llRot2Up(mrot)*.001), 5];
        }
        rotations = llListSort(rotations,2,TRUE);
        if(llGetListLength(rotations))return llList2Integer(rotations, 1);
        else return -1;
    }else return -1;
}
integer triggerAnim(string anim, integer start){
    if(llGetInventoryType(anim) == INVENTORY_ANIMATION && llGetPermissions() & PERMISSION_TRIGGER_ANIMATION){
        if(start)llStartAnimation(anim);
        else llStopAnimation(anim);
        return TRUE;
    }
    return FALSE;
}
string trimZeros(float input){
    string inp = (string)input;
    while(llStringLength(inp) && llGetSubString(inp, -1, -1) == "0")inp = llDeleteSubString(inp,-1,-1);
    if(llGetSubString(inp, -1, -1) == ".")inp = llDeleteSubString(inp,-1,-1);
    return inp;
}
string vecComp(vector input, integer accuracy){
    list mpo=llParseString2List(llGetSubString((string)input,1,-2), [", "], []); integer x;
    for(x=0; x<llGetListLength(mpo); x++){
        string n = (string)llRound(llList2Float(mpo,x)*llPow(10,accuracy));
        if(accuracy>0)n = llInsertString((string)n, llStringLength((string)n)-2,".");
        mpo = llListReplaceList(mpo, [n], x, x);
    }
    return "<"+llDumpList2String(mpo, ",")+">";
}
// Vec is the vector of the target to look at
float Vector2Avatar(vector vec)
{
    vec = vec-llGetPos();
    vector fwd = vec * <0.0, 0.0, -llSin(PI_BY_TWO * 0.5), llCos(PI_BY_TWO * 0.5)>;
    fwd.z = 0.0;
    fwd = llVecNorm(fwd);
    vector left = fwd * <0.0, 0.0, llSin(PI_BY_TWO * 0.5), llCos(PI_BY_TWO * 0.5)>;
    rotation rot = llAxes2Rot(fwd, left, fwd % left);
    vector euler = -llRot2Euler(rot);
    return euler.z;
}
//Adds word wrap to INPUT, specified by ROWLENGTH and returns a string separated by SEPARATOR (recommended 
string wordWrap(string input, integer rowlength, string separator){
    list words = llParseString2List(input,[" "],[]);
    integer i; list rows; string thisrow;
    while(i<llGetListLength(words)){
        string this = llList2String(words,i)+" ";
        if((llStringLength(this)+llStringLength(thisrow)) <= rowlength && i+1 != llGetListLength(words)){
            thisrow+=this;
        }else{
            if(i+1 == llGetListLength(words))thisrow+=this;
            rows+=[thisrow];
            thisrow = this;
        }
        i++;
    }
    return llDumpList2String(rows, separator);
}
