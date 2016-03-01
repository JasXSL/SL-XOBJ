/*
	The cubes work similar to DB2
	They need to have a small amount of path cut and hollow to become 9-sided.
	Name your database cubes JQL0, JQL1, JQL2 etc and link them up to the root prim which contains jas JQL
	
	
	Generic usage.
	- Create a table named test with 3kb of storage space (the kbytes get rounded up to nearest 3k cause that's how much you can store on a face):
		JQL$create_table(
			"test", 	// Table name (case sensitive)
			1,			// KB data to allocate a high number might cause stack heaps
			""			// Callback
		);
	
	- Define some columns:
	#define COL_ID -1
	#define COL_NAME 0
	#define COL_SPECIES 1
	#define COL_DOES 2
	Note that COL_ID is always -1 regardless of what you define it as, and the value of ID starts at 1 and auto increases every insert
	
	- Insert some data (the arrays should correspond to the columns)
	list set = [
        llList2Json(JSON_ARRAY, ["Khant", "Cat", "Pizza Eater"]),
        llList2Json(JSON_ARRAY, ["Jasdac", "Cat", "Scripter"]),
        llList2Json(JSON_ARRAY, ["Chaser", "Hyena", "Scripter"]),
        llList2Json(JSON_ARRAY, ["Jes", "Fox", "Tits"]),
        llList2Json(JSON_ARRAY, ["Toonie", "Panda", "Scripter"]),
        llList2Json(JSON_ARRAY, ["Sylus", "Dog", "Annoying"]) ,
        llList2Json(JSON_ARRAY, ["Kadah", "Cat", "Scripter"])
    ];
    JQL$insert(
		"test", 			// Table name
		mkarr(set), 		// Arrays to insert
		""					// Callback
	);
	
	- Update Jasdac and set species to Shibe:
	JQL$update(
        "test",                             // Table
        "["+(str)COL_SPECIES+"]",           // Keys
        "[\"Doge\"]",                       // Vals
        (str)COL_NAME+"=jasdac",            // WHERE
		""									// Callback
    );
	
	- Delete Sylus
	JQL$delete(
        "test", 							// Table
        (str)COL_NAME+"=Sylus",				// WHERE
		""									// Callback
    );
	
	
	- Prepare a callback reader for select
	#include "xobj_core/_LM.lsl"
    if(method$isCallback){
        if(SENDER_SCRIPT == "jas JQL" && METHOD == JQLMethod$select){
            list data = llJson2List(PARAMS);
            llOwnerSay("== QUERY RESULTS ==");
            list_shift_each(data, val,
                llOwnerSay(val);
            )
        }
        return;
    }
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
	
	
	- Select all data from the table and order by ID
	JQL$select(
        "test",     // Table
        "*",        // Cols
        "",		 	// WHERE
        COL_ID,     // Order by
		""			// Callback
    );
	
	
	- Select all scripters from the table, order by name
	JQL$select(
        "test",                     // Table
        "*",                        // Cols
        (str)COL_DOES+"=scripter", 	// WHERE
        COL_NAME,                   // Order by
		""							// Callback
    );
	
	
	- Delete table test:
		JQL$delete_table(
			"test",			// Table
			""				// Callback
		);

	
	== GOOD TO KNOW ==
	Table names are case sensitive
	WHERE calls are NOT case sensitive
	
	== Primer on WHERE ==
	All calls that have a WHERE var use the same syntax of col=var AND/OR col=var...
	OR is a separator meaning a statement like 
		COL_SPECIES=cat AND COL_DOES=scripter OR COL_DOES=tits evaluates to:
		(COL_SPECIES=cat AND COL_DOES=scripter) OR (COL_DOES=tits)
		
	Valid comparison operations are:
		= 
		!= 
		>
		>=
		<=
		<
		IN - (array)values | Ex: (str)COL_DOES+" IN [\"scripter\",\"tits\"]" <- Gets everyone who is either a scripter or tits
		HAS - (str)in | Ex: (str)COL_DOES+" HAS e" <- Gets everyone where their "does" field contains the letter E
	
	
*/



// Table modifying
#define JQLMethod$create_table 1		// (str)name, (int)kbytes - Creates a table, returns [TRUE] on success
#define JQLMethod$delete_table 2		// (str)name - Delete a table, returns [TRUE] on success

// Set data
#define JQLMethod$insert 100			// (str)table, (arr)valsArr - Inserts all sub-arrays of valsArr - Returns [(bool)success, (arr)insert_ids]
#define JQLMethod$update 101			// (str)table, (arr)keys, (arr)vals, (str)WHERE - Updates records - Returns [(int)affected_rows] on success
#define JQLMethod$delete 102			// (str)table, (str)WHERE - Deletes from a table - Returns [(int)num_deleted] on success

// Get data
#define JQLMethod$select 200			// (str)table, (arr)field_indexes or *, (str)WHERE, (int)orderBy - Returns an array of all the rows


#define JQL$create_table(name, kbytes, cb) runMethod((str)LINK_THIS, "jas JQL", JQLMethod$create_table, [name, kbytes], cb)
#define JQL$delete_table(name, cb) runMethod((str)LINK_THIS, "jas JQL", JQLMethod$delete_table, [name], cb)
#define JQL$insert(table, valsArr, cb) runMethod((str)LINK_THIS, "jas JQL", JQLMethod$insert, [table, valsArr], cb)
#define JQL$update(table, keys, vals, where, cb) runMethod((str)LINK_THIS, "jas JQL", JQLMethod$update, [table, keys, vals, where], cb)
#define JQL$select(table, vals, where, orderBy, cb) runMethod((str)LINK_THIS, "jas JQL", JQLMethod$select, [table, vals, where, orderBy], cb)
#define JQL$delete(table, where, cb) runMethod((str)LINK_THIS, "jas JQL", JQLMethod$delete, [table, where], cb)




