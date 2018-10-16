/*
	Refer to st Primswim's header file for setup instructions.
*/
#define Primswim$partChan playerChan(llGetOwner())+0x1717 

#define PrimswimAuxMethod$spawn 1

#define PrimswimAux$spawn() runMethod((str)LINK_THIS, "jas PrimswimAux", PrimswimAuxMethod$spawn, [], TNN)


