#ifndef __DB4
#define __DB4
/*
    DB4 creates sequential LSD auto increase int keys and assigns them as chars
    Each table is assigned 1 character as an identifier (referred to as tableChar or ch)
    Each row is assigned 1 character corresponding to its ID

    Limitations:
    - If creating your own tables outside of DB4, use at least 3 character length. 
        DB4 lsd indexes are always one or two characters long, and span all character combinations.
    - You cannot use an empty table name
    - It does not check for deleted keys. 
        If you delete many many entries from a table, you may want to reindex to speed things up.
    
    
    Table names:
    
    "$d4" : Stores a JSON array of each table. 
            The order they are stored in decides their tableChar with llChar(indexInArray+1)
        [name0, name1...]
    
    (char table) : A single tableChar is used to mark metadata.
                    It stores the current auto increase index and a full name for debugging.
        {
            "i" : (int)ai_idx,
            "_" : (str)full_name
        }
    (char table)(char row) : A tableChar followed by a row ID converted to a char is a table row.
                            It stores a JSON array. 
                            The first value is always the unique table ID as an integer (auto created).
                            The rest of the values are user specified.
        [(int)id,val0,val1...]
    
*/


// #define db4$PASS ""          Todo: Use to enable password protect

// NOTE: "char" below is used to represent an integer stored as a single character string.
// NOTE: Plus notation lets you make a list by using a plus, or inputting a single value.
//      A benefit is that the preprocessor does not throw a fit when you use [] in a macro.
//      A drawback is that if you are going to use + for math or string joining in the macro, you must wrap that in parentheses
//      Example: Instead of ["var1", "var2"] you can do "var1" + "var2". And instead of ["var"] you can do "var"
//      

// Have the root script create tables. This is recommended because it prevents race conditions. stdMethod$setShared is run as a callback on table creation.
// note: if a table exists nothing happens, and the callback stdMethod$setShared will still include the table
#define db4$createTables(tables) llMessageLinked(LINK_ROOT, DB4_ADD, llList2Json(JSON_ARRAY, (list)llGetScriptName() + mkarr((list)tables)), "")

#define db4$ofs 32	// Added to every table and insert char. Because SL breaks if you use a lower number.

// Create a table with a name (string). Name cannot be empty. XOBJ prefers the use of a #ROOT script. When using a #ROOT script, use db4$createTables
// Returns a tableChar string of the newly created table
#define db4$createTableLocal(name) _4c(name)
// Drop a table and all its data by name (string)
#define db4$dropTable(name) _4d(name)

// Convert an a table name to a table char
#define db4$getTableChar(n) \
    llChar( \
        llListFindList( \
            llJson2List( \
                llLinksetDataRead("$d4") \
            ), \
            (list)n \
        )+db4$ofs \
    )

// Get a row from a table by table name (string) and row ID (int)
#define db4$get(table, id) \
    llJson2List(llLinksetDataRead(db4$getTableChar(table) + llChar(id+db4$ofs)))
// Delete a row from a table by table name (string) and row ID (int)
#define db4$delete(table,id) \
    llLinksetDataDelete(db4$getTableChar(table) + llChar(id+db4$ofs))
// Replace the contents of a row with data (list) by specifying table (string) and id (int). 
// Do not enter ID in the replacement, it is auto added.
// Data can use plus notation
// Note: Replacing a row with an ID greater than the current auto increase index will cause it to be overwritten when performing an insert
// 	I only suggest you do this if you want to hard code the index and ONLY use db4$replace, and never insert
#define db4$replace(table, id, data) \
    llLinksetDataWrite(db4$getTableChar(table) + llChar(id+db4$ofs), mkarr((list)(id) + data))


// You can cache the tableChar as a string with db4$getTableChar or on table creation.
// By using a tableChar you can speed up your calls a little by not having to convert a table name to a char
// Same as above non-fast, but use a tableChar instead of a table name
#define db4$getFast(tableChar, id) \
    llJson2List( llLinksetDataRead( tableChar + llChar(id+db4$ofs) ))
#define db4$deleteFast(tableChar,id) \
    llLinksetDataDelete(tableChar + llChar(id+db4$ofs))
#define db4$replaceFast(tableChar, id, data) \
    llLinksetDataWrite(tableChar + llChar(id+db4$ofs), mkarr((list)(id) + data))

// Gets the first unused ID from a table, or returns 0 if it has no free ones.
// Can be used if you want to reuse deleted row IDs, but is not recommended.
#define db4$getFreeId(table) _4f(table, FALSE)
#define db4$getFreeIdFast(tableChar) _4f(tableChar, TRUE)

// Gets the next insert ID for a table. Differs from freeId in that it always returns the next ID that will be inserted.
#define db4$getMax(table) \
    ((int)j(llLinksetDataRead(db4$getTableChar(table)), "i"))
#define db4$getMaxFast(tableChar) \
    ((int)j(llLinksetDataRead(tableChar), "i"))

	
// Inserts a new row by table (str) and a list of data.
// Data can use plus notation
#define db4$insert(table,data) _4i(table, (list)data, FALSE)
// Same as above but uses a tableChar
#define db4$insertFast(tableChar,data) _4i(tableChar, (list)data, TRUE)

