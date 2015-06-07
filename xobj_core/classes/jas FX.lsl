#define FXMethod$run 1					// (key)sender, (obj)wrapper - Runs a package on a player
#define FXMethod$refresh 2				// Runs a user defined refresh() function to check status updates etc
#define FXMethod$rem 3					// raiseEvt, name, tag, sender, pid - Use "" to disregard a value
										// if sender is prefixed with ! it will remove everyone BUT that attacker
#define FXMethod$setPCs 4				// (arr)pc_keys - Set PC keys on send to PC events
#define FXMethod$setNPCs 5				// (arr)pc_keys - Set NPC keys to send to on NPC events

#define FXEvt$runEffect 1				// [(key)caster, (int)stacks, (arr)package]
#define FXEvt$effectAdded 2				// [(key)caster, (int)stacks, (arr)package]
#define FXEvt$effectRemoved 3			// [(key)caster, (int)stacks, (arr)package]
#define FXEvt$effectStacksChanged 4		// [(key)caster, (int)stacks, (arr)package]


#define FX$send(target, sender, wrapper) runMethod(target, "jas FX", FXMethod$run, ([sender, wrapper]), TNN)
#define FX$run(sender, wrapper) runMethod((string)LINK_SET, "jas FX", FXMethod$run, ([sender, wrapper]), TNN)
#define FX$refresh() runMethod((string)LINK_SET, "jas FX", FXMethod$refresh, [], TNN)
#define FX$rem(raiseEvt, name, tag, sender, pid) runMethod((string)LINK_SET, "jas FX", FXMethod$rem, ([raiseEvt, name, tag, sender, pid]), TNN)


#ifndef fx$COND_HAS_PACKAGE_NAME
	#define fx$COND_HAS_PACKAGE_NAME 1			// [(str)name1, (str)name2...] - Recipient has a package with at least one of these names
#endif
#ifndef fx$COND_HAS_PACKAGE_TAG
	#define fx$COND_HAS_PACKAGE_TAG 2			// [(int)tag1, (int)tag2...] - Recipient has a tackage with a tag with at least one of these
#endif

//#define FXConf$useEvtListener
// Lets you use the evtListener(string script, integer evt, string data) to perform actions when an event is received
//#define FXConf$useShared "a"
// Lets you save the spell packages as a shared array. It will likely risk overflowing if you add more than a handful of spells.
// If saved, shared will be the strided array [(int)pid, (key)caster, (arr)package, (int)stacks]

// User defined functions (overwrite these in your implementation)
	// Run whenever a spell needs to check condition
	integer checkCondition(key caster, integer inverse, integer cond, list data){return TRUE;}
	// Targ can also be "PC" and "NPC" in which case it's up to the developer to scan for those
	// Events are run automatically on packages. They are then sent to evtListener where you can write your own onEvt actions if you want
	evtListener(string script, integer evt, string data){}
	
	
// Note, you'll probably want a sheet to keep track of FX types

// Wrapper is an array that contains the entire fx object
// Once the script receives a wrapper it's opened and the packages are cached if valid
// Note: if you add your own targ flags, use 65536 and greater values as this list might be extended
#define TARG_CASTER 1
#define TARG_VICTIM 2
#define TARG_PCS 4
#define TARG_NPCS 8
// packages is strided [(int)stacks, (arr)package...]
string FX_buildWrapper(integer min_objs, integer max_objs, list packages){
    return llList2Json(JSON_ARRAY, [min_objs, max_objs]+packages);
}


// Events are used to run additional wrappers on a target based on script events
// For internal events use "" as evscript
// Internal events are quick events restrained to this script
#define INTEVENT_ONREMOVE 1			// Data is a package
#define INTEVENT_ONADD 2			// Data is a package
string FX_buildEvent(integer evtype, string evscript, integer targ, integer maxtargets, string wrapper){
    return llList2Json(JSON_ARRAY, [evtype, evscript, targ, maxtargets, wrapper]);
}

// FX are packages containing info about a specific effect. You'll likely want to write your own sheet of various effects
string FX_buildFX(integer id, list params){
    return llList2Json(JSON_ARRAY, [id]+params);
}


// Conditions should also be added to your FX sheet. Conditions will be checked in the checkCondition(key caster, key targ, integer cond, list cond_data) function
string FX_buildCondition(integer cond, list vars){
    return llList2Json(JSON_ARRAY, [cond]+vars);
}


// Packages are the effect objects bound to an FX wrapper. A wrapper can contain multiple packages, and a package can contain multiple fx objects
// These are general package flags
#define PF_ALLOW_WHEN_DEAD 1        // Package is not removed and can be added when player is dead
#define PF_DETRIMENTAL 2            // Package is detrimental.
#define PF_UNDISPELLABLE 4			// 
#define PF_UNIQUE 8					// Only one player can have this
// an integer PID gets added on the end when added to FX

#define FX_DUR 0
#define FX_TICK 1
#define FX_FLAGS 2
#define FX_MAXSTACKS 3
#define FX_NAME 4
#define FX_DESC 5
#define FX_TEXTURE 6
#define FX_FXOBJS 7
#define FX_CONDS 8
#define FX_EVTS 9
#define FX_TAGS 10
#define FX_MIN_CONDITIONS 11	// 0 = ALL


string FX_buildPackage(float dur, float tick, integer flags, integer maxstacks, string name, string desc, key texture, list fxobjs, list conditions, list evts, list tags, integer fxMinConditions){
    return llList2Json(JSON_ARRAY, FX_fround(dur)+FX_fround(tick)+[flags, maxstacks, name, desc, texture, llList2Json(JSON_ARRAY, fxobjs),llList2Json(JSON_ARRAY, conditions),llList2Json(JSON_ARRAY, evts), llList2Json(JSON_ARRAY, tags), fxMinConditions]);
}

// Helper function for shortening package strings
list FX_fround(float input){
    if((float)llRound(input) != input)return [input];
    return [llRound(input)];
}



