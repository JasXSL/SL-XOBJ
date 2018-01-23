/*
	This is a file of macros to interface with the JasX VibHub system. It has no methods or events. You should instead use these macros in your own modules.
	If you want to know more about VibHub, check out the git project: https://github.com/JasXSL/VibHub-Client
	See the package file for a demo!
*/

// SERVER
#ifndef jasVibHub$server
	#define jasVibHub$server "http://api.vibhub.io/"
#endif

// PROGRAM

	// Creates and returns a new Program
	#define jasVibHub$newProgram( repeats, port ) \
		llList2Json(JSON_OBJECT, ["stages","[]", "repeats",repeats, "port",port])
	// Adds a stage to a Program
	#define jasVibHub$program$addStage( program, stage ) \
		program = llJsonSetValue(program, ["stages", -1], stage)
	// Executes the program
	#define jasVibHub$program$execute( id, program ) \
		llHTTPRequest(jasVibHub$server+ \
			"?id="+llEscapeURL(id)+ \
			"&type=vib"+ \
			"&data="+llEscapeURL(program), [], "")
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

	