#ifndef __DB3
#define __DB3
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
	
	Settings:
	db3$use_cache - Enables caching. Call db3_cache() in state entry to build the cache
	
*/

// Constants
#define db3$tableMaxlength 2000

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


// Collpases prim media to a string and appends it to &var
#define db3$getPrimFaceData( prim, face, var ) \
	string add = llGetSubString(llList2String(llGetLinkMedia(prim, face, [PRIM_MEDIA_HOME_URL]), 0), 8, -1); \
	if(add == "https://")add = ""; \
	data += add; \
	add = llGetSubString(llList2String(llGetLinkMedia(prim, face, [PRIM_MEDIA_CURRENT_URL]), 0), 8, -1); \
	if(add == "https://")add = ""; \
	data += add; \
	data += llList2String(llGetLinkMedia(prim, face, [PRIM_MEDIA_WHITELIST]), 0)
	

#ifdef db3$use_cache 
list db3CACHE;	// (str)table, (int)prim, (int)face
db3_cache(){

	db3CACHE = [];
	links_each(nr, name,
		if( llGetSubString(name, 0, 1) == "DB" ){
		
			integer i;
			for(; i<llGetLinkNumberOfSides(nr); ++i ){
				
				string data;
				db3$getPrimFaceData(nr, i, data);
				integer pos = llSubStringIndex(data,"|");
				if( ~pos )
					db3CACHE += (list)llGetSubString(data, 0, pos-1) + nr + i;
				
			}
			
		}
	)
	
}
#endif


	


// GET is [(str)tableName] - Returns data
// SET is [(str)tableName, (str)data[, (var)indexLv1, (var)indexLv2]] - Returns "1" on success and "" on fail
// Index levels work as following: SET [llGetScriptName(), "Cat", "players", "jasdac"], essentially saves llJsonSetValue(dataForScript, ["players", "jasdac"], "Cat")
// Returns 0 if a save failed due to overflow
string db3(list input){
	string table = llList2String(input,0);
	
	// Use cache
	#ifdef db3$use_cache
	integer p = llListFindList(db3CACHE, (list)table);
	if( p == -1 )
		return "";
	integer nr = l2i(db3CACHE, p+1);
	integer i = l2i(db3CACHE, p+2);
	string data;
	db3$getPrimFaceData(nr, i, data);
	integer pos = llSubStringIndex(data,"|");
	
	// Do not use cache, scan linkset
	#else
	integer nr;
	for( nr=1; nr<=llGetNumberOfPrims(); ++nr ){
		
		str name = llGetLinkName(nr);
		if( llGetSubString(name, 0, 1) == "DB" ){
			
			integer nrFaces = llGetLinkNumberOfSides(nr);
			integer i;
			for( ; i<nrFaces; ++i ){
			
				// For backwards compatibility, GET will grab whitelist, but SET cannot
				// Editing existing levels will require a conversion by the local script
				string data;
				db3$getPrimFaceData(nr, i, data);

				// See if this is the proper table
				integer pos = llSubStringIndex(data,"|");
				if(llGetSubString(data, 0, pos-1) == table){
	#endif
					// Remove the prefix
					data = llDeleteSubString(data, 0, pos);
					// return data on GET
					if(count(input)==1)
						return data;

					// SET data
					data = table+"|"+llJsonSetValue(data, llDeleteSubList(input, 0, 1), llList2String(input, 1));
					if( llStringLength(data) > db3$tableMaxlength ){
						debugRare("Data overflow on DB3 table: "+table);
						return "0";
					}
						
					// SET data. Whitelist can only be 63 characters long for security purposes
					llSetLinkMedia(nr, i, [
						PRIM_MEDIA_HOME_URL, 
						"https://"+llGetSubString(data,0,1015), 
						PRIM_MEDIA_CURRENT_URL, 
						"https://"+llGetSubString(data,1016,2032), 
						PRIM_MEDIA_WHITELIST, 
						llGetSubString(data, 2033, 2095), 
						PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_NONE, PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_NONE
					]);

					return "1";
	// Use cache, fetch from table
	#ifdef db3$use_cache
	
	// Do not use cache, cycle
	#else
				}
				
			}
			
		}
	}
	return "";		// Fail because table not found
	#endif
	
	
}

#define clearDB3() links_each(ln, n, {if(llGetSubString(n,0,1) == "DB"){integer i;for(i=0; i<llGetLinkNumberOfSides(ln); i++){llClearLinkMedia(ln, i);}}})


#endif
