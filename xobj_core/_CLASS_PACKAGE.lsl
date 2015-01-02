#include "xobj_core/_CLASS_STATIC.lsl"
#define SCRIPT_IS_PACKAGE
list _OBJECTS;
list _INDEX;
list _INDEX_VARS = INDEXES;

integer CURRENT_WORK_OBJECT = -1;	// Index
#define UNINITIALIZED (CURRENT_WORK_OBJECT == -1)






// This Methods
#define this(param) llJsonGetValue(llList2String(_OBJECTS, CURRENT_WORK_OBJECT), [param])
#define this$replace(data)if(~CURRENT_WORK_OBJECT){ _OBJECTS = llListReplaceList(_OBJECTS, data, CURRENT_WORK_OBJECT, CURRENT_WORK_OBJECT); __rebuildIndex();}
#define this$setProperty(var, val) _OBJECTS = llListReplaceList(_OBJECTS, [llJsonSetValue(llList2String(_OBJECTS, CURRENT_WORK_OBJECT), [var], (string)val)], CURRENT_WORK_OBJECT, CURRENT_WORK_OBJECT); __rebuildIndex()
#define this$remove() if(~CURRENT_WORK_OBJECT){__remove(CURRENT_WORK_OBJECT); __rebuildIndex();}
#define this$data llList2String(_OBJECTS, CURRENT_WORK_OBJECT)


// Class methods
#define cls$setLast() CURRENT_WORK_OBJECT = llGetListLength(_OBJECTS)-1
#define cls$setIndex(index) CURRENT_WORK_OBJECT = (integer)index
#define cls$each(index, obj, fnAction)  integer index; for(index=0; index<llGetListLength(_OBJECTS); index++){ string obj=llList2String(_OBJECTS, index); fnAction}
#define cls$push(arr) _OBJECTS+=llList2Json(JSON_OBJECT, arr); __rebuildIndex()
#define cls$clear() CURRENT_WORK_OBJECT = -1
#define cls$index CURRENT_WORK_OBJECT

// Class properties
#define cls$length llGetListLength(_OBJECTS)




// Default methods
// Standard constructor
integer __construct(list args){return FALSE;}
__destruct(){} // Raised before current object is deleted
__indexed(){}	// Raised after re-indexed


// Automated, do not edit
__rebuildIndex(){
	#ifdef INDEXES
	_INDEX = [];
	integer i;
	for(i; i<llGetListLength(_INDEX_VARS); i++)_INDEX+="[]";
	cls$each(index, obj, {
		list_each(_INDEX_VARS, k, v, {
			string dta = llList2String(_INDEX, k);
			push(dta, llJsonGetValue(obj, [v]));
			_INDEX = llListReplaceList(_INDEX, [dta], k, k);
		});
	});
	__indexed();
	#endif
}
__remove(integer index){
	if(CURRENT_WORK_OBJECT < 0)return;
	__destruct();
	_OBJECTS = llDeleteSubList(_OBJECTS, CURRENT_WORK_OBJECT, CURRENT_WORK_OBJECT);
	CURRENT_WORK_OBJECT = -1;
	#ifdef INDEXES
	__rebuildIndex();
	#endif
}
integer __add(list args){
	integer ret = __construct(args); 
	__rebuildIndex(); 
	return ret;
}
list __search(string SEARCH, string IN){
    list WORK_OBJS = [-1];
    if(SEARCH != "" && IN != ""){
        WORK_OBJS = [];
        integer pos = llListFindList(_INDEX_VARS, [IN]); // Data 2 is index
        if(~pos){
            list idx = llJson2List(llList2String(_INDEX, pos));
            list_each(idx, i, val, {
                if(val == SEARCH)WORK_OBJS+=i;
            });
        }else{
            // Deep scan
            cls$each(idx, obj, {
                if(llJsonGetValue(obj, [IN]) == SEARCH)WORK_OBJS+=idx;
            });
        }
    }
    return WORK_OBJS;
}



