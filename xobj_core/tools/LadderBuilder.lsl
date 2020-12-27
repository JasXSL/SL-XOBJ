/*

:: HOW TO USE ::
	
	:: START ::
1. Click the box.
2. Copypaste the key of the prim you want to climb (build tool > general > copy keys)

:: POSITIONS ::
1. Sit on the box and position yourself at the position you want to dismount the ladder after climbing DOWN it.
2. Press DisStart to save the dismount start position.
3. Press Rot to save your rotation relative to the ladder.
4. Position the box in the position the player should mount the ladder.
5. Click the Nodes button. Click <ADD> to set this as your bottom position.
6. Move yourself to the top of the ladder. Click <ADD> again to set this as the top position.
7. Go back to the main menu. Move yourself to the position the player should be brought to after dismounting (usually a bit forward and up on a ledge when making a ladder).
8. Press the DisEnd button to store this as the dismount top position.

:: ANIMATIONS ::
1. Click the Anims button.
2. Select the animation you want to change:
    - DisTop = Dismount at the top animation (optional)
    - DIsBottom = Dismount at the bottom animation (optional)
    - Idle = Idle animation while on the ladder
    - Fwd = Climbing UPWARDS animation
    - Back = Climbing DOWN animation.
3. Paste the name of the animation.

Built in animations into GoT:

    Shimmying across a rope horizontally:
        Idle : c_p
        Fwd & Back: c_a
    Shimmying across a ledge:
        Idle: s_p
        Fwd: s_l
        Back: s_a
    Climbing a ladder:
        Idle: l_p
        Fwd & Back: l_a
        Dismount: l_d

If making your own animation. The dismount animation takes place on the position you set DisEnd as.

:: SPEED ::
1. Click the Speed button to set speed. You can use this to adjust speed. Use 0 to let the HUD decide for you.

:: CHANGE LADDER OBJECT ::
1. Click the Ladder button, enter the new UUID




*/





#include "mattyhud/_core.lsl"

key ladder;             // Ladder object
rotation rot_offset;    // Rotation offset from the ladder
string anim_passive;
string anim_active;
string anim_active_down;
string anim_dismount_top;
string anim_dismount_bottom;
list nodes;
float speed;
vector dismount_location_start;
vector dismount_location_end;

integer menu;
#define MENU_START 0
#define MENU_SET_LADDER 1   // Set the ladder UUID

#define MENU_SET_ANIMS 2
#define MENU_LOAD 3

#define MENU_SET_ANIM_PASSIVE 20
#define MENU_SET_ANIM_ACTIVE 21
#define MENU_SET_ANIM_ACTIVE_DOWN 22
#define MENU_SET_ANIM_DISMOUNT_TOP 23
#define MENU_SET_ANIM_DISMOUNT_BOTTOM 24

#define MENU_SET_NODES 7
#define MENU_SPEED 8



