/*
	REMOTE_TABLE : Stores scripts with a portal and what scripts you can use the portal to defer loading to
		Table keys follow this convention: TABLE + "." + (str)remoterUUID
		Table value is a JSON array: [
			(int)(llGetTime()*10),		- Last time this remoteloaded something
			(arr)scripts
		]
	
	QUEUE_TABLE : Sequential load queue. Purged when all scripts have been loaded.
		[
			(key)target, (str)name, (int)pin, (int)startparam
		]

*/
#define USE_DB4
#include "xobj_core/_ROOT.lsl"

#ifndef REMOTE_TABLE
	#error "Remoteloader requires DB4 now. Please #define REMOTE_TABLE with the table that you want to use for portal remoting."
#endif
#ifndef QUEUE_TABLE
	#error "Remoteloader requires DB4 now. Please #define QUEUE_TABLE with the table that you want to use for queue storage."
#endif




list slaves;			// [(float)time] Cooldowns of each slave

integer BFL;
#define BFL_DONE 0x1


list queue;				// [(key)id, (str)script, (int)pin, (int)startparam]
#define QSTRIDE 4

// Assets with a portal in it can be used to alleviate remote loading
key getAvailablePortal( string script, key id ){
	
	str regex = "^"+REMOTE_TABLE+"\\."; // Starts with TABLE followed by script and a dot
	list keys = llLinksetDataFindKeys(regex, 0, 0);
	float gtime = llGetTime();
	integer i;
	for(; i < count(keys); ++i ){
		
		string k = l2s(keys, i);
		string data = llLinksetDataRead(k);
		float time = (float)j(data, 0)*0.1; 	// Time is stored as an int of 10th of a second
		key targ = llGetSubString(k, llSubStringIndex(k, ".")+1, -1);
		
		if( llKey2Name(targ) == "" ){
		
			debugCommon("[Remoter] Prune: "+k);
			llLinksetDataDelete(k);
			
		}
		// Can be used every 4 seconds.
		else if( gtime-time > 4 && targ != id ){
			
			list scripts = llJson2List(j(data, 1));
			if( ~llListFindList(scripts, (list)script) ){ // Has this script

				// Mark as used
				data = llJsonSetValue(data, (list)0, (str)floor(llGetTime()*10));
				llLinksetDataWrite(k, data);
				return targ;
				
			}
			
		}
	}
	return "";
	
}

int getAvailableSlave(){
	
	float gtime = llGetTime();
	integer i;
	for(; i < count(slaves); ++i ){
		
		if( gtime-l2f(slaves, i) > 3.1 )
			return i;
		
	}
	return -1;
	
}

// returns an index in QUEUE_TABLE or -1 if we are done
int getNextScriptIndex(){

	db4$each(QUEUE_TABLE, idx, item, 
		return idx;
	)
	return -1;
	
}

// Checks if a remoteload already exists in queue so you do not have to be worried about causing recursions
// Returns the index if it exists, or -1
int getQueueIndex( key targ, string script ){
	
	db4$each(QUEUE_TABLE, idx, item,
		
		if( j(item, 0) == targ && j(item, 1) == script )
			return idx;
		
	)
	return -1;
	
}


// Returns -1 on complete, 0 on all spawners busy, 1 on success
int load(){

	int next = getNextScriptIndex();
	// Queue done. Reset.
	if( next == -1 ){
		
		if( ~BFL & BFL_DONE ){
			
			db4$drop(QUEUE_TABLE);
			debugUncommon("[Queue] Done!");
			#ifdef onLoadFinish
			onLoadFinish;
			#endif
			BFL = BFL|BFL_DONE;
			
		}
		return -1;
		
	}
	
	BFL = BFL &~ BFL_DONE;
	
	list task = llJson2List(db4$get(QUEUE_TABLE, next));
	key targ = l2k(task, 0);
	string script = l2s(task, 1);
	int pin = l2i(task, 2);
	int startParam = l2i(task, 3);
	int noRemote = l2i(task, 4);
	
	// First try to find a portal to defer to
	if( !noRemote ){
		
		key targPortal = getAvailablePortal( script, targ );
		if( targPortal ){
			
			Portal$remoteLoad( 
				targPortal, 
				targ, 
				script, 
				pin, 
				startParam 
			);
			db4$delete(QUEUE_TABLE, next); // We always delete on attempt. If it fails, the target will send a new request.
			debugUncommon("[Remoter] Remoting "+script+" from "+llKey2Name(targPortal)+" to "+llKey2Name(targ));
			return TRUE;
			
		}
		
	}
	
	int slave = getAvailableSlave();
	if( ~slave ){
	
		slaves = llListReplaceList(slaves, (list)llGetTime(), slave, slave);
		llMessageLinked(LINK_THIS, slave, mkarr((list)targ + script + pin + startParam), "rm_slave");
		db4$delete(QUEUE_TABLE, next); // We always delete on attempt. If it fails, the target will send a new request.
		debugUncommon("[Internal] Load "+script+" via slave "+(str)slave+" to "+llKey2Name(targ));
		return TRUE;
		
	}


	debugUncommon("[Queue] Out of loaders... delaying "+(str)llGetTime()+" "+mkarr(slaves));
	return FALSE;
	
}

