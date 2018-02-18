
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

// Old
integer integerLizeKey(string id, integer salt)
{
    return (integer)("0x1"+llGetSubString(id, 0, 6))+salt;
}
integer isDay()
{
    vector sun = llGetSunDirection();
    return sun.z > 0;
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
        return llJsonSetValue(json,ident,JSON_DELETE);
    return json;
}

// Very rudimentary and can probably be written better.
// You cant do a number immediately followed by a parentheses, ex: "3(4+6)". Use "3*(4+6)" instead.

// Usage example:
// string variables = llList2Json(JSON_OBJECT, ["x", 4]);
// string algorithm = "10+RAND(x*2)/2";
// llSay(0, algorithm+" (Where: "+variables+")  = "+(string)mathToFloat(algorithm, 0, variables));
// al is the algorithm, part is only used internally so it should be 0, varObj is a JSON object with variables
// If you have libJasPre (see JasX Github) you can also use shorthand algo(mathString, varObj)

float mathToFloat( string al, integer part, string varObj ){

	qd("mathToFloat is deprecated, see ");

    list parts = [
        "(,)",                              // Parentheses work different in that they are calculated separately
        "+,-",                              // AS
        "*,/",                              // MD
		"&,~,|",							// Bitwise
		">,<,=",							// Less than, greater than, equals
        "^",                                // E
        "RAND,CEIL,FLOOR,ROUND,BOOL"             // This is the math order inverse
    ];
	
    list exp = llParseString2List(llList2String(parts,part), [","], []);
    float val; integer i; 
    list split = llParseString2List(al, [], exp);
     
    if(part == 0){
	
        for(i=0; i<llGetListLength(split); i++){
		
            string s = llStringTrim(llList2String(split,i), STRING_TRIM);
            if(s == "("){
			
                integer x; integer ps = 1; list out;
                for(x = i+1; x<llGetListLength(split); x++){
				
                    if(llList2String(split,x) == "(")ps++;
                    else if(llList2String(split,x) == ")") ps--;
                    out+=llList2String(split, x);
                    if(ps == 0 || x>=llGetListLength(split)){
                        float nr = mathToFloat((string)llDeleteSubList(out, -1, -1), 0, varObj); 
                        split = llListReplaceList(split, [nr], i, x);
                        x = llGetListLength(split);
                    }
					
                }
				
            }
			
        }
		
        part = 1;
        exp = llParseString2List(llList2String(parts,part), [","], []);
        split = llParseString2List((string)split, [], exp);
		
    }
    string action = "+";
    
    //llOwnerSay("Step: "+(string)part+" : "+llDumpList2String(split, " ")+" (Split by "+llList2CSV(exp)+")"); 
    for( i=0; i<llGetListLength(split); ++i ){
	
        string s = llStringTrim(llList2String(split, i), STRING_TRIM);
        if(~llListFindList(exp, [s]))
			action = s;
        else{
		
            float v;
            if( llJsonValueType(varObj, [s]) != JSON_INVALID )
				v = (float)llJsonGetValue(varObj, [s]);
			// go up a level
            else if( part <= llGetListLength(parts) )
				v = mathToFloat(s, part+1, varObj);
            else 
				v = (float)s;

            if(action == "+")val+=v;
            else if(action == "-")val-=v;
            else if(action == "*")val*=v;
            else if(action == "/")val/=v;
            else if(action == "^")val = llPow(val, v);
            else if(action == "RAND")val+=llFrand(v);
            else if(action == "CEIL")val+=llCeil(v);
            else if(action == "FLOOR")val+=llFloor(v);
            else if(action == "ROUND")val+=llRound(v);
			else if(action == "BOOL")val = (v!=0);
            else if(action == ">")val = val > v;
			else if(action == "<")val = val < v;
			else if(action == "=")val = val == v;
			else if(action == "&")val = (integer)val&(integer)v;
			else if(action == "~")val = ~(integer)val&(integer)v;
			
			
        }
    }
    return val;
}
string mergeJson(string input, string MERGE){
	integer i; list js = llJson2List(MERGE);
	for(i=0; i<llGetListLength(js); i+=2)input = llJsonSetValue(input, llList2List(js,i,i), llList2String(js,i+1));
	return input;
}



