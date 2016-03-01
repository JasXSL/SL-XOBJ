#include "xobj_core/classes/jas JQL.lsl"
#include "xobj_core/_ROOT.lsl"
list prim_index;    // Contains the JQL prim numbers in order
list index;         // [(int)blockLength, (str)name, (int)primIndex, (int)face1, (int)prim2, (int)face2...]

#define metaPrim llList2Integer(prim_index, 0)
#define metaFace 0

#define get(prim, face) llDumpList2String(llGetLinkMedia(prim, face, [PRIM_MEDIA_HOME_URL, PRIM_MEDIA_CURRENT_URL, PRIM_MEDIA_WHITELIST]), "")
#define put(prim, face, data) llSetLinkMedia(prim, face, [\
    PRIM_MEDIA_HOME_URL, llGetSubString(data, 0, 1023), \
    PRIM_MEDIA_CURRENT_URL, llGetSubString(data, 1024, 2047),\
    PRIM_MEDIA_WHITELIST, llGetSubString(data, 2048, 3071), \
    PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_NONE, \
    PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_NONE \
]) \

#define cycleIndex(i, run) integer i; for(i=0; i<llGetListLength(index); i+=llList2Integer(index,i)){run }

#define throwError(table, message) llOwnerSay("JQL ERROR ["+table+"]: "+message)

// takes a table name and returns position
integer name2index(string name){
    cycleIndex(i,
        if(llList2String(index, i+1) == name)return i;
    )
    return -1;
}


string readTable(string table){
    integer pos = name2index(table);
    if(pos == -1)return JSON_INVALID;
    list faces = llList2List(index, pos+2, pos+llList2Integer(index, pos+1)-1);
    string out; integer i;
    for(i=0; i<llGetListLength(faces); i+=2)
        out+= get(
            llList2Integer(prim_index, llList2Integer(faces, i)),   // Prim
            llList2Integer(faces, i+1)                              // Face
        );
    return out;
}
integer saveTable(string table, string data){
    integer pos = name2index(table);
    if(pos == -1)return FALSE;
    
    list faces = llList2List(index, pos+2, pos+llList2Integer(index, pos+1)-1);
    
    integer i;
    for(i=0; i<llGetListLength(faces); i+=2){
        put(
            llList2Integer(prim_index, llList2Integer(faces, i)),   // Prim
            llList2Integer(faces, i+1),                             // Face
            llGetSubString(data, i/2*1024, i/2*1024+1023)           // Data
        );
    }
    return TRUE;
}


list where(list data, string query){
    list split = llParseString2List(query, [], ["AND", "OR"]);
    list out = [];
    list successes = [];
    list types = ["AND"];
    
    integer i;
    for(i=0; i<count(data); i++){
        list temp = llJson2List(llList2String(data, i));

        integer x; integer success; integer blockSuccess = TRUE;
        
        for(x = 0; x<llGetListLength(split) && !success; x+=2){
            list task = llParseString2List(llList2String(split, x), [], ["=", "!=", ">", ">=", "<", "<=", "IN", "HAS"]);
            
            integer idx = (int)llStringTrim(llList2String(task,0), STRING_TRIM);
            string operation = llStringTrim(llList2String(task, 1), STRING_TRIM);
            string check = llToLower(llStringTrim(llList2String(task, 2), STRING_TRIM));   // Value to check against
            string cur = llToLower(llList2String(temp, idx+1));    // Current value, +1 is cause JQL adds an index to the start of the task
            
            integer f = (
                (operation == "=" && check != cur) ||
                (operation == "!=" && check == cur) ||
                (operation == ">" && (float)check<=(float)cur) ||
                (operation == ">=" && (float)check<(float)cur) ||
                (operation == "<=" && (float)check>(float)cur) ||
                (operation == "<" && (float)check>=(float)cur) ||
                (operation == "IN" && llListFindList(llJson2List(check), [cur]) == -1) ||
                (operation == "HAS" && llSubStringIndex(cur, check) == -1)
            );
            
            if(f)blockSuccess = FALSE;
            if(llToUpper(llList2String(split, x+1)) == "OR" && blockSuccess){
                success = TRUE;
            }
        }
        
        if(success || blockSuccess)out+=i;
    }
    
    return out;
}


