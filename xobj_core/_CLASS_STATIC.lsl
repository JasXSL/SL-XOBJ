#define cls$name llGetScriptName()

// General
#define method_arg(index) llJsonGetValue(PARAMS, [index])
#define jVal(obj, index) llJsonGetValue(obj, index)
#define fn_arg(index) llList2String(args, index)
#define memLim(multi) llSetMemoryLimit(llCeil((float)llGetUsedMemory()*multi))

#define method$byOwner id == "" || llGetOwnerKey(id) == llGetOwner()
#define method$internal id == ""
#define method$isCallback nr == METHOD_CALLBACK