// pandaMath
	
	// Runs a math string
	// If you do not need parentheses you can use #define PMATH_IGNORE_PARENTHESES to save space and time
	// If you want to use a list of constants, use #define PMATH_CONSTS varName
	float pandaMath( string I )
	{
		
		list parse;
		#ifndef PMATH_IGNORE_PARENTHESES
		parse = llParseString2List(I, [], (list)"(" + ")");
		if (1 < (parse != []))
		{
			integer n;
			integer nIn = ((integer)-1);
			integer i;
			for (; i < (parse != []); ++i)
			{
				if (llList2String(parse, i) == "(")
				{
					++n;
					if (!~nIn)
						nIn = i;
				}
				else if (llList2String(parse, i) == ")")
				{
					if (!--n)
					{
						parse = llListReplaceList(parse, (list)pandaMath((string)llList2List(parse, -~nIn, ~-i)), nIn, i);
						i = ~-~-i;
						nIn = ((integer)-1);
					}
				}
			}
			I = (string)parse;
		}
		#endif
		
		// 1+2>3
		// 1, 2, >, 3
		
		list order = (list)"^" + "*,/" + "" + ">,<,==,&";
		parse = llParseString2List(I, (list)"+", (list)"^" + "*" + "/" + "-" + "&" + "<" + ">" + "==");
		I = "";
		
		// Convert to float
		integer i;
		for( ; i < (parse != []); ++i ){

			string s = llList2String(parse, i);
			if (s == "-")
				parse = llListReplaceList(parse, (list)((float)(s + llList2String(parse, -~i))), i, -~i);
			else if ((!(s == "0")) & (float)s == ((float)0))
			{
				// Redeem functions and constants
				list functions = (list)"π" + "~" +"!" + "CEIL" + "RAND" + "FLOOR" + "ROUND" + "COS" + "SIN";
				
				// Check constants
				#ifdef PMATH_CONSTS
				integer p = llListFindList(llList2ListStrided(PMATH_CONSTS, 0, -1, 2), (list)s);
				if( ~p )
					parse = llListReplaceList(parse, (list)llList2Float(PMATH_CONSTS, p*2+1), i, i);
				// Check built in functions
				else{
				#endif				
			
					integer n;
					for (; n < (functions != []); ++n)
					{
						string f = llList2String(functions, n);
						
						if(llGetSubString(s, 0, ~-llStringLength(f)) == f)
						{
							float v = (float)llGetSubString(s, llStringLength(f), ((integer)-1));
							if (f == "CEIL")
								v = llCeil(v);
							else if (f == "RAND")
								v = llFrand(v);
							else if (f == "FLOOR")
								v = (integer)v;
							else if (f == "ROUND")
								v = llRound(v);
							else if (f == "!")
								v = !((integer)v);
							else if (f == "~")
								v = ~(integer)v;
							else if (f == "COS")
								v = llCos(v);
							else if (f == "SIN")
								v = llSin(v);
							else if (f == "π")
								v = PI;
								
							parse = llListReplaceList(parse, (list)v, i, i);
							functions = [];
						}
					}
				
				#ifdef PMATH_CONSTS
				}
				#endif
				
			}
			else
				parse = llListReplaceList(parse, (list)((float)s), i, i);
		}

		for( i = 0; i < (order != []); ++i ){
		
			list o = llParseString2List(llList2String(order, i), (list)",", []);
			integer pointer;
			for (; pointer < (parse != []); ++pointer){
			
				if( llGetListEntryType(parse, pointer) == TYPE_FLOAT && (o != [] || !pointer) )
					jump pandaMath_continue;
				
				float a = llList2Float(parse, ~-pointer);
				
				
				string v = llList2String(parse, pointer);
				
				// Handle addition
				if( o == [] && llGetListEntryType(parse, ~-pointer) + llGetListEntryType(parse, pointer) == 4 ){

					parse = llListReplaceList(parse, (list)(a+llList2Float(parse, pointer)), ~-pointer, pointer);
					pointer = ~-pointer;
					
				}
				else if( ~llListFindList(o, (list)v) ){
				
					
					float b = llList2Float(parse, -~pointer);
					if (v == "*")
						a = a * b;
					else if(v == "/")
						a = a / b;
					else if(v == "^")
						a = llPow(a, b);
					else if(v == "&")
						a = (integer)a & (integer)b;
					else if(v == ">")
						a = a > b;
					else if(v == "<")
						a = a < b;
					else if(v == "==")
						a = a == b;
					
					parse = llListReplaceList(parse, (list)a, ~-pointer, -~pointer);
					pointer = ~-~-pointer;
				}
				@pandaMath_continue;
			}
		}
		
		return llList2Float(parse, 0);
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
        if(llGetListLength(data)==4)_TIMERS+=[llGetTime()+llList2Float(data,2)]+data;
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


//Sets objects name to NAME, then says MESSAGE and sets name to its previous name.
outputAs(string name, string message){
	string o = llGetObjectName();
	llSetObjectName(name);
	llSay(0, message);
	llSetObjectName(o);
}

// Set stride to 0 or 1 to not use stride
list reverseList(list input, integer stride){
    if(stride == 0)stride = 1;
    integer i; list output;
    for(i=llGetListLength(input)/stride-1; i>=0; i--){
        output+= llList2List(input, i*stride, i*stride+stride-1);
    }
    return output;
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

translateTo(vector to, rotation rota, float time, integer mode){
    vector start = llGetPos();
    vector dist = to-start;
    integer totSteps = llFloor(time/0.2);
    if(totSteps<=0)totSteps = 0;
    if(totSteps>50)totSteps = 50;
    
    vector srot = llRot2Euler(llGetRot());
    vector vrot = llRot2Euler(rota);
    vector rdist = vrot-srot;
    
    list frames;
    integer i; vector added; vector roted;
    for(i=1; i<=totSteps; i++){
        float f = llCos(PI+PI*((float)i/totSteps))/2+.5;
        vector rot = rdist*f-roted;
        vector point = dist*f-added;
        roted = rdist*f;
        added = dist*f;
        frames+=[point, llEuler2Rot(rot), 0.2];
    }
    
    float tot;
    for(i=0; i<llGetListLength(frames); i+=2){
        vector v = llList2Vector(frames, i);
        tot+=v.x;
    }
    if(mode == 0)mode = KFM_FORWARD;
    llSetKeyframedMotion(frames, [KFM_MODE,mode]);    
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
float Vector2Avatar(vector vec){
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


// Normalizes a list of floats, where they all add up to norm
list listNormalize(list input, float norm){
    integer i; float s = norm/llListStatistics(LIST_STAT_SUM, input);
    for(i=0; i<llGetListLength(input); ++i)
        input = llListReplaceList(input, [llList2Float(input, i)*s], i, i);
    return input;
}

// Originally by Nexii Malthus - http://wiki.secondlife.com/wiki/Geometric
float distFromLine(vector origin,vector dir,vector point){
    vector k = ( point - origin ) % llVecNorm(origin-dir);
    return llSqrt( k * k );
}

// Original math by Nexii Malthus - http://wiki.secondlife.com/wiki/Geometric
// O is origin
// D is end pont
// A is avatar position
integer standingInBeam(vector O, vector D, vector A, integer ignoreZ, float width){
    if(ignoreZ){O.z = 0;D.z = 0;A.z = 0;}
    vector d = llVecNorm(O-D);
    vector k = ( A - O ) % d;
    float xy = llSqrt( k * k );
    if(xy > width)
        return FALSE;
    vector pointOnLine = ((O-A)-((O-A)*d)*d)+A;
    float dist = llVecDist(O, D);
    float pointToA = llVecDist(pointOnLine, O);
    float pointToB = llVecDist(pointOnLine, D);
    if(pointToA > dist || pointToB > dist)
        return FALSE;    
    return TRUE;
}
// Line and line intersection point
vector gLLxX( vector A, vector B, vector C, vector D ){
    vector b = B-A; vector d = D-C;
    float dotperp = b.x*d.y - b.y*d.x;
    if (dotperp == 0) return <-1,-1,-1>;
    vector c = C-A;
    float t = (c.x*d.y - c.y*d.x) / dotperp;
    return <A.x + t*b.x, A.y + t*b.y, 0>;}

// Bits to hex from http://wiki.secondlife.com/wiki/Efficient_Hex
string bits2nybbles(integer bits){
    integer lsn; // least significant nybble
    string nybbles = "";
    do
        nybbles = llGetSubString("0123456789ABCDEF", lsn = (bits & 0xF), lsn) + nybbles;
    while (bits = (0xfffFFFF & (bits >> 4)));
    return nybbles;
}
