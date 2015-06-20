
#define fxWrapper$remByName(name) FX_buildWrapper(0,0,([0,FX_buildPackage(0,0,0,0,"","","",[FX_buildFX(fx$REM_FX_BY_NAME, [name])],[],[],[],0)]))

#define fxWrapper$sitRape(primKey, duration) FX_buildWrapper(0,0,([0,FX_buildPackage(duration,0,PF_DETRIMENTAL|PF_UNIQUE,0,"sitRape","","",[FX_buildFX(fx$FORCE_SIT, [llGetKey(), FALSE]), FX_buildFX(fx$RAPE, [])],[FX_buildCondition(fx$COND_NOT_RAPED, [])],[FX_buildEvent(StatusEvt$VULNERABLE, "ots Status", TARG_VICTIM, 0, fxWrapper$remByName("sitRape"))],[],0)]))



