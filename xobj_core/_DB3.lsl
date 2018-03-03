/*


	DB3 is a bit slower than DB2 but also consumes much less memory
	Setting and getting uses the same syntax as DB2:
	db3$get((str)script, (list)index) - Returns data
	db3$set(((list)index, (var)data) - Returns "1" on success or "0" if the table was not set up
	
	You generally want to set up your schema in your #ROOT script and then initialize the other scripts after creation
	This can look like:
	// Create schema before resetting the other scripts
	list tables = [
		"#ROOT",
		"got Bridge"
	];
	db3$addTables(tables);
	
	Then in the link message callback:
	if(method$isCallback){
		if(SENDER_SCRIPT == "#ROOT" && METHOD == stdMethod$setShared){
			//qd("Tables created: "+PARAMS);
			resetAllOthers();
			// Initialize here
		}
        return;
    }
	
	You can create new tables ad-hoc by using the above method and callback in a sub script. But all in all it will be more efficient to set them up in root
	
	!! IMPORTANT NOTES !!
	- Set up tables BEFORE writing or DB3 will FAIL to write
	- DB3 stores max 3000 bytes per table
	- Table names longer than 70 bytes will be truncated to 70 bytes (This probably won't matter much as max length of a script in SL is 64)
	- Table names cannot contain the character |
	
	
*/

// Constants
#define db3$tableMaxlength 2111

// Accepts a list of tables to add to the database
#define db3$addTables(tables) llMessageLinked(LINK_ROOT, DB3_ADD, llList2Json(JSON_ARRAY, [llGetScriptName(), mkarr(tables)]), "")

// Macros
#define db3$get(script, index) llJsonGetValue(db3([script]),index)
#define db3$set(index, data) db3([llGetScriptName(), data]+index)
#define db3$setOther(script, index, data) db3([script, data]+index)
// Upper case variations
#define DB3$get(script, index) db3$get(script, index)
#define DB3$set(index, data) db3$set(index, data)
#define DB3$setOther(script, index, data) db3$setOther(script, index, data)

// GET is [(str)tableName] - Returns data
// SET is [(str)tableName, (str)data[, (var)indexLv1, (var)indexLv2]] - Returns "1" on success and "" on fail
// Index levels work as following: SET [llGetScriptName(), "Cat", "players", "jasdac"], essentially saves llJsonSetValue(dataForScript, ["players", "jasdac"], "Cat")
// Returns 0 if a save failed due to overflow
string db3(list input){
	string table = llList2String(input,0);
	integer i; string data; 
	// Scan the linkset
	links_each(nr, name,
		if(llGetSubString(name, 0, 1) == "DB"){
			integer nrFaces = llGetLinkNumberOfSides(nr);
			for(i=0; i<nrFaces; i++){
				// For backwards compatibility, GET will grab whitelist, but SET cannot
				// Editing existing levels will require a conversion by the local script
				data = implode("", llGetLinkMedia(nr, i, [PRIM_MEDIA_HOME_URL, PRIM_MEDIA_CURRENT_URL, PRIM_MEDIA_WHITELIST]));
				// See if this is the proper table
				integer pos = llSubStringIndex(data,"|");
				if(llGetSubString(data, 0, pos-1) == table){
					// Remove the prefix
					data = llDeleteSubString(data, 0, pos);
					// return data on GET
					if(count(input)==1)return data;
					
					
					// SET data
					data = table+"|"+llJsonSetValue(data, llDeleteSubList(input, 0, 1), llList2String(input, 1));
					if(llStringLength(data)>db3$tableMaxlength){
						debugRare("Data overflow on DB3 table: "+table);
						return "0";
					}
						
					// SET data. Whitelist can only be 63 characters long for security purposes
					llSetLinkMedia(nr, i, [
						PRIM_MEDIA_HOME_URL, 
						llGetSubString(data,0,1023), 
						PRIM_MEDIA_CURRENT_URL, 
						llGetSubString(data,1024,2047), 
						PRIM_MEDIA_WHITELIST, 
						llGetSubString(data, 2048, 2110), 
						PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_NONE, PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_NONE
					]);
					
					return "1";
				}
			}
		}
	)
	return "";		// Fail because table not found
}

#define clearDB3() links_each(ln, n, {if(llGetSubString(n,0,1) == "DB"){integer i;for(i=0; i<llGetLinkNumberOfSides(ln); i++){llClearLinkMedia(ln, i);}}})

