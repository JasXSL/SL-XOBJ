#include "xobj_core/_CLASS_STATIC.lsl"
#define THIS_SUB 2

float vol_max = 1;
float vol;
integer BFL;
#define BFL_DIR_UP 1
string sound_next;


timerEvent(string id, string data){
    if(id == "A"){
        if(BFL&BFL_DIR_UP){
            vol+=.05;
            if(vol>vol_max){
                vol = vol_max;
                multiTimer(["A"]);
                sound_next = "";
            }
        }else{
            vol-=.05;
            if(vol<0){
                vol = 0;
                if(sound_next != ""){
                    llLoopSound(sound_next, 0.01);
                    BFL = BFL|BFL_DIR_UP;
                }else{
                    multiTimer(["A"]);
                }
            }
        }
        llAdjustSoundVolume(vol);    
    }
}

default
{
    state_entry()
    {
        llStopSound();
        llSetMemoryLimit(llCeil(llGetUsedMemory()*1.5));
    }
    
    timer(){
        multiTimer([]);
    }
    
    #include "xobj_core/_LM.lsl" 
    /*
        Included in all these calls:  
        METHOD - (int)method 
        INDEX - (int)obj_index
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task
    */
        if(method$isCallback){
            return;
        }
        if(id != "")return;
        
        integer sub = (integer)method_arg(0);
        if(sub != THIS_SUB && sub != -1)return;
        
        if(METHOD == SoundspaceAuxMethod$start){
            BFL = BFL|BFL_DIR_UP;
            vol_max = (float)method_arg(2);
            sound_next = method_arg(1);
            if(vol == 0)llLoopSound(sound_next,0.01);
            else BFL = BFL&~BFL_DIR_UP;
            multiTimer(["A", "", .05, TRUE]);
        }else if(METHOD == SoundspaceAuxMethod$stop){
            BFL = BFL&~BFL_DIR_UP;
            multiTimer(["A", "", .05, TRUE]);
            sound_next = "";
        }
        
        
    #define LM_BOTTOM   
    #include "xobj_core/_LM.lsl" 
}