default
{
    state_entry()
    {
        
        list sortme = [];
        links_each(nr, name, 
            if(llGetSubString(name, 0, 2) == "JQL")
                sortme+= ([(integer)llGetSubString(name, 3, -1), nr]);
        )
        sortme = llListSort(sortme, 2, TRUE);
        prim_index = llList2ListStrided(llDeleteSubList(sortme,0,0), 0, -1, 2);
        
        // See if we can load the index
        string cur = get(metaPrim, metaFace);
        if(llJsonValueType(cur, []) == JSON_ARRAY){
            index = llJson2List(cur);
        }
        //qd(mkarr(index));
    }
    
    #include "xobj_core/_LM.lsl"
    /*
        Included in all these calls:
        METHOD - (int)method
        PARAMS - (var)parameters
        SENDER_SCRIPT - (var)parameters   
        CB - The callback you specified when you sent a task
    */ 
    if(method$isCallback){
        return;
    }
    
    
    
    
                    // MANAGE TABLES //
    
    if(METHOD == JQLMethod$create_table){
        string name = method_arg(0);
        integer faces = llCeil((float)method_arg(1)/3);
        if(faces < 0)return;
        
        if(~name2index(name)){
            return throwError(name, "Table already exists.");
        }
        
        // Reserve some prims
        list meta = [
            0,                  // Length of block, set at end
            name                // Name of table
        ];
        list reserved = [];     // (int)primIndex, (int)face
        
        integer i; integer x;
        for(i=0; i<count(prim_index) && llGetListLength(reserved)/2<faces; i++){
            for(x=0; x<9 && llGetListLength(reserved)/2<faces; x++){
                
                integer taken = (i+x == 0);
                if(!taken){
                    cycleIndex(_idx,
                        list blocks = llList2List(index, _idx+2, llList2Integer(index,_idx)-1);
                        integer _i;
                        for(i=0; i<llGetListLength(blocks); _i+=2){
                            if(llList2Integer(blocks, _i) == i && llList2Integer(blocks, _i+1) == x){
                                taken = TRUE;
                                i = llGetListLength(index);
                            }
                        }
                    ) 
                }
                
                if(!taken){
                    reserved+= [i, x];
                    put(llList2Integer(prim_index, i), x, "");
                }
            }
        }
        
        if(llGetListLength(reserved)/2 < faces){
            throwError(name, "Database is full.");
            return;
        }
        meta+= reserved;
        // Index it
        index+= llListReplaceList(meta, [llGetListLength(meta)], 0, 0);
        
        // Save the index
        put(metaPrim, metaFace, mkarr(index));
        CB_DATA = [TRUE];
    }
    
    else if(METHOD == JQLMethod$delete_table){
        integer pos = name2index(method_arg(0));
        if(pos == -1)return;
        index = llDeleteSubList(index, pos, llList2Integer(index, pos)-1);
        put(metaPrim, metaFace, mkarr(index));
        CB_DATA = [TRUE];
    }
    
    
    
    
    
    
                    // PUT DATA //
    else if(METHOD == JQLMethod$insert){
        string data = readTable(method_arg(0));
        if(data == JSON_INVALID)return throwError(method_arg(0), "Table not found.");
        list parse = llJson2List(data);
        data = "";
        integer insertID = (integer)j(llList2String(parse, -1),0);
        list ids = [];
        
        list inserts = llJson2List(method_arg(1));
        list_shift_each(inserts, data,
            insertID++;
            parse+= mkarr([insertID]+llJson2List(data));
            ids+= insertID;
        )

        CB_DATA = [saveTable(method_arg(0), mkarr(parse)), mkarr(ids)];
    }
    
    else if(METHOD == JQLMethod$update){
        string table = method_arg(0);
        string data = readTable(table);
        if(data == JSON_INVALID)return throwError(method_arg(0), "Table not found.");
        list keys = llJson2List(method_arg(1));
        list vals = llJson2List(method_arg(2));
        if(keys != vals)return throwError(table, "Keys and vals length do not match");
        
        list parse = llJson2List(data); data = "";
        list indexes = where(parse, method_arg(3));

        // No need to set anything if nothing passed filter
        if(llGetListLength(indexes)){
            integer i;
            for(i=0; i<llGetListLength(indexes); i++){
                integer idx = llList2Integer(indexes, i);
                list cur = llJson2List(llList2String(parse, idx));
                integer x;
                for(x = 0; x<llGetListLength(keys); x++){
                    integer k = llList2Integer(keys, x)+1;
                    cur = llListReplaceList(cur, llList2List(vals,x,x), k,k);
                }
                parse = llListReplaceList(parse, [mkarr(cur)], idx, idx);
            }
            saveTable(table, mkarr(parse));
        }
        CB_DATA = [llGetListLength(indexes)];
    }
    
    else if(METHOD == JQLMethod$delete){
        string table = method_arg(0);
        string data = readTable(table);
        if(data == JSON_INVALID)return throwError(method_arg(0), "Table not found.");
        
        list parse = llJson2List(data);
        list indexes = where(parse, method_arg(1));

        integer num_deleted;
        list_shift_each(indexes, idx,
            integer i = (integer)idx-num_deleted;
            parse = llDeleteSubList(parse, i, i);
            num_deleted++;
        )
        if(num_deleted){
            saveTable(table, mkarr(parse));
        }
        CB_DATA = [num_deleted];
    }
    
    
    
    
                    // GET DATA //
    else if(METHOD == JQLMethod$select){
        string data = readTable(method_arg(0));
        if(data == JSON_INVALID)return throwError(method_arg(0), "Table not found.");
        list parse = llJson2List(data);
        data = "";
        list indexes = where(parse, method_arg(2));
        
        // Fields to return (along with ID)
        list fields = [];
        if(llJsonValueType(method_arg(1), []) == JSON_ARRAY)
            fields = llJson2List(method_arg(1));

        list out = []; integer orderBy = (integer)method_arg(3)+1;
        list_shift_each(indexes, idx,
            
            list data = llJson2List(llList2String(parse, (int)idx));
            list ret = [llList2Integer(data, 0)];   // Always add the ID
            if(fields == [])ret = data;
            else{
                integer i;
                for(i=0; i<llGetListLength(fields); i++){
                    integer f = llList2Integer(fields, i)+1;
                    ret+= llList2List(data, f, f);
                }
            }
            out+= llList2List(data, orderBy, orderBy)+[mkarr(ret)];
        )
        out = llList2ListStrided(llDeleteSubList(llListSort(out, 2, TRUE), 0, 0), 0, -1, 2);
        
        CB_DATA = out;
    }
    
    
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
    
}
