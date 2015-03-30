/*
	
	Installing soundspaces
	1. Create 2 prims on your HUD create a new script in one of them and name it st Soundspace
	2. Include your _core.lsl file
	3. #include "xobj_core/classes/packages/st Soundspace.lsl"
	4. Create a new script in the same prim as st Soundspace, name it "st SoundspaceAux"
	5. Make sure you have st SoundspaceAux on drive.
	6. At the top of your st SoundspaceAux include your _core.lsl file
	7. enter #define THIS_SUB 1
	8. Enter #include "xobj_core/classes/packages/st SoundspaceAux.lsl"
	9. Compile
	10. Go to the second prim and create another script named st SoundspaceAux
	11. Copy+paste the code from your previous st SoundspaceAux into the new one but replace #define THIS_SUB 1 with #define THIS_SUB 2
	12. Done!
	
	Usage:
	To override current soundspace with the underwater soundspace, use Soundspace$dive(integer underWater)
	Soundspaces are gained by the closest item 10m underneath you.
	See st Interact for description setup.

*/

#define SoundspaceMethod$dive 1				// Overrides any soundspace with underwater sounds

// List of implemented soundspaces
#define SP_RAIN "ra"
#define SP_RAIN_INTERIOR "ri"
#define SP_RAIN_SHELTERED "sh"
#define SP_NIGHT "ni"
#define SP_RUMBLE "ru"
#define SP_DRONE_DARK "dd" 	// Drone2
#define SP_DRONE_HOLLOW "dh" //
#define SP_COMPUTER "co"
#define SP_UNDERWATER "uw"
#define SP_NIGHT_INT "in"	
#define SP_INT_FIREPLACE "fp"
#define SP_SEWER_DRIP "dr"
#define SP_SEWER_STREAM "st"
#define SP_SEWER_WATERFALL "wf"
#define SP_CINEMA "ci"

// 2-strided list of soundspaces if you want to add more
#define SP_DATA [SP_RAIN_INTERIOR, "f8c6e681-e2a1-6e71-a38d-7323391d8c64", SP_RAIN_SHELTERED, "165a41d5-12ab-8b71-1fda-6590f616fded", SP_RAIN, "766f250a-410b-81e6-21ec-bfbea99947cc", SP_NIGHT,"2d371ae8-53fa-d640-4faa-b97395c91caa", SP_RUMBLE,"10b0ad90-d8b1-0552-019d-ec8eb853cf6d", SP_DRONE_DARK,"bb72e416-7956-19ce-cc4d-cf5e80a58a2a", SP_DRONE_HOLLOW,"e34305af-0337-7632-5bfb-74e875f0a21d", SP_COMPUTER,"fd36026d-5945-ccc0-b4c3-728f5b79b32c", SP_UNDERWATER,"d0a2c412-34a3-46e1-6668-72281424ede1", SP_NIGHT_INT, "767b9f46-876f-701e-5d7d-e946263c71c3", SP_INT_FIREPLACE,"7515a1f4-a497-2aef-6885-b4bf78f27d65", SP_SEWER_DRIP,"a8ee5281-4e30-2a86-67d9-66c10084ff9a", SP_SEWER_STREAM,"7f2ba05d-9d7b-37f6-6c74-f221fec33426", SP_SEWER_WATERFALL,"52174c27-9c54-a2fd-abf7-b38e2175646e", SP_CINEMA, "c80c9883-9575-22d2-d0a8-1c8b413216e3"]


#define Soundspace$dive(submerged) runMethod((string)LINK_ALL_OTHERS, "st Soundspace", SoundspaceMethod$dive, [submerged], TNN)


