#define SceneMethod$start 1				// (obj)scene, (var)callback		- 
#define SceneMethod$stop 2				// NULL								- 
#define SceneMethod$getMonsterScene 3	// [(int)monster(or -1 for total random), (vec)pos_offset_global, (rot)rot_global, (int)selfcastMonsterID or 0] - Gets a random scene by monster, returns true or false 

#define evt$SCENE_START_EVENT 1		// {t:(int)type} Scene has started
#define evt$SCENE_ON_END_EVENT 2	// {t:(int)type} Scene has gone into onEnd state 
#define evt$SCENE_KILL_EVENT 3		// {t:(int)type} Scene has been killed

#define Scene$start(scenedata) runMethod((string)LINK_THIS, "jas Scene", SceneMethod$start, [scenedata], TNN)
#define Scene$stop() runMethod((string)LINK_THIS, "jas Scene", SceneMethod$stop, [], TNN)
#define Scene$getMonsterScene(targ, monster, posOffset, rotOffset, selfCastMonsterID) runMethod(targ, "jas Scene", SceneMethod$getMonsterScene, [monster, posOffset, rotOffset, selfCastMonsterID], TARG_NULL, llGetScriptName(), "")

