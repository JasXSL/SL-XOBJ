//#define SoundspaceAuxMethod$stop 1			// (int)controller, (key)uuid, (float)vol
//#define SoundspaceAuxMethod$start 2			// (int)controller
#define SoundspaceAuxMethod$set 1				// (int)controller, (key)uuid, (float)vol

#define SoundspaceAux$set(controller, uuid, vol) runMethod((str)LINK_SET, "jas SoundspaceAux", SoundspaceAuxMethod$set, [controller, uuid, vol], TNN)



