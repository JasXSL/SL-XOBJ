
#define fxWrapper$remByName(name) FX_buildWrapper(0,0,([0,FX_buildPackage(0,0,0,0,"","","",[FX_buildFX(fx$REM_FX_BY_NAME, [name])],[],[],[],0)]))

#define fxWrapper$sitRape(primKey, duration) FX_buildWrapper(0,0,([0,FX_buildPackage(duration,0,PF_DETRIMENTAL|PF_UNIQUE,0,"sitRape","","",[FX_buildFX(fx$FORCE_SIT, [llGetKey(), FALSE]), FX_buildFX(fx$RAPE, [])],[FX_buildCondition(fx$COND_NOT_RAPED, [])],[FX_buildEvent(StatusEvt$VULNERABLE, "ots Status", TARG_VICTIM, 0, fxWrapper$remByName("sitRape"))],[],0)]))

#define fxWrapper$text(text, color) FX_buildWrapper(0,0,[0,FX_buildPackage(0,0,0,0,"","","",[FX_buildFX(fx$SETTEXT, [text, color])],[],[],[],0)])

#define fxWrapper$knockdown() "[0,0,0,[3,0,2,0,\"knockdown\",\"\",\"\",[[4],[6,\"knockdown\",1]],[],[],[6],0]]"


#define fxEvt$textOnRemove(text, color) FX_buildEvent(INTEVENT_ONREMOVE, "", TARG_VICTIM, 0, fxWrapper$text(text, (color)))