buildMenu(){
    
    if( llKey2Name(ladder) == "" )
        menu = MENU_SET_LADDER;
    
    string out;
    list buttons;
    if( menu == MENU_START ){
        
        list n = nodes;
        integer i;
        for(; i<count(n); ++i ){
            n = llListReplaceList(n, (list)allRound(l2v(n, i), 2), i, i);
        }

        out += "Ladder: "+llKey2Name(ladder)+"\n";
        out += "Rot offset: "+allRound(rot_offset, 3)+"\n";
        out += "Idle anim: "+(str)anim_passive+"\n";
        out += "Fwd anim: "+(str)anim_active+"\n";
        out += "Back anim: "+(str)anim_active_down+"\n";
        out += "Dismount top anim: "+(str)anim_dismount_top+"\n";
        out += "Dismount bottom anim: "+(str)anim_dismount_bottom+"\n";
        out += "Speed: "+(str)allRound(speed, 3)+"\n";
        out += "Dismount start: "+(str)allRound(dismount_location_start,2)+"\n";
        out += "Dismount End: "+(str)allRound(dismount_location_end,2)+"\n";
        out += "Nodes: "+mkarr(n)+"\n";
        
        buttons += (list)
            "Ladder"+
            "Rot"+
            "Anims"+
            "Speed"+
            "DisStart"+
            "DisEnd"+
            "Nodes"+
            "SAVE"+
            "RESET"+
            "LOAD"
        ;
                
    }
    
    else if( menu == MENU_SET_LADDER ){
        out = "Paste the UUID of the PRIM you want to be the ladder here:";        
    }
    else if( menu == MENU_LOAD ){
        out = "Paste the description from an existing climbable to load it:";
    }
    
    else if( menu == MENU_SET_ANIMS ){
        
        out = "Pick animation type to set:";
        buttons = (list)
            "Idle"+
            "Fwd"+
            "Back"+
            "DisTop"+
            "DisBottom"+
            "<<"
        ;
        
    }
    // Set animation
    else if( menu >= 20 && menu < 30 ){
        out = "Enter a new animation:";
    }
    else if( menu == MENU_SPEED ){
        out = "Enter a speed multiplier value (0 for default):";
    }
    
    else if( menu == MENU_SET_NODES ){
        
        out = "Nodes go from left to right on shimmy, bottom to top when climbing. You usually only need 2 nodes for start and finish.\nADD will add a node at the box current position. I suggest you sit on it. Active nodes:\n";
        integer i;
        for(; i < count(nodes); ++i ){
            out += (str)i+". "+allRound(l2v(nodes, i), 2)+"\n";
        }

        
        buttons = (list)
            "RESET" +
            "<ADD>"+
            "Back"
        ;
        
    }
    
    if( buttons == [] ){
        
        llTextBox(llGetOwner(), out, 123);   
        return;
        
    }
    
    llDialog(llGetOwner(), out, buttons, 123);
    
}

stash(){
    
    list vectors = dismount_location_start+nodes+dismount_location_end;
    integer i;
    for( ; i<count(vectors); ++i ){
        vectors = llListReplaceList(vectors, (list)allRound(l2v(vectors, i), 2), i, i);   
    }
    
    list data = [
        allRound(rot_offset,3),
        anim_passive,
        anim_active,
        anim_active_down,
        anim_dismount_top,
        anim_dismount_bottom,
        implode(",",(list)vectors),
        allRound(speed, 3)
    ];
    
    for( i=0; i<count(data); ++i ){
        if( l2s(data, i) == "" )
            data = llListReplaceList(data, (list)" ", i, i);
        
    }
    llSetText("CL$"+implode("$", data), ZERO_VECTOR, 0);
    
}

rotation getLadderRot(){
    return prRot(ladder);    
}

vector getLadderPos(){
    return prPos(ladder);
}

vector getLadderPosRelational(){
    return (llGetPos()-getLadderPos())/getLadderRot();
}

rotation getLadderRotRelational(){
    return llGetRot()/getLadderRot();
}

loadFromString( string input ){
    
    list split = explode("$$", input);
    list_shift_each(split, val,
    
        list stash = explode("$", val);

        if( l2s(stash, 0) == "CL" ){
        
            stash = llDeleteSubList(stash, 0, 0);
            rot_offset = (rotation)l2s(stash, 0);
            anim_passive = l2s(stash, 1);
            anim_active = l2s(stash, 2);
            anim_active_down = l2s(stash, 3);
            anim_dismount_top = l2s(stash, 4);
            anim_dismount_bottom = l2s(stash, 5);
            speed = l2f(stash, 7);
                
            // Get the positions
            stash = llCSV2List(l2s(stash, 6));
            dismount_location_start = (vector)l2s(stash, 0);
            stash = llDeleteSubList(stash, 0, 0);
            dismount_location_end= (vector)l2s(stash, -1);
            stash = llDeleteSubList(stash, -1, -1);
            nodes = [];
            list_shift_each(stash, val,
                nodes += (vector)val;
            )
            
        }
    )
    
}