next(){
	
	// Need to allow events to raise. So we set a timer.
	float t = 0.01;
	integer l = load();
	if( l == -1 )
		return;
		
	if( !l )
		t = 1.0; // All spawners occupied.
		
	multiTimer(["A", 0, t, FALSE]);

}

timerEvent(string id, string data){

	if( id == "A" )
		next();
	
}


default
{
    on_rez(integer start){
        llResetScript();
    }
    
	
	state_entry(){
	
		// qd("state_entry");
		slaves=[];
		integer i;
		for( ; i <= llGetInventoryNumber(INVENTORY_SCRIPT); ++i ){
			
			str name = llGetInventoryName(INVENTORY_SCRIPT, i);
			if( llGetSubString(name, 0, 4) == "slave" )
				slaves += -3.0;
			
		}
		debugUncommon("Found "+(str)count(slaves)+" slaves.");
		
		db4$drop(REMOTE_TABLE);
		db4$drop(QUEUE_TABLE);
		
		llListen(RemoteloaderConst$iniChan, "", "", "");
		
		#ifdef stateEntry
		stateEntry;
		#endif
		
	}
	
	// Receive init messages from portal
	listen( integer ch, string n, key id, string msg ){
		idOwnerCheck
		
		// Portal always added
		list scripts = "got Portal" + llJson2List(msg);
		str label = REMOTE_TABLE + "." + (str)id;
		llLinksetDataWrite(
			label, 
			mkarr((list)
				-50 + // Can start loading instantly
				mkarr(scripts)
			)
		);
		debugCommon("[Remoter]  Adding "+llKey2Name(id)+" : "+mkarr(scripts));

	
	}
	
    timer(){multiTimer([]);}

    #include "xobj_core/_LM.lsl"
        if( !method$byOwner )
			return;
			
        if( nr == METHOD_CALLBACK ) 
            return;
        
        if( METHOD == RemoteloaderMethod$load ){
		
			list dta = PARAMS;
			if( id == "" )
				id = llList2String(dta, -1);		// Lets you override the ID to send to. Only used internally.
			
			string s = llList2String(dta, 0);
			
			list scripts = (list)s;
			if( llJsonValueType(s, []) == JSON_ARRAY )		// Load multiple
				scripts = llJson2List(s);
			
			integer i;
			for(; i < count(scripts); ++i ){
			
				string script = l2s(scripts, i);
				if( llGetInventoryType(script) != INVENTORY_SCRIPT )
					llOwnerSay("Trying to remoteload non-existing script "+script);
				else{
				
					// This exists already as a remoteloader. We should remove it or it may cause desync
					str rl = REMOTE_TABLE+"."+(str)id;
					if( llLinksetDataRead(rl) )
						llLinksetDataDelete(rl);
				
					int exists = getQueueIndex(id, script);
					string out = mkarr((list)
						id +
						script + 		// Script
						l2i(dta, 1) +		// Pin
						l2i(dta, 2)	+		// Start param
						l2i(dta, 3)			// No remoter
					);
					if( ~exists )
						db4$replace(QUEUE_TABLE, exists, out);
					else
						db4$insert(QUEUE_TABLE, out);
					debugCommon("[Queue] Add " + llKey2Name(id)+" >> "+script);
					
				}
			
			}
			
			next();
			
        }

    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}
 


