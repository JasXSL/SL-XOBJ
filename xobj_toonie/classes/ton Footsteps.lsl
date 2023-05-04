/*
	
	Footsteps is a simple footstep script for walking and a thud script when hitting the ground
	The thud function will be raised when hitting the ground at a fair speed
	
	Z is the downwards absolute velocity 
	onThud(float z){
		
	}
	
	Install:
	1. Create a new script and name it ton Footsteps
	2. Include your _core.lsl file
	3. Include any other files you want
	4. add onThud(float z){} which is raised when landing heavily
	5. 	#include "xobj_toonie/classes/packages/ton Footsteps.lsl"
	6. Compile and enjoy ^.^
	
	See xobj_core/classes/jas Interact.lsl for object descriptions
	
*/


list SOUNDS;
list COLS;
init(){
	SOUNDS = [
		"DEFAULT",
		(key)"3ab45c85-0d7e-606f-75c6-a2719f80f383",
		(key)"6ec26ca3-bf66-7e9e-eac4-7ab266391f16",
		(key)"b01678af-eefe-9917-6438-46bbe8a60ec2",
		"TILE",
		(key)"b92b13b5-6444-2354-95fb-d040a8f02e4a",
		(key)"91bb6696-1ac8-850a-ab25-fea22a30bc55",
		(key)"2096982e-87c5-ba2d-82bc-a5225072166d",
		(key)"5984e2cc-dc58-f05d-d966-ced16a350886",
		"WOOD",
		(key)"1b115ed4-a41f-d40a-6c6f-7212a1690e0c",
		(key)"0a601cd1-6e04-0ec3-77b9-fe25ddfa277d",
		(key)"0a601cd1-6e04-0ec3-77b9-fe25ddfa277d",
		(key)"5efb72d1-45fa-f78a-3203-90d370358efd",
		(key)"9a6b08a9-c14d-8bf3-636e-a4c91677b08f",
		"GRASS",
		(key)"89e47593-e02e-f292-6afe-7766b3345077",
		(key)"9a124d26-31a8-f478-18df-80c077d4e1cd",
		(key)"887b575c-da8f-7318-0da6-b84390f2ba70",
		(key)"9240b445-a43d-ed03-d3ac-dd50e8d937b4",
		(key)"a4c92b46-1314-9b58-230d-050633cba29c",
		"CARPET",
		(key)"4ce80406-2d5d-8c4d-efd4-ee3ab5679a21",
		(key)"f8687c50-7c26-9403-3e2a-650f2e02f453",
		(key)"9d19285f-7bb7-47f4-b822-4ceb0417a18d",
		(key)"1710be41-eec3-91a4-61b3-57f6324e74e7",
		(key)"fd2c609f-ec7e-1a3b-c60c-414963338130",
		"SAND",
		(key)"5d6bb6d2-93d4-55df-f271-a517adb79a3b",
		(key)"f6be521b-4f06-ab91-7c2b-75e07370869d",
		(key)"8af8d348-aa46-4083-318d-630692e175cc",
		(key)"9301239c-e92c-d6ad-88c4-5941a56a7a8c",
		"CREEKY",
		(key)"33a8166c-8331-a4c7-d980-4621046c48c5",
		(key)"e2bcb428-54e8-f6bb-e474-2b28e531181a",
		(key)"db5e2629-fccb-1ae3-7052-8f4905af50f6",
		(key)"1a82b0e2-b068-2886-b4f3-30654a551694",
		(key)"57ea1de9-edcf-9c4d-07b4-7757cad2d26b",
		(key)"1df06327-5017-753c-029e-ef1c8d29d650",
		(key)"24afee02-fccf-8431-48bd-5fb9f5c26e4f",
		(key)"372497e1-7e19-8e60-0cc0-376f787ef76d",
		"HWD", // Hardwood
		(key)"a5642a10-143c-6fd5-fed3-35e7c091a409",
		(key)"812d7bf9-6f5d-e7cc-bcc8-9c89c94cd89a",
		(key)"8fb332e0-7863-3b68-3b4e-0a9b184c6cd8",
		(key)"0072c548-5102-c6dc-9a18-bb96af53eaac",
		"HOW", // Hollow wood
		(key)"a6ca8b74-087f-ff1b-8ebf-4647693438b2",
		(key)"554e2b87-c32e-91ed-56b8-e2d3249af56b",
		(key)"1255eec7-d196-82fc-9edf-d16974c4235a",
		(key)"692eb3bc-4ca6-7857-4677-f3931d06004f",
		"SLM", // SLIME
		(key)"67850540-2107-1474-37d8-6cb89b2a8773",
		(key)"8e5f4532-d073-627e-bb2c-d06a1ad3b01f",
		(key)"e536f03a-9d39-100b-ede6-5b852bffbf22",
		(key)"59f8cbe4-8882-6367-d1d6-ce469a3a9460",
		"GRT", // Grate
		(key)"ad1131d8-b435-b5e1-c4ae-ed0146400163",
		(key)"703320fe-db93-a4e3-0117-bb92de5bda9d",
		(key)"482d7ef2-5611-1601-7181-e1d0cc1abe58",
		"ASP", // Asphalt
		(key)"56addba7-e548-b3f0-0e00-83f42ae1d18d",
		(key)"97698837-9c1b-12b5-b885-f8f522e41c51",
		(key)"c45cf806-8d58-00fa-39b4-97fbbada9a80",
		(key)"e85c5b13-397e-28ec-a326-3356997e12c2",
		"WTR", // Water
		(key)"21f9d648-dab6-e8aa-fc96-20f516061852", 
		(key)"0c21ae4c-f542-4e44-baa5-7f3d9b9600e3", 
		(key)"3b8f13f2-727b-e80c-7d25-28c9601bf651",
		(key)"a5048f46-2b7f-8ba4-db08-e962e6c0f9c8",
		"CBS", // Cobblestone
		(key)"49ab80f2-de46-2ae5-1e59-d23c722c3ee3",
		(key)"b35677a5-7fbe-f6e4-bedd-6637b61a2e99",
		(key)"d31a5d1e-1aae-d1b1-36a5-97b5c6c7c712",
		(key)"e2b8d5d2-36aa-8dbd-c7f9-5f4b14748049",
		"STN", // Stone
		(key)"0f75f3b4-289b-c4fa-bec9-8f70f135fa32",
		(key)"d2e81862-c7c3-df34-1784-4c00002b277c",
		(key)"347b57f9-007d-096b-acdb-ed9294fce8bc",
		(key)"fdf53f61-a06e-f10f-f352-9acef84f8384",
		"MTL", // Metal
		(key)"72a4beba-50e5-b000-58cb-7727da1c857e",
		(key)"27c5cbbe-6de8-1bad-6993-c240a395fd91",
		(key)"af6b498f-789e-6f6b-18e5-add00b2d5ef7",
		"SNW", // Snow
		(key)"96231a18-9328-cf5a-21d6-18440b7ee1e8",
		(key)"b65aaab0-ba50-3651-89c2-3a54958564a4",
		(key)"e4aedc26-c31a-307c-4466-87c305ff4888",
		(key)"2f67fc13-8892-6186-f5ab-c5226e7259bf",
		"GRV", // Gravel
		(key)"2344ea8f-a72b-a1c0-1ca1-33beca50d48d",
		(key)"808fb5cd-9778-d31b-4fb5-bcb05b5e01bc",
		(key)"eff6a567-0385-f155-790b-4e750b120ff7",
		(key)"3a2d4f9c-ae12-694a-225c-d15281e2f61d",
		"FOL", // Foliage
		(key)"d88e6d5b-9e62-d6d6-47de-708e0f3aa2d0",
		(key)"6ccbab84-66bb-b929-7e42-2b7c3bc3c303",
		(key)"26aded65-4df0-9751-1177-f655d7f06b15",
		(key)"0b69ae8b-f3f2-376c-9b08-364e0acfc921",
		"MTR",	// Swim mattress
		(key)"e037874e-db50-e4f2-8bca-8e24d24aa602",
		(key)"393191af-41dc-8b9c-5c96-bda9a47ccaa2",
		(key)"f1927a9b-0890-cbb8-44ea-dce2c7545b28",
		(key)"1b087621-fbcd-3281-488f-1a9d8016831b"
	];
	
	COLS = [
		"DEFAULT",
		(key)"99038894-7a2b-e1a0-30dc-9b1a542df0e0",
		"TILE",
		(key)"2516d068-ad1d-8779-9797-2f075ce4e339",
		"WOOD",
		(key)"577a2615-58ca-66f0-f9e8-dae50bf18ca7",
		"GRASS",
		(key)"1b693f15-8e36-8f80-004d-328b2ff4d2e0",
		"SAND",
		(key)"0fccdae2-e30e-51bd-b9d8-0ee047e1fe3a",
		"CREEKY",
		(key)"577a2615-58ca-66f0-f9e8-dae50bf18ca7",
		"HWD",
		(key)"577a2615-58ca-66f0-f9e8-dae50bf18ca7",
		"SLM", (key)"ca2d9f5d-2768-edc9-a989-885c80df5cc3",
		"GRT", (key)"51c25332-b1e1-f3dc-ae1c-bda4158f26af",
		"ASP", (key)"0fccdae2-e30e-51bd-b9d8-0ee047e1fe3a",
		"WTR", (key)"d3b5210b-1e6f-9e43-42ca-59cbfdec847e",
		"CBS", (key)"99038894-7a2b-e1a0-30dc-9b1a542df0e0",
		"STN", (key)"99038894-7a2b-e1a0-30dc-9b1a542df0e0",
		"MTL", (key)"94fbf5e9-a6c2-8b66-2f5f-13170ae2590f",
		"SNW", (key)"701a3f4b-6f88-03d5-9849-0358da96b271",
		"GRV", (key)"e4e5d44c-0864-3f23-516a-76985cc9df23",
		"FOL", (key)"b2c8aea0-f9a0-7e8e-a547-fb2297b7e8e2"
		
	];
}

#ifndef FootstepsCfg$SPEED
	#define FootstepsCfg$SPEED .4
#endif
#ifndef FootstepsCfg$WALK_VOL
	#define FootstepsCfg$WALK_VOL .1
#endif
#ifndef FootstepsCfg$RUN_VOL
	#define FootstepsCfg$RUN_VOL .2
#endif
#ifndef FootstepsCfg$CROUCH_VOL
	#define FootstepsCfg$CROUCH_VOL .01
#endif








