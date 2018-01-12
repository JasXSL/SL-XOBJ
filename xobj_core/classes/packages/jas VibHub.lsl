/*
	
	This is an example on how to use VibHub
	Don't use this package file directly, this is only here to show you how to use the macros!
	
*/

#include "xobj_core/_ROOT.lsl"
#include "xobj_core/classes/jas VibHub.lsl"

// Macros for building the program
integer CD;


default
{
    touch_start(integer total_number){
        
        // Limit to every 1.5 sec push
        if( CD )
            return;
        CD = TRUE;
        llSetTimerEvent(1.5);
        llTriggerSound("41013111-a713-ddd5-ede1-a22998aab0d1", 1);
        
        
        // PROGRAM IS CREATED HERE
        
        // Create a new program
        string program = jasVibHub$newProgram( 0 ); // Create a new program that should run once
        
        
        // ADD SOME STAGES
        
        // An empty stage will reset the intensity to 0. This will force the program to start from 0 intensity
        jasVibHub$program$addStage( program, jasVibHub$newStage() );
        
        // Create a new stage
        string stage = jasVibHub$newStage();
        jasVibHub$stage$setIntensity(stage, 75);      // This stage will tween the intensity to 75%
        jasVibHub$stage$setDuration(stage, 0.1);      // It should take 0.1 second to reach 75% intensity
        jasVibHub$stage$setYoyo(stage, TRUE);          // this will cause the stage to ease back and forth
        jasVibHub$stage$setRepeats(stage, 11);         // 11 repeats means it goes up and down 6 times.
                                                    // This is because a repeat of 1 means to play it twice
                                                    // And each up or down counts as a single tween.
                                                    // Because of this, it takes 0.2 seconds to go back and forth once
        jasVibHub$stage$setEasing(stage, "Sinusoidal.InOut");  // Generates a smoother pulse
        
        // Add the stage to the program
        jasVibHub$program$addStage( program, stage );
        
        
        // Add another stage
        stage = jasVibHub$newStage();
        // This stage will be slower and repeat 3 times
        jasVibHub$stage$setIntensity(stage, 75);
        jasVibHub$stage$setDuration(stage, 0.25);
        jasVibHub$stage$setYoyo(stage, TRUE);
        jasVibHub$stage$setRepeats(stage, 5);
        jasVibHub$stage$setEasing(stage, "Sinusoidal.InOut");
        
        jasVibHub$program$addStage(program, stage);
        
        // Add a final stage which will be a single slow and powerful pulse
        stage = jasVibHub$newStage();
        jasVibHub$stage$setIntensity(stage, 100);
        jasVibHub$stage$setDuration(stage, 1);
        jasVibHub$stage$setYoyo(stage, TRUE);
        jasVibHub$stage$setRepeats(stage, 1);
        jasVibHub$stage$setEasing(stage, "Sinusoidal.InOut");
        jasVibHub$program$addStage(program, stage);

        // Exec the program on a device with id "JasBulletIsMuchAmaze"
        jasVibHub$program$execute( "JasBulletIsMuchAmaze", program );

    }
    
    // Cooldown
    timer(){
        CD = FALSE;
        llSetTimerEvent(0);
    }
}

