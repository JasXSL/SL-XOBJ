/*
	Refer to st Primswim's header file for setup instructions.
*/
#define PrimswimAuxMethod$particleset 1		// (int)set, (vec)pos
#define PrimswimAuxMethod$killById 2		// (str)id




#define PrimswimAux$particleset(set, pos) runMethod((string)LINK_THIS, "jas PrimswimAux", PrimswimAuxMethod$particleset, [set,pos], TNN)
#define PrimswimAux$killById(id) runMethod((string)LINK_THIS, "jas PrimswimAux", PrimswimAuxMethod$killById, [id], TNN)