default{
    
    on_rez( integer awdaw ){ llResetScript(); }
    
    state_entry(){
        
        
        llListen(123, "", llGetOwner(), "");
        llSitTarget(<0,0,0.01>, ZERO_ROTATION);
        ladder = llGetObjectDesc();
        

        loadFromString(llList2String(
            llGetPrimitiveParams((list)PRIM_TEXT),
            0
        ));

        
    }
    
    listen( integer chan, string name, key id, string message ){
        
        if( menu == MENU_START){
            
            if( message == "Ladder" ){
                menu = MENU_SET_LADDER;
                buildMenu();
            }
            else if( message == "RESET" ){
                loadFromString("CL");
                stash();
                buildMenu();
            }
            else if( message == "LOAD" ){
                menu = MENU_LOAD;
                buildMenu();
            }
                
            else if( message == "Anims" ){
                menu = MENU_SET_ANIMS;
                buildMenu();
            }
            else if( message == "Speed" ){
                menu = MENU_SPEED;
                buildMenu();
            }
            else if( message == "DisStart" ){
                
                dismount_location_start = getLadderPosRelational();
                stash();
                buildMenu();
                
            }
            else if( message == "DisEnd" ){
                
                dismount_location_end = getLadderPosRelational();
                stash();
                buildMenu();
                
            }
            else if( message == "SAVE" ){
                
                llOwnerSay("D$Climb$$"+
                    llList2String(llGetPrimitiveParams((list)PRIM_TEXT), 0)
                );
                
            }
            else if( message == "Nodes" ){
                menu = MENU_SET_NODES;
                buildMenu();
            }
            
            else if( message == "Rot" ){

                rot_offset = getLadderRotRelational();                
                stash();
        
                buildMenu();
            }
            
        }
        else if( menu == MENU_SET_LADDER ){
            ladder = message;
            llSetObjectDesc(ladder);
            menu = MENU_START;
            buildMenu();   
        }
        else if( menu == MENU_SPEED ){
            speed = (float)message;
            stash();
            menu = MENU_START;
            buildMenu();
        }
        
        else if( menu == MENU_SET_ANIMS ){
            
            if( message == "<<" ){
                menu = MENU_START;
                buildMenu();
                return;
            }
            
            list opts = (list)
                "Idle"+
                "Fwd"+
                "Back"+
                "DisTop"+
                "DisBottom"
            ;
            integer pos = llListFindList(opts, (list)message);
            if( pos == -1 )
                return;
                
            menu = 20+pos;
            buildMenu();
            
        }
        // Set animation
        else if( menu >= 20 && menu < 30 ){
            
            if( menu == MENU_SET_ANIM_PASSIVE )
                anim_passive = message;
            else if( menu == MENU_SET_ANIM_ACTIVE )
                anim_active = message;
            else if( menu == MENU_SET_ANIM_ACTIVE_DOWN )
                anim_active_down = message;
            else if( menu == MENU_SET_ANIM_DISMOUNT_TOP )
                anim_dismount_top = message;
            else if( menu == MENU_SET_ANIM_DISMOUNT_BOTTOM )
                anim_dismount_bottom = message;
            
            stash();
            menu = MENU_SET_ANIMS;
            buildMenu();

        }
        else if( menu == MENU_SET_NODES ){
            
            if( message == "RESET" ){
                nodes = [];
                stash();
                buildMenu();
            }
            else if( message == "Back" ){
                menu = MENU_START;
                buildMenu();
            }
            else if( message == "<ADD>" ){
                nodes += getLadderPosRelational();
                stash();
                buildMenu();
            }

        }
        
        else if( menu == MENU_LOAD ){
            
            loadFromString(message);
            stash();
            menu = MENU_START;
            buildMenu();
            
        }
        

        
    }
    
    changed( integer change ){
        
        if( change & CHANGED_LINK ){
            key st = llAvatarOnSitTarget();
            if( st ){
                if( st != llGetOwner() )
                    llUnSit(st);
                else
                    llRequestPermissions(st, PERMISSION_TRIGGER_ANIMATION);
            }
        }    
    }
    run_time_permissions(integer perm ){
        if( perm & PERMISSION_TRIGGER_ANIMATION ){
            list anims = llGetAnimationList(llGetOwner());
            list_shift_each(anims, anim,
                llStopAnimation(anim);
            )
        }
    }

    touch_start(integer total_number){
        detOwnerCheck
        
        menu = MENU_START;
        buildMenu();
        
    }
}