// Tries to print a table in a readable format. Fields are used as headlines for each column. ID is not needed, it is auto added.
// Supports plus notation
#define db4$dump(table, fields) _4du(table, (list)fields)


// Loop over all entries of a table
#define db4$each(table, dataVar, code) \
    { \
        string _c = db4$getTableChar(table); \
        integer _m = (int)j(llLinksetDataRead(_c), "i"); \
        integer _i; string _d; \
        for(; _i < _m; ++_i ){ \
            _d = llLinksetDataRead(_c+llChar(_i+db4$ofs)); \
            if( _d ){ \
                list dataVar = llJson2List(_d); \
                code \
            } \
        } \
    }
// Same as above but uses tableChar to save time and memory
#define db4$eachFast(tableChar, dataVar, code) \
    { \
        integer _m = (int)j(llLinksetDataRead(tableChar), "i"); \
        integer _i; string _d; \
        for(; _i < _m; ++_i ){ \
            _d = llLinksetDataRead(tableChar+llChar(_i+db4$ofs)); \
            if( _d ){ \
                list dataVar = llJson2List(_d); \
                code \
            } \
        } \
    }


// NOTE: USE THE MACROS ABOVE. NOT THESE.

// Creates a DB4 table. If it already exists, nothing happens. Returns the table charid.
// It is adviced to let the root script handle table creation to prevent race conditions
// Inline lets you use it either in root or as a standalone function
#define _4c_inline( n ) \
	list idx = llJson2List(llLinksetDataRead("$d4")); \
    integer pos = llListFindList(idx, (list)n); \
    if( ~pos || n == "" ){ \
        debugRare("Table already exists or is empty: "+n); \
        return llChar(pos+1); \
    } \
    integer free = llListFindList(idx, (list)""); \
    string id; \
    /* A table has been dropped, we can reuse its position */  \
    if( ~free ){  \
        idx = llListReplaceList(idx, (list)n, free, free); \
        id = llChar(free+db4$ofs); \
    } \
    /* No dropped table, we cannot replace */  \
    else{ \
        id = llChar(count(idx)+db4$ofs); \
        idx += n; \
    } \
    llLinksetDataWrite("$d4", mkarr(idx)); \
    llLinksetDataWrite(id, llList2Json(JSON_OBJECT, (list) \
        "i" + 0 + \
        "_" + n \
    )); \
    return id;
	

str _4c( string n ){
    _4c_inline(n)
}

// Drops a DB4 table
_4d( string n ){
    
    list idx = llJson2List(llLinksetDataRead("$d4"));
    integer pos = llListFindList(idx, (list)n);
    if( pos == -1 ){
        debugRare("Table does not exist "+n);
        return;
    }
    idx = llListReplaceList(idx, (list)"", pos, pos);
    llLinksetDataWrite("$d4", mkarr(idx));
	
    str ch = llChar(pos+db4$ofs);
    integer max = (int)j(llLinksetDataRead(ch), "i");
    llLinksetDataDelete(ch);
    integer i;
    for(; i < max; ++i )
        llLinksetDataDelete(ch+llChar(i+db4$ofs));
    
}

// Gets the first free ID of a table
// Can be used with replace if you want to reuse deleted rows
int _4f( string n, integer fast ){
    
    string ch = n;
    if( !fast )
        ch = db4$getTableChar(n);
    
    string meta = llLinksetDataRead(ch);
    integer max = (int)j(meta, "i");
    integer at;
    for(; at < max; ++at ){
        integer o = at+db4$ofs;
        if( !llStringLength(llLinksetDataRead(ch+llChar(o))) )
            return at+1;
    }
    return max;	// Max has the next field to be inserted
    
}
// insert. Returns the inserted id
int _4i( string n, list vals, integer fast ){
    
    string ch = n;
    if( !fast )
        ch = db4$getTableChar(n);
    string meta = llLinksetDataRead(ch);
    integer max = (int)j(meta, "i");
    integer nr = max;
    llLinksetDataWrite(ch, llJsonSetValue(meta, (list)"i", (str)(nr+1))); // Add to indexer
    // Write the data
    string chn = llChar(nr+db4$ofs);
    if( llLinksetDataWrite(ch+chn, mkarr(nr + vals)) )
        return 0;
    return nr;
    
}


// I strongly suggest defining constants for your tables
// It will make it easier to remember which index is which
// DB4 relies on arrays because they save memory

_4du( string table, list fields){
    
    string tab = "                ";
    string title = "ID"+"             ";
    integer i;
    for(; i < count(fields); ++i ){
        string t = llGetSubString(l2s(fields, i), 0, 14);
        title += t+llGetSubString(tab, 0, 15-llStringLength(t));
    }
    llOwnerSay(title);
    db4$each(table, row,
        string id = l2s(row, 0);
        title = "#"+id+llGetSubString(tab, 0, 15-llStringLength(id));
        for( i = 0; i < count(fields); ++i ){
            string data = llGetSubString(l2s(row, i+1), 0, 15);
            title += data + llGetSubString(tab, 0, 15-llStringLength(data));
        } 
        llOwnerSay(title);
    )
    
}


#endif
