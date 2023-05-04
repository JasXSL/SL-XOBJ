/*
	Refer to st Primswim's header file for setup instructions.
*/
#define Primswim$partChan playerChan(llGetOwner())+0x1717 

#define PrimswimAuxMethod$spawn 1

#define PrimswimAux$spawn() runMethod((str)LINK_THIS, "jas PrimswimAux", PrimswimAuxMethod$spawn, [], TNN)


// Sound defaults
#ifndef PrimswimAuxCfg$splashBig
	#define PrimswimAuxCfg$splashBig "cb50db39-8fb7-acd2-21e7-ef37cc2e0030"
#endif 
#ifndef PrimswimAuxCfg$splashMed
	#define PrimswimAuxCfg$splashMed "58bab621-cbec-175a-2b55-fc2810e96d7c"
#endif
#ifndef PrimswimAuxCfg$splashSmall
	#define PrimswimAuxCfg$splashSmall "0eccd45f-8a31-1263-c4c2-cbe80a27696b"
#endif

#ifndef PrimswimAuxCfg$soundExit
	#define PrimswimAuxCfg$soundExit "2ade5961-3b75-f8cf-ca78-7f64cd804572"
#endif
#ifndef PrimswimAuxCfg$soundStroke
	#define PrimswimAuxCfg$soundStroke "975f7f5d-320c-94a7-e31f-1cc5547081e8"
#endif
#ifndef PrimswimAuxCfg$soundSubmerge
	#define PrimswimAuxCfg$soundSubmerge "c72c63dc-7ca2-fde7-41d8-6f63b3360820"
#endif

#ifndef PrimswimAuxCfg$footstepSpeed
	#define PrimswimAuxCfg$footstepSpeed .4
#endif

#ifndef PrimswimAuxCfg$soundFootstepsShallow
	#define PrimswimAuxCfg$soundFootstepsShallow ["d2a62376-8569-274d-3378-b33028915845", "88179970-4fb8-9fe8-c1c0-c6c8a112ede8", "200548aa-c2c7-c32c-77fc-6ad9acef65a9"]
#endif
#ifndef PrimswimAuxCfg$soundFootstepsMed
	#define PrimswimAuxCfg$soundFootstepsMed ["6ff37e21-b76e-45c5-bb17-0f40af500b50", "d7e3be48-bdeb-6e7e-644e-6cfaee33effc", "d69f45ec-346b-bd5c-2b62-0de4fc60a5c0", "53bbd8c6-4e49-88e0-006c-7ce6987db83c"]
#endif
#ifndef PrimswimAuxCfg$soundFootstepsDeep
	#define PrimswimAuxCfg$soundFootstepsDeep ["21f9d648-dab6-e8aa-fc96-20f516061852", "0c21ae4c-f542-4e44-baa5-7f3d9b9600e3", "3b8f13f2-727b-e80c-7d25-28c9601bf651", "a5048f46-2b7f-8ba4-db08-e962e6c0f9c8"]
#endif


