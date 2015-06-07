The root input file is used to accept inputs and forward them to the right scripts.
You can create it any way you want, but here's my recommended one:

```
#define SCRIPT_IS_ROOT
#include "myFirstProject/_core.lsl"

default 
{
    on_rez(integer mew){
        resetAll();  
    }
    
    state_entry()
    {
        resetAllOthers();
        initiateListen();
        if(llGetAttached())
            llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
    }

    
    touch_start(integer total){
        if(llDetectedKey(0) != llGetOwner())return;
        raiseEvent(evt$TOUCH_START, llList2Json(JSON_ARRAY, [llDetectedLinkNumber(0), llDetectedKey(0)]));
    }
    touch_end(integer total){ 
        if(llDetectedKey(0) != llGetOwner())return;
        raiseEvent(evt$TOUCH_END, llList2Json(JSON_ARRAY, [llDetectedLinkNumber(0), llDetectedKey(0)]));
    }
    run_time_permissions(integer perm){
        if(perm&PERMISSION_TAKE_CONTROLS){
            llTakeControls(CONTROL_ML_LBUTTON|CONTROL_UP, TRUE, FALSE);
        }
    }
    
    changed(integer change){
        if(change&CHANGED_INVENTORY){
            llSleep(1);
            resetAll();
        }
    }
    
    control(key id, integer level, integer edge){
        if(level&edge)raiseEvent(evt$BUTTON_PRESS, (string)(level&edge));
        if(~level&edge)raiseEvent(evt$BUTTON_RELEASE, (string)(~level&edge));
    }

    #include "xobj_core/_LISTEN.lsl"
}
```



