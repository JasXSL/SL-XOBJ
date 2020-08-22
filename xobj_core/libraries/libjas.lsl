#ifndef _libjas
#define _libjas

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

// Lets you round floats, vectors, and rotations
#define allRound(input, places) _allRound((list)(input), places)
string _allRound( list input, integer places ){
    
    list vals = (list)llList2Float(input, 0); 
    integer type = llGetListEntryType(input, 0);
    if( type == TYPE_VECTOR ){
        vector v = llList2Vector(input, 0);
        vals = (list)v.x + v.y + v.z;
    }
    else if( type == TYPE_ROTATION  ){
        rotation v = llList2Rot(input, 0);
        vals = (list)v.x + v.y + v.z + v.s;
    }
    
    float exponent = llPow(10,places);
    integer i;
    for( ; i<llGetListLength(vals); ++i ){
        
        
        string v = (string)(
            (float)llRound(llList2Float(vals, i)*exponent)
            /exponent
        );
        while( llGetSubString(v, -1, -1) == "0" )
            v = llDeleteSubString(v, -1, -1);
        
        while( llGetSubString(v, 0, 0) == "0" )
            v = llDeleteSubString(v, 0, 0);
            
        if( llGetSubString(v, -1, -1) == "." )
            v = llDeleteSubString(v, -1, -1);
        
        if( v == "" )
            v = "0";
        
        vals = llListReplaceList(vals, (list)v, i, i);
        
    }
    
    if( llGetListLength(vals) > 1 )
        return "<"+llDumpList2String(vals, ",")+">";
    return llList2String(vals, 0);
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

// pandaMath
	
	// Runs a math string
	// If you do not need parentheses you can use #define PMATH_IGNORE_PARENTHESES to save space and time
	// If you want to use a list of constants, use #define PMATH_CONSTS varName
	// If you don't need multi argument functions, you can use #define PMATH_IGNORE_MULTI_ARG or PMATH_IGNORE_PARENTHESES as both will disable the feature
	list pandaMath( string I ){
		
		list parse;
		#ifndef PMATH_IGNORE_MULTI_ARG
			list funcs = (list)"MIN"+"MAX";	// if any functions share ending, the longer ones need to go first
		#endif
		
		integer i;
		parse = llParseString2List(I, [], (list)"(" + ")");
		if( 1 < (parse != []) ){
		
			integer n;
			integer nIn = ((integer)-1);
			for( i=0; i < (parse != []); ++i ){
			
				if( llList2String(parse, i) == "(" ){
				
					++n;
					if( !~nIn )
						nIn = i;
						
				}
				else if( llList2String(parse, i) == ")" ){
				
					if( !--n ){
					
						
						list bl = pandaMath((string)llList2List(parse, -~nIn, ~-i));
						
						#ifndef PMATH_IGNORE_MULTI_ARG
						string e = l2s(parse, nIn-1);
						// Look behind for a function, otherwise flatten
						integer fn;
						for( ; fn<count(funcs); ++fn ){
							string func = l2s(funcs, fn);
							if( llGetSubString(e, -llStringLength(func), -1) == func ){
								if( func == "MAX" )
									bl = (list)llListStatistics(LIST_STAT_MAX, bl);
								else if( func == "MIN" )
									bl = (list)llListStatistics(LIST_STAT_MIN, bl);
								else if( func == "MIN" )
									bl = (list)llListStatistics(LIST_STAT_MIN, bl);
								// Delete the function name
								parse = llListReplaceList(parse, (list)llDeleteSubString(e, -llStringLength(func), -1), nIn-1, nIn-1);
								fn = 9001; // break
							}
						}
						#endif
						
						parse = llListReplaceList(
							parse, 
							llList2List(bl, 0, 0),
							nIn, i
						);
						i = ~-~-i;
						nIn = ((integer)-1);
						
					}
					
				}
				
			}
			
			I = (string)parse;
			
		}

		//list blocks = llJson2List(I);
		
		// Parentheses done, deal with functions
		// Deal with commas next
		list blocks = llCSV2List(I);
		
		//list blocks = llParseString2List(I, [], funcs);
		#ifndef PMATH_CAPTURE_MATH_ERRORS
			I = "";
		#endif
		
		integer block;
		// Turn blocks into calculations
		for( block = 0; block<count(blocks); ++block ){
		
			// "" is needed for addition
			list order = (list)"^" + "*,/" + "" + ">,<,==,&,|,<<,>>";
			parse = llParseString2List(l2s(blocks, block), (list)"+", (list)"^" + "*" + "/" + "-" + "&" + "<<" + ">>" + "==");

			// Convert constants and functions
			for( i=0; i < count(parse); ++i ){

				// Split by additional separators
				string p = l2s(parse, i);
				if( p != ">>" && p != "<<" ){
					list l = llParseString2List(p, [], (list)"|"+">"+"<");
					if( (l != []) > 1 )
						parse = llListReplaceList(parse, l, i, i);
				}
				
				// Check if this is a function
				string s = llList2String(parse, i);
				
				// Check if s is numeric
				if( llGetSubString(s,0,0) != "0" && (float)s == 0 ){
					// Redeem functions and constants
					list functions = (list)"~" + "!" + "CEIL" + "RAND" + "FLOOR" + "ROUND" + "COS" + "SIN" + "SQRT" + "ABS";
									
					// Check constants
					#ifdef PMATH_CONSTS
					integer p = llListFindList(llList2ListStrided(PMATH_CONSTS, 0, -1, 2), (list)s);
					if( ~p )
						parse = llListReplaceList(parse, (list)llList2Float(PMATH_CONSTS, p*2+1), i, i);
					// Check built in functions
					else{
					#endif				
				
						integer n;
						for (; n < (functions != []); ++n){
						
							string f = llList2String(functions, n);
							if( llGetSubString(s, 0, ~-llStringLength(f)) == f ){

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
								else if( f == "SQRT" )
									v = llSqrt(v);
								else if( f == "ABS" && l2s(parse, -~i) == "-" ){
									parse = llDeleteSubList(parse, i, -~i);
									jump pmath_functionLoop;
								}

									
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
				
				@pmath_functionLoop;
			}
			
			
			
			// Handle minuses
			for( i = 0; i<count(parse); ++i ){
			
				string s = l2s(parse, i);
				if (s == "-")
					parse = llListReplaceList(parse, (list)((float)(s + llList2String(parse, -~i))), i, -~i);
					
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
						else if(v == "/"){
							#ifdef PMATH_CAPTURE_MATH_ERRORS
							if( b == 0 )
								qd("MATH ERROR Captured: Division by zero in "+I);
							else
							#endif 
							a = a / b;
						}
						else if(v == "^"){
							#ifdef PMATH_CAPTURE_MATH_ERRORS
							if((b != (integer)b) && (a < 0.0))
								qd("MATH ERROR Captured: Invalid base or exponent in pow: "+I);
							else
							#endif
							a = llPow(a, b);
						}
						else if(v == "&")
							a = (integer)a & (integer)b;
						else if(v == ">")
							a = a > b;
						else if(v == "<")
							a = a < b;
						else if(v == "==")
							a = a == b;
						else if( v == "|" )
							a = (integer)a|(integer)b;
						else if( v == ">>" )
							a = (integer)a>>(integer)b;
						else if( v == "<<" )
							a = (integer)a<<(integer)b;
						
							
						parse = llListReplaceList(parse, (list)a, ~-pointer, -~pointer);
						pointer = ~-~-pointer;
					}
					@pandaMath_continue;
				}
			}
		
			blocks = llListReplaceList(blocks, parse, block, block);
		}
	
		return blocks;
	}

// USAGE
// multiTimer([id]) deletes timer with id
// multiTimer([id, data, timeout, repeating]) to set a timer
// id is always an integer
// data can be anything but a list, type is preserved
// if repeating is TRUE, the timer will keep triggering until it's manually removed
// You'll also need timer(){multiTimer([]);}
// Timeouts are raised in timerEvent(integer id, list data)

list _T;	// (float)timeout, id, data, looptime, repeating
/*
	timeout = script time when to trigger event
	id = 
*/
multiTimer( list da ){
    
	integer i;
    if( da ){
	
        integer pos = llListFindList(llList2ListStrided(llDeleteSubList(_T,0,0), 0, -1, 5), llList2List(da,0,0));
        if( ~pos )
			_T = llDeleteSubList(_T, pos*5, pos*5+4);
        if( count(da) == 4 )
			_T = _T + (list)(llGetTime() + llList2Float(da,2)) + da;

    }
	
	for( i=0; i<count(_T); i = i+5 ){
	
        if( !(llGetTime() < llList2Float(_T,i)) ){
            
			string t = llList2String(_T, -~i);
            string d = llList2String(_T,-~-~i);

            if( llList2Integer(_T,i+4) )
				_T = llListReplaceList(_T, (list)(llGetTime()+llList2Float(_T,i+3)), i, i);
            else 
				_T= llDeleteSubList(_T, i, i+4);
				
            timerEvent(t, d);
            i = i+((integer)-5);
			
        }
    }
	
	
    if( _T == [] ){
		llSetTimerEvent(0); 
		return;
	}
    _T= llListSort(_T, 5, TRUE);
    float t = llList2Float(_T,0) + -llGetTime();
    if( t < .01 )
		t=.01;
	
    llSetTimerEvent(t);
	
}


// Panda alternative minified multiTimer
// use ptEvt(id);
#define ptSet(id, timeout, repeating) \
    _MT(id, (integer)((timeout)*100)|(repeating<<31))
#define ptRefresh() \
	_MT("",0)
#define ptUnset(id) \
	_MT(id, 0)
list _mt;	// nextTick, id, timeout
_MT(string id, integer t){
    float g = llGetTime();
    if(!(id == "")){
        integer pos = llListFindList(_mt, (list)id);
        float to = (float)(t & ~0x80000000) / 100;		// Timeout
        float nx = to + g;								// Next
        if ((~t) & ((integer)-0x80000000))
            to = 0;
        if (~pos)
            _mt = llDeleteSubList(_mt, ~-pos, -~pos);
        if (t)
            _mt = _mt + ((list)nx + id + to);
    }
    for (t = 0; t < (_mt != []); t = 3 + t)
    {
        if (!(g < llList2Float(_mt, t)))
        {
            float re = llList2Float(_mt, -~-~t);
            string id = llList2String(_mt, -~t);
            if (re == ((float)0))
            {
                _mt = llDeleteSubList(_mt, t, -~-~t);
                t = ((integer)-3) + t;
            }
            else
                _mt = llListReplaceList(_mt, (list)(g + re), t, t);
			
            ptEvt(id);
        }
    }
    if (_mt == [])
    {
        llSetTimerEvent(0);
        return;
    }
    _mt = llListSort(_mt, 3, 1);
	float n = llList2Float(_mt, 0) + -g;
    if (!(0 < n))
        n = 0.01;
	llSetTimerEvent(n);
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
    vector start = llGetRootPosition();
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
    vec = vec-llGetRootPosition();
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

#endif
