/*
	This script will dispense scripts or objects, can be accessed externally but only by the owner.
	
	Install instructions:
	1. Create a new prim on your HUD
	2. Create a new script, on the first line you include your project "_core.lsl" file
	3. On the second line #include "xobj_core/classes/packages/st Remoteloader.lsl"
	4. Create a new script in your inventory, name it _slave1
	5. Paste the following code into it and compile:
	
	
default
{
    state_entry(){llSetMemoryLimit(llGetUsedMemory()*2);}
    link_message(integer link, integer nr, string str, key id){
        if(id == "rm_slave"){
            if(nr == (integer)llGetSubString(llGetScriptName(), -1, -1)){
                llRemoteLoadScriptPin(llJsonGetValue(str, [0]), 
                    llJsonGetValue(str,[1]),
                    (integer)llJsonGetValue(str,[2]),
                    TRUE,
                    (integer)llJsonGetValue(str, [3])
                );
            }
        }
    }
}
	
	6. Drag the script into the same prim as you put st Remoteloader. Drag it in 5 times to create 5 copies of it.
	7. Rename the _slave scripts into _slave1, _slave2, _slave3, _slave4, _slave5
	8. These scripts will be used to speed up remoteloading, to circumvent the long delay caused by it.
	9. Make sure jas Remoteloader is on drive
	
	
*/

// Methods //
// These are identifier ints used to call methods on this class from other scripts
// Each function you make in public methods should be listed here with it's own integer ID
// Methods should not be negative
#define RemoteloaderMethod$load 0		// (str)script, (int)pin, (int)startparam - Remoteloads a script onto sender
#define RemoteloaderMethod$asset 1		// (str)asset - Gives an inventory item to sender
#define RemoteloaderMethod$attach 2		// (str)asset
#define RemoteloaderMethod$rez 3		// (str)obj, (vec)pos, (vec)vel, (rot)rotation, (int)startparam
#define RemoteloaderMethod$detach 4		// (str)asset

#ifndef RemoteloaderConf$slaves
#define RemoteloaderConf$slaves 5
#endif

// Preprocessor shortcuts
#define Remoteloader$attach(asset) runMethod((string)LINK_SET, "jas Remoteloader", RemoteloaderMethod$attach, [asset], TNN)
#define Remoteloader$detach(asset) runMethod((string)LINK_SET, "jas Remoteloader", RemoteloaderMethod$detach, [asset], TNN)
#define Remoteloader$attachTo(target, asset) runMethod((string)target, "jas Remoteloader", RemoteloaderMethod$attach, [asset], TNN)
#define Remoteloader$detachFrom(target, asset) runMethod((string)target, "jas Remoteloader", RemoteloaderMethod$detach, [asset], TNN)


#define Remoteloader$rez(obj,pos,vel,rot,sp) runMethod((string)LINK_SET, "jas Remoteloader", RemoteloaderMethod$rez, [obj,pos,vel,rot,sp], TNN)
#define Remoteloader$load(script, pin, startparam) runMethod((string)llGetOwner(), "jas Remoteloader", RemoteloaderMethod$load, [script, pin, startparam], TNN)
#define Remoteloader$loadInt(script, pin, startparam, sender) runMethod((string)LINK_ALL_OTHERS, "jas Remoteloader", RemoteloaderMethod$load, [script, pin, startparam, sender], TNN)








