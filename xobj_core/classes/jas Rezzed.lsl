/*
	This script can be put into a rezzed object serving as a #ROOT and letting you remove it.
	
	1. Include your project _core.lsl
	2. Install st Remoteloader
	3. #include "xobj_core/classes/packages/st Rezzed.lsl"
	4. Compile and put it into the same prim you put the remoteloader.
	5. Rez the object with either Remoteloader$rez((string)objName) using start param playerChan(llGetOwner())
	
	To remove attachments, use Rezzed$remove((string)attachmentName);
	To remove ALL rezzed items loaded this way, use Rezzed$remove("*")
*/
#ifndef RezzedConf$removeByName
	#define RezzedConf$removeByName 0		// Set to 1 in your implementation to have all objects rezzed with the same name removed when this object is rezzed
#endif

#define RezzedMethod$remove 0			// NULL
 

#define Rezzed$remove(itemname) runOmniMethod("jas Rezzed", RezzedMethod$remove, [], TARG_NULL, NORET, itemname)



