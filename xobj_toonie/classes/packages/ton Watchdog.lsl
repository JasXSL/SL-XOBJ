/* 
	Resets scripts in this that don't respond to ping commands
	Requires #define USE_WATCHDOG in _core.lsl
	You can use #define onDeadScripts( list scripts ) if you want to do something custom, otherwise it resets everything when encountered
*/
#include "xobj_core/_ROOT.lsl"

list scripts = [];
int pong;	// when false we are waiting for responses, when true we catch a reset

default{
	
	state_entry(){ 
	
		memLim(1.5);
		llSetTimerEvent(10); 
		
	}
	timer(){
		
		if( !pong ){
		
			scripts = [];
			integer i;
			for(; i<llGetInventoryNumber(INVENTORY_SCRIPT); ++i ){
			
				str script = llGetInventoryName(INVENTORY_SCRIPT, i);
				if( script != cls$name )
					scripts += script;
				
			}
			
			llMessageLinked(LINK_THIS, WATCHDOG_PING, "", "");
		
		}
		else{
			
			if( count(scripts) ){
				#ifdef onDeadScripts
				onDeadScripts(scripts);
				#else
				
				integer i;
				for(; i<count(scripts); ++i )
					llResetOtherScript(l2s(scripts, i));
				
				llSleep(1);
				resetAllOthers();				
				
				#endif
			}
		}
		
		pong = !pong;
		
	}
	
	link_message( integer link, integer nr, string s, key id ){
		
		if( link == llGetLinkNumber() && nr == WATCHDOG_PONG ){
			
			integer pos = llListFindList(scripts, (list)s);
			if( ~pos )
				scripts = llDeleteSubList(scripts, pos, pos);
			
			
		}
	
	}
	

}

