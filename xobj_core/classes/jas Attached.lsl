/*
	Dependencies
		- st Remoteloader
	
	This is a script that lets an object temp attach to you. It also serves as a #ROOT script.
	Setup:
	1. Create a prim in your target's HUD.
	2. Install the "jas Remoteloader" module into that prim.
	3. Create a new script in the prim, make sure it's transferrable.
	4. Name the new script "jas Attached"
	5. Open the script and uncheck "running".
	6. Copy+paste the contents of this script into the open script and compile.
	7. Drag that script into your inventory.
	8. From your inventory, drag the script into the object you want to temp-attach when rezzed. (Recommended 
	9. Pick up that item to inventory and put it in the same prim as the "jas Remoteloader" script.
	10. Rez the object with either Remoteloader$attach((string)objName) or you can use llRezObject or llRezAtRoot using start parameter 1.
	11. The object should now attach.
	
	
	To remove attachments, use Attached$remove((string)attachmentName);
	To remove ALL temp attachments loaded this way, use Attached$remove("*");
	
*/

// If you want to have a random token that will detach all attachments without needing to verify object owner (on HUD detach for an instance)
// Define LISTEN_OVERRIDE, then LISTERN_OVERRIDE_ALLOW_ALL and define Attached$detachHash to a personal function
// When the message is received on that chan, the object will detach
// Please note that this might be somewhat vulnerable and if someone figures out your hashing algorithm they can remove people's
// Attachments attached through this script
// #define Attached$detachHash llSHA1String((string)llGetOwner()+"detachall")

// #define Attached$automateMeshAnim - 	Parses standard events from ton MeshAnim. 
// #define Attached$useExtUpdate - Use a different script to update. Useful for the portal method of spawned assets
// #define Attached$onSpawn - Put any code you want to run on rez
// #define Attached$remoteloadCommand; - Put code in this if you want to override the standard remoteload call
// #define Attached$useOverride; - Uses listen override
// #define Attached$removeIfSpawnerNotFound - Detaches if the object that spawned it is not found in the sim

#define AttachedMethod$remove 0			// NULL

#define Attached$remove(attachmentName) runOmniMethod("jas Attached", AttachedMethod$remove, [attachmentName], TNN)
#define Attached$removeThis() runMethod((string)LINK_SET, "jas Attached", AttachedMethod$remove, [], TNN)
#define Attached$removeTarg(targ) runMethod(targ, "jas Attached", AttachedMethod$remove, ["*"], TNN)

onAttach(){}
