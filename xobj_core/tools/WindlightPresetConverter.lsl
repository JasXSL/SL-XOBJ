/*
	
	Since EEP removed a bunch of presets, this can be used to convert preset names to UUIDs
	Just drop it in and it tries to automatically update presets

*/

#include "xobj_core/_ROOT.lsl"
key fetch;
fetchWindlights( list windlights ){
    
    fetch = llHTTPRequest(
        "https://jasx.org/api/windlight/?SKY="+llEscapeURL(llList2CSV(windlights)), 
        [], 
        ""
    );
    
}
// Windlights is a JSON object of skies
onWindlightsFetched( string windlights ){
    
    llOwnerSay("Fetched windlights: \n" + windlights);
    integer updates;
    integer i;
    for(; i < count(toSet); i += 2 ){
        
        key uuid = j(windlights, l2s(toSet, i));
        if( uuid ){
            
            list prims = explode(",", l2s(toSet, i+1));
            integer pid;
            for(; pid < count(prims); ++pid ){
                
                integer prim = l2i(prims, pid);
                list desc = explode(
                    "$$", 
                    l2s(
                        llGetLinkPrimitiveParams(prim, (list)PRIM_DESC),
                        0
                    )
                );
                
                integer d;
                for( ; d < count(desc); ++d ){
                    
                    list spl = explode("$", l2s(desc, d));
                    if( l2s(spl, 0) == "WL" ){
                        
                        spl = llListReplaceList(spl, (list)uuid, 1, 1);
                        desc = llListReplaceList(desc, (list)implode("$", spl), d, d);
                        
                    }    
                    
                }
                
                string out = implode("$$", desc);
                if( llStringLength(out) > 127 )
                    llOwnerSay("ERROR: Prim desc too long: '"+out+"'");
                else{
                    llOwnerSay("Setting WL on "+llGetLinkName(prim));
                    ++updates;
                    llSetLinkPrimitiveParamsFast(prim, (list)PRIM_DESC + out);
                }
            }
            
            
        }
        else
            llOwnerSay("MISSING WINDLIGHT: "+l2s(toSet, i));
        
        
    }
    
    llOwnerSay("Windlights updated: "+(str)updates);
    llRemoveInventory(llGetScriptName());
    
}

list toSet; // (str)windlight, (list)prims


default{
    
    state_entry(){
        
        llOwnerSay("Scanning");
        integer N;
        // fetchWindlights((list)"[TOR] Night - Anwar" + "Nacon's Natural Sunset: C");
        links_each( nr, name,
            
            string desc = l2s(llGetLinkPrimitiveParams(nr, (list)PRIM_DESC), 0);
            if( ~llSubStringIndex(desc, "WL$") ){
                
                list spl = explode("$$", desc);
                integer i;
                for(; i < count(spl); ++i ){
                    
                    list sub = explode("$", l2s(spl, i));
                    if( l2s(sub, 0) == "WL" ){
                        
                        string wl = llToLower(l2s(sub, 1));
                        integer pos = llListFindList(toSet, (list)wl);
                        if( ~pos )
                            toSet = llListReplaceList(toSet, [
                                implode(",", explode(",", l2s(toSet, pos+1)) + nr )
                            ], pos+1, pos+1);
                        else{
							llOwnerSay("Windlight found: "+wl);
                            toSet += (list)wl + nr;
                        }
                        i = count(spl);
                    }
                    
                }
                
            }
            ++N;
        
        )
        llOwnerSay("Done scanning "+(str)N+" prims!");
        fetchWindlights(llList2ListStrided(toSet, 0, -1, 2));
        
    }

    http_response( key id, integer status, list meta, string body ){
        
        if( id != fetch )
            return;
            
        if( status != 200 ){
            
            llOwnerSay("Invalid server response: "+(string)status);
            return;
            
        }
        
        if( !isset(j(body, "SKY")) ){
            
            llOwnerSay("No viable sky found");
            return;
            
        }
           
        onWindlightsFetched(j(body, "SKY"));
        
    }
    
}
