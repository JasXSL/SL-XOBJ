/*
	This is a file of macros to interface with the JasX VibHub system. It has no methods or events. You should instead use these macros in your own modules.
	If you want to know more about VibHub, check out the git project: https://github.com/JasXSL/VibHub-Client
	The package file can be used to wrap a lot of these calls
*/
#ifndef __jasVibHub
#define __jasVibHub

#define jasVibHubMethod$openDialog 1		// Opens the configurator
#define jasVibHubMethod$initialize 2		// Opens token dialog if non exists, otherwise requests device data 
#define jasVibHubMethod$sendProgram 3		// (obj)program, (float)duration - Sends a program to the server. Note that there's no http request protection. Don't send more than one a second.

#define VibHubEvt$meta 1					// (obj)metadata - See the VibHub main documentation
#define VibHubEvt$ports 2					// (int)ports_butt, (int)ports_groin, (int)ports_breasts - Bitwise combinations




#define jasVibHub$initialize( target ) runMethod( (str)target, "jas VibHub", jasVibHubMethod$initialize, [], TNN)
#define jasVibHub$openDialog( target ) runMethod( (str)target, "jas VibHub", jasVibHubMethod$openDialog, [], TNN)
#define jasVibHub$sendProgram( target, program, duration ) runMethod( (str)target, "jas VibHub", jasVibHubMethod$sendProgram, (list)(program) + (duration), TNN)



// SERVER
#ifndef jasVibHub$server
	#define jasVibHub$server "https://vibhub.io/api"
#endif

// Meta
	#define jasVibHub$meta$get(id) \
		llHTTPRequest(jasVibHub$server+ \
			"?id="+llEscapeURL(id)+ \
			"&type=whois&data=[]", \
			[], \
			"" \
		)

// PROGRAM

	// Creates and returns a new Program
	// Ports is a bitwise combination, or 0 to target all
	#define jasVibHub$newProgram( repeats, port ) \
		llList2Json(JSON_OBJECT, ["stages","[]", "repeats",repeats, "port",port])
	// Adds a stage to a Program
	#define jasVibHub$program$addStage( program, stage ) \
		program = llJsonSetValue(program, ["stages", -1], stage)
	// Sets all stages from a list of stages
	#define jasVibHub$program$setStagesList( program, stages ) \
		program = llJsonSetValue(program, ["stages"], mkarr(stages))
	// Sets all stages from an JSON array of stages
	#define jasVibHub$program$setStagesArray( program, stages ) \
		program = llJsonSetValue(program, ["stages"], stages)
	
	// Executes the program
	#define jasVibHub$program$execute( id, program ) \
		llHTTPRequest(jasVibHub$server+ \
			"?id="+llEscapeURL(id)+ \
			"&type=vib"+ \
			"&data="+llEscapeURL("["+program+"]"), [], "")
	// Executes multiple programs on different ports
	#define jasVibHub$program$executeMany( id, programs ) \
		jasVibHub$program$execute(id, mkarr(programs))
		
	

// STAGE
	// Creates and returns a new Stage
	#define jasVibHub$newStage() \
		"{}"
	// Sets intensity on a stage
	#define jasVibHub$stage$setIntensity( stage, intensity ) \
		stage = llJsonSetValue(stage, ["i"], (str)intensity)
	// Sets duration of the stage
	#define jasVibHub$stage$setDuration( stage, duration ) \
		stage = llJsonSetValue(stage, ["d"], (str)llRound(duration*1000))
	// Sets how many repeats a stage should have
	#define jasVibHub$stage$setRepeats( stage, repeats ) \
		stage = llJsonSetValue(stage, ["r"], (str)llRound(repeats))
	// Makes the stage to back and forth. Requires at least 1 repeat, as each back and each forth consumes 1 repeat. 
	// Therefore unless you want to end at the peak value, you should always use an odd number of repeats when using yoyo
	#define jasVibHub$stage$setYoyo( stage, yoyo ) \
		stage = llJsonSetValue(stage, ["y"], (str)(yoyo == TRUE))
	// Sets easing function, default is "Linear.None". See here for acceptable values: http://sole.github.io/tween.js/examples/03_graphs.html
	#define jasVibHub$stage$setEasing( stage, easing ) \
		stage = llJsonSetValue(stage, ["e"], easing)


#endif
