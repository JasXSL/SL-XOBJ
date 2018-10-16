#include "../jas PrimswimAux.lsl"
#include "../jas PrimswimParticles.lsl"

int P_RINGS;
float alpha = 0;
float z_offset = 0;

waterEnterSplash( integer intensity ){
    
    llLinkParticleSystem(LINK_SET, []);
	
	float multi = intensity/3.0+0.3;
	
	float diameter = intensity*1.5+1;
	// <0.01000, 2.00000, 2.00000>
	alpha = (intensity+1)/6.0;
	llSetLinkPrimitiveParamsFast(P_RINGS, [PRIM_COLOR, ALL_SIDES, <1,1,1>, alpha, PRIM_SIZE, <0.01, diameter, diameter>]);
	ptSet("alpha", alpha, FALSE);
	
	if( intensity == 0 ){
	
		llLinkParticleSystem(3, [
			PSYS_PART_MAX_AGE,.75, // max age
			PSYS_PART_FLAGS, 
				//PSYS_PART_EMISSIVE_MASK|
				//PSYS_PART_WIND_MASK|
				PSYS_PART_BOUNCE_MASK|
				PSYS_PART_INTERP_COLOR_MASK|
				PSYS_PART_INTERP_SCALE_MASK//|
				//PSYS_PART_FOLLOW_VELOCITY_MASK
				, // flags, glow etc
			PSYS_PART_START_COLOR, <.8, .9, 1>, // startcolor
			PSYS_PART_END_COLOR, <1, 1, 1>, // endcolor
			PSYS_PART_START_SCALE, <.0, .0, 0>, // startsize
			PSYS_PART_END_SCALE, <.5, .5, 0>, // endsize
			PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE, // pattern
			PSYS_SRC_BURST_RATE, 0.01, // rate
			PSYS_SRC_ACCEL, <0,0,-0.5>,  // push
			PSYS_SRC_BURST_PART_COUNT, 1, // count
			PSYS_SRC_BURST_RADIUS, 0.25, // radius
			PSYS_SRC_BURST_SPEED_MIN, 0, // minSpeed
			PSYS_SRC_BURST_SPEED_MAX, .5, // maxSpeed
			// PSYS_SRC_TARGET_KEY, NULL_KEY, // target
			PSYS_SRC_OMEGA, <0., 0., 0.>, // omega
			PSYS_SRC_MAX_AGE, .4, // life
			PSYS_SRC_TEXTURE, "dcab6cc4-172f-e30d-b1d0-f558446f20d4", // texture
			
			PSYS_PART_START_ALPHA, .25, // startAlpha
			PSYS_PART_END_ALPHA, 0.0, // endAlpha
			PSYS_PART_START_GLOW, 0.0,
			PSYS_PART_END_GLOW, 0,
			
			PSYS_SRC_ANGLE_BEGIN, PI_BY_TWO, // angleBegin
			PSYS_SRC_ANGLE_END, PI_BY_TWO // angleend
		]);
		
		return;
		
	}

    llParticleSystem([
        PSYS_PART_MAX_AGE,1.2, // max age
        PSYS_PART_FLAGS, 
            //PSYS_PART_EMISSIVE_MASK|
            PSYS_PART_WIND_MASK|
            PSYS_PART_INTERP_COLOR_MASK|
            PSYS_PART_INTERP_SCALE_MASK|
            //PSYS_PART_RIBBON_MASK|
            PSYS_PART_FOLLOW_VELOCITY_MASK
            , // flags, glow etc
        PSYS_PART_START_COLOR, <.6, .8, 1>, // startcolor
        PSYS_PART_END_COLOR, <1, 1, 1>, // endcolor
        PSYS_PART_START_SCALE, <.5, .5, 0>*multi, // startsize
        PSYS_PART_END_SCALE, <2, 2, 0>*multi, // endsize
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE, // pattern
        PSYS_SRC_BURST_RATE, 0.01, // rate
        PSYS_SRC_ACCEL, <0,0,-12>*multi,  // push
        PSYS_SRC_BURST_PART_COUNT, 10, // count
        PSYS_SRC_BURST_RADIUS, 0., // radius
        PSYS_SRC_BURST_SPEED_MIN, 3.3*multi, // minSpeed
        PSYS_SRC_BURST_SPEED_MAX, 8.*multi, // maxSpeed
        // PSYS_SRC_TARGET_KEY, NULL_KEY, // target
        PSYS_SRC_OMEGA, <0., 0., 0.>, // omega
        PSYS_SRC_MAX_AGE, .4, // life
        PSYS_SRC_TEXTURE, "883c11fb-1468-fa1e-231a-f1c531027f18", // texture
        
        PSYS_PART_START_ALPHA, .25, // startAlpha
        PSYS_PART_END_ALPHA, 0.0, // endAlpha
        PSYS_PART_START_GLOW, 0.0,
        PSYS_PART_END_GLOW, 0,
        
        PSYS_SRC_ANGLE_BEGIN, 0.2, // angleBegin
        PSYS_SRC_ANGLE_END, 0.2 // angleend
    ]);

	if( intensity > 1 ){	// Mist
		llLinkParticleSystem(3, [
			PSYS_PART_MAX_AGE,3, // max age
			PSYS_PART_FLAGS, 
				//PSYS_PART_EMISSIVE_MASK|
				//PSYS_PART_WIND_MASK|
				PSYS_PART_BOUNCE_MASK|
				PSYS_PART_INTERP_COLOR_MASK|
				PSYS_PART_INTERP_SCALE_MASK//|
				//PSYS_PART_FOLLOW_VELOCITY_MASK
				, // flags, glow etc
			PSYS_PART_START_COLOR, <1, 1, 1>, // startcolor
			PSYS_PART_END_COLOR, <1, 1, 1>, // endcolor
			PSYS_PART_START_SCALE, <.0, .0, 0>, // startsize
			PSYS_PART_END_SCALE, <3., 3., 0>, // endsize
			PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE, // pattern
			PSYS_SRC_BURST_RATE, 0.05, // rate
			PSYS_SRC_ACCEL, <0.1,0,0>,  // push
			PSYS_SRC_BURST_PART_COUNT, 1, // count
			PSYS_SRC_BURST_SPEED_MIN, 0, // minSpeed
			PSYS_SRC_BURST_RADIUS, 0.75*multi, // radius
			PSYS_SRC_BURST_SPEED_MAX, .1, // maxSpeed
			// PSYS_SRC_TARGET_KEY, NULL_KEY, // target
			PSYS_SRC_OMEGA, <0., 0., 0.>, // omega
			PSYS_SRC_MAX_AGE, .4, // life
			PSYS_SRC_TEXTURE, "dcab6cc4-172f-e30d-b1d0-f558446f20d4", // texture
			
			PSYS_PART_START_ALPHA, .25, // startAlpha
			PSYS_PART_END_ALPHA, 0.0, // endAlpha
			PSYS_PART_START_GLOW, 0.0,
			PSYS_PART_END_GLOW, 0,
			
			PSYS_SRC_ANGLE_BEGIN, PI, // angleBegin
			PSYS_SRC_ANGLE_END, PI // angleend
		]);
	}

    // Droplets
    llLinkParticleSystem(5, [
        PSYS_PART_MAX_AGE,.75, // max age
        PSYS_PART_FLAGS, 
            //PSYS_PART_EMISSIVE_MASK|
            //PSYS_PART_WIND_MASK|
            //PSYS_PART_RIBBON_MASK|
            PSYS_PART_INTERP_COLOR_MASK|
            PSYS_PART_INTERP_SCALE_MASK|
            //PSYS_PART_RIBBON_MASK|
            PSYS_PART_FOLLOW_VELOCITY_MASK
            , // flags, glow etc
        PSYS_PART_START_COLOR, <.5, .75, 1>, // startcolor
        PSYS_PART_END_COLOR, <1, 1, 1>, // endcolor
        PSYS_PART_START_SCALE, <.1, .1, 0>*multi, // startsize
        PSYS_PART_END_SCALE, <0.05, .075, 0>*multi, // endsize
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE, // pattern
        PSYS_SRC_BURST_RATE, 0.01, // rate
        PSYS_SRC_ACCEL, <0,0,-15>*multi,  // push
        PSYS_SRC_BURST_PART_COUNT, 1, // count
        PSYS_SRC_BURST_RADIUS, 0.1, // radius
        PSYS_SRC_BURST_SPEED_MIN, 6*multi, // minSpeed
        PSYS_SRC_BURST_SPEED_MAX, 10*multi, // maxSpeed
        // PSYS_SRC_TARGET_KEY, NULL_KEY, // target
        PSYS_SRC_OMEGA, <0., 0., 0.>, // omega
        PSYS_SRC_MAX_AGE, .4, // life
        PSYS_SRC_TEXTURE, "dcab6cc4-172f-e30d-b1d0-f558446f20d4", // texture
        
        PSYS_PART_START_ALPHA, 1*multi, // startAlpha
        PSYS_PART_END_ALPHA, 1*multi, // endAlpha
        PSYS_PART_START_GLOW, 0.0,
        PSYS_PART_END_GLOW, 0,
        
        PSYS_SRC_ANGLE_BEGIN, .5, // angleBegin
        PSYS_SRC_ANGLE_END,.5 // angleend
    ]);

    // Edges
    llLinkParticleSystem(4, [
        PSYS_PART_MAX_AGE,0.8, // max age
        PSYS_PART_FLAGS, 
            //PSYS_PART_EMISSIVE_MASK|
            PSYS_PART_WIND_MASK|
            PSYS_PART_INTERP_COLOR_MASK|
			PSYS_PART_BOUNCE_MASK|
            PSYS_PART_INTERP_SCALE_MASK//|
            //PSYS_PART_RIBBON_MASK|
            //PSYS_PART_FOLLOW_VELOCITY_MASK
            , // flags, glow etc
        PSYS_PART_START_COLOR, <.8, .9, 1>, // startcolor
        PSYS_PART_END_COLOR, <1, 1, 1>, // endcolor
        PSYS_PART_START_SCALE, <.1, .1, 0>*multi, // startsize
        PSYS_PART_END_SCALE, <1.5, 1.5, 0>*multi, // endsize
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE, // pattern
        PSYS_SRC_BURST_RATE, 0.01, // rate
        PSYS_SRC_ACCEL, <0,0,-8>,  // push
        PSYS_SRC_BURST_PART_COUNT, 3, // count
        PSYS_SRC_BURST_RADIUS, 0., // radius
        PSYS_SRC_BURST_SPEED_MIN, 3.3*multi, // minSpeed
        PSYS_SRC_BURST_SPEED_MAX, 5.*multi, // maxSpeed
        // PSYS_SRC_TARGET_KEY, NULL_KEY, // target
        PSYS_SRC_OMEGA, <0., 0., 0.>, // omega
        PSYS_SRC_MAX_AGE, .4, // life
        PSYS_SRC_TEXTURE, "b1b5356d-9c40-e3a7-70ec-c32066f531f6", // texture
        
        PSYS_PART_START_ALPHA, .25, // startAlpha
        PSYS_PART_END_ALPHA, 0.0, // endAlpha
        PSYS_PART_START_GLOW, 0.0,
        PSYS_PART_END_GLOW, 0,
        
        PSYS_SRC_ANGLE_BEGIN, 0.2, // angleBegin
        PSYS_SRC_ANGLE_END, 0.2 // angleend
    ]);
    
    
}

emerge(){
	float diameter = 2;
	alpha = 0.5;
	llSetLinkPrimitiveParamsFast(P_RINGS, [PRIM_COLOR, ALL_SIDES, <1,1,1>, alpha, PRIM_SIZE, <0.01, diameter, diameter>]);
	ptSet("alpha", alpha, FALSE);
	float multi = 1;
	llLinkParticleSystem(5, [
        PSYS_PART_MAX_AGE,0.5, // max age
        PSYS_PART_FLAGS, 
            PSYS_PART_EMISSIVE_MASK|
            //PSYS_PART_WIND_MASK|
            //PSYS_PART_RIBBON_MASK|
            PSYS_PART_INTERP_COLOR_MASK|
            PSYS_PART_INTERP_SCALE_MASK|
            //PSYS_PART_RIBBON_MASK|
            PSYS_PART_FOLLOW_VELOCITY_MASK
            , // flags, glow etc
        PSYS_PART_START_COLOR, <.5, .75, 1>, // startcolor
        PSYS_PART_END_COLOR, <1, 1, 1>, // endcolor
        PSYS_PART_START_SCALE, <.075, .12, 0>*multi, // startsize
        PSYS_PART_END_SCALE, <0.0, .0, 0>*multi, // endsize
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE, // pattern
        PSYS_SRC_BURST_RATE, 0.025, // rate
        PSYS_SRC_ACCEL, <0,0,-6>*multi,  // push
        PSYS_SRC_BURST_PART_COUNT, 1, // count
        PSYS_SRC_BURST_RADIUS, 0.1, // radius
        PSYS_SRC_BURST_SPEED_MIN, 0*multi, // minSpeed
        PSYS_SRC_BURST_SPEED_MAX, 3*multi, // maxSpeed
        // PSYS_SRC_TARGET_KEY, NULL_KEY, // target
        PSYS_SRC_OMEGA, <0., 0., 0.>, // omega
        PSYS_SRC_MAX_AGE, .3, // life
        PSYS_SRC_TEXTURE, "dcab6cc4-172f-e30d-b1d0-f558446f20d4", // texture
        
        PSYS_PART_START_ALPHA, .0, // startAlpha
        PSYS_PART_END_ALPHA, .7, // endAlpha
        PSYS_PART_START_GLOW, 0.0,
        PSYS_PART_END_GLOW, 0,
        
        PSYS_SRC_ANGLE_BEGIN, .7, // angleBegin
        PSYS_SRC_ANGLE_END,.7 // angleend
    ]);
	
	llParticleSystem([
        PSYS_PART_MAX_AGE,.8, // max age
        PSYS_PART_FLAGS, 
            //PSYS_PART_EMISSIVE_MASK|
            //PSYS_PART_WIND_MASK|
            PSYS_PART_INTERP_COLOR_MASK|
            PSYS_PART_INTERP_SCALE_MASK|
            //PSYS_PART_RIBBON_MASK|
            PSYS_PART_FOLLOW_VELOCITY_MASK
            , // flags, glow etc
        PSYS_PART_START_COLOR, <.6, .8, 1>, // startcolor
        PSYS_PART_END_COLOR, <1, 1, 1>, // endcolor
        PSYS_PART_START_SCALE, <.5, .5, 0>*multi, // startsize
        PSYS_PART_END_SCALE, <1, 1, 0>*multi, // endsize
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE, // pattern
        PSYS_SRC_BURST_RATE, 0.025, // rate
        PSYS_SRC_ACCEL, <0,0,-4>*multi,  // push
        PSYS_SRC_BURST_PART_COUNT, 3, // count
        PSYS_SRC_BURST_RADIUS, 0.2, // radius
        PSYS_SRC_BURST_SPEED_MIN, 0*multi, // minSpeed
        PSYS_SRC_BURST_SPEED_MAX, 2.*multi, // maxSpeed
        // PSYS_SRC_TARGET_KEY, NULL_KEY, // target
        PSYS_SRC_OMEGA, <0., 0., 0.>, // omega
        PSYS_SRC_MAX_AGE, .2, // life
        PSYS_SRC_TEXTURE, "dcab6cc4-172f-e30d-b1d0-f558446f20d4", // texture
        
        PSYS_PART_START_ALPHA, .05, // startAlpha
        PSYS_PART_END_ALPHA, 0.0, // endAlpha
        PSYS_PART_START_GLOW, 0.0,
        PSYS_PART_END_GLOW, 0,
        
        PSYS_SRC_ANGLE_BEGIN, 1.2, // angleBegin
        PSYS_SRC_ANGLE_END, 1.2 // angleend
    ]);
}

footstep( integer size ){

	float multi = size+1;
	
	llLinkParticleSystem(3, [
        PSYS_PART_MAX_AGE,.4, // max age
        PSYS_PART_FLAGS, 
            //PSYS_PART_EMISSIVE_MASK|
            //PSYS_PART_WIND_MASK|
            //PSYS_PART_RIBBON_MASK|
            PSYS_PART_INTERP_COLOR_MASK|
            PSYS_PART_INTERP_SCALE_MASK|
            //PSYS_PART_RIBBON_MASK|
            PSYS_PART_FOLLOW_VELOCITY_MASK
            , // flags, glow etc
        PSYS_PART_START_COLOR, <.75, .9, 1>, // startcolor
        PSYS_PART_END_COLOR, <1, 1, 1>, // endcolor
        PSYS_PART_START_SCALE, <.075, .075, 0>*multi, // startsize
        PSYS_PART_END_SCALE, <0.0, .05, 0>, // endsize
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE, // pattern
        PSYS_SRC_BURST_RATE, 0.015, // rate
        PSYS_SRC_ACCEL, <0,0,-3>*2*multi,  // push
        PSYS_SRC_BURST_PART_COUNT, 1, // count
        PSYS_SRC_BURST_RADIUS, 0.05*multi, // radius
        PSYS_SRC_BURST_SPEED_MIN, 0., // minSpeed
        PSYS_SRC_BURST_SPEED_MAX, 1.5*multi, // maxSpeed
        // PSYS_SRC_TARGET_KEY, NULL_KEY, // target
        PSYS_SRC_OMEGA, <0., 0., 0.>, // omega
        PSYS_SRC_MAX_AGE, .2, // life
        PSYS_SRC_TEXTURE, "dcab6cc4-172f-e30d-b1d0-f558446f20d4", // texture
        
        PSYS_PART_START_ALPHA, .4, // startAlpha
        PSYS_PART_END_ALPHA, 0, // endAlpha
        PSYS_PART_START_GLOW, 0.0,
        PSYS_PART_END_GLOW, 0,
        
        PSYS_SRC_ANGLE_BEGIN, .75, // angleBegin
        PSYS_SRC_ANGLE_END,.75 // angleend
    ]);

	
	llLinkParticleSystem(4, [
        PSYS_PART_MAX_AGE,.5, // max age
        PSYS_PART_FLAGS, 
            //PSYS_PART_EMISSIVE_MASK|
            //PSYS_PART_WIND_MASK|
            //PSYS_PART_RIBBON_MASK|
            PSYS_PART_INTERP_COLOR_MASK|
            PSYS_PART_INTERP_SCALE_MASK//|
            //PSYS_PART_RIBBON_MASK|
            //PSYS_PART_FOLLOW_VELOCITY_MASK
            , // flags, glow etc
        PSYS_PART_START_COLOR, <.7, .8, 1>, // startcolor
        PSYS_PART_END_COLOR, <1, 1, 1>, // endcolor
        PSYS_PART_START_SCALE, <.2, .1, 0>*multi, // startsize
        PSYS_PART_END_SCALE, <0.5, .4, 0>*(0.5+multi/2), // endsize
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE, // pattern
        PSYS_SRC_BURST_RATE, 0.1, // rate
        PSYS_SRC_ACCEL, <0,0,0.>*multi,  // push
        PSYS_SRC_BURST_PART_COUNT, 1, // count
        PSYS_SRC_BURST_RADIUS, 0.0, // radius
        PSYS_SRC_BURST_SPEED_MIN, 0.0, // minSpeed
        PSYS_SRC_BURST_SPEED_MAX, .01*multi, // maxSpeed
        // PSYS_SRC_TARGET_KEY, NULL_KEY, // target
        PSYS_SRC_OMEGA, <0., 0., 0.>, // omega
        PSYS_SRC_MAX_AGE, .4, // life
        PSYS_SRC_TEXTURE, "a451b090-f493-fa64-e83d-78eadce7d6ef", // texture
        
        PSYS_PART_START_ALPHA, .5, // startAlpha
        PSYS_PART_END_ALPHA, .0, // endAlpha
        PSYS_PART_START_GLOW, 0.0,
        PSYS_PART_END_GLOW, 0,
        
        PSYS_SRC_ANGLE_BEGIN, .5, // angleBegin
        PSYS_SRC_ANGLE_END,.5 // angleend
    ]);
	
	if( size )
		llLinkParticleSystem(5, [
			PSYS_PART_MAX_AGE,.8, // max age
			PSYS_PART_FLAGS, 
				//PSYS_PART_EMISSIVE_MASK|
				//PSYS_PART_WIND_MASK|
				PSYS_PART_INTERP_COLOR_MASK|
				PSYS_PART_INTERP_SCALE_MASK|
				//PSYS_PART_RIBBON_MASK|
				PSYS_PART_FOLLOW_VELOCITY_MASK
				, // flags, glow etc
			PSYS_PART_START_COLOR, <.6, .8, 1>, // startcolor
			PSYS_PART_END_COLOR, <1, 1, 1>, // endcolor
			PSYS_PART_START_SCALE, <.75, .75, 0>, // startsize
			PSYS_PART_END_SCALE, <0, .2, 0>, // endsize
			PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE, // pattern
			PSYS_SRC_BURST_RATE, 0.025, // rate
			PSYS_SRC_ACCEL, <0,0,-6>,  // push
			PSYS_SRC_BURST_PART_COUNT, 3, // count
			PSYS_SRC_BURST_RADIUS, 0.3, // radius
			PSYS_SRC_BURST_SPEED_MIN, 0, // minSpeed
			PSYS_SRC_BURST_SPEED_MAX, 2., // maxSpeed
			// PSYS_SRC_TARGET_KEY, NULL_KEY, // target
			PSYS_SRC_OMEGA, <0., 0., 0.>, // omega
			PSYS_SRC_MAX_AGE, .3, // life
			PSYS_SRC_TEXTURE, "883c11fb-1468-fa1e-231a-f1c531027f18", // texture
			
			PSYS_PART_START_ALPHA, .2, // startAlpha
			PSYS_PART_END_ALPHA, 0.0, // endAlpha
			PSYS_PART_START_GLOW, 0.0,
			PSYS_PART_END_GLOW, 0,
			
			PSYS_SRC_ANGLE_BEGIN, 1, // angleBegin
			PSYS_SRC_ANGLE_END, 1 // angleend
		]);
	
}

wetBody( int on ){
	if( !on ){		
		llLinkParticleSystem(1, []);
		ptUnset("wet");
		ptUnset("WT");
		return;
	}
	
	ptSet("WT", 0.1, TRUE);
	ptSet("wet", 30, FALSE);
	llLinkParticleSystem(1, [
		PSYS_PART_MAX_AGE,1, // max age
		PSYS_PART_FLAGS, 
			//PSYS_PART_EMISSIVE_MASK|
			//PSYS_PART_WIND_MASK|
			PSYS_PART_INTERP_COLOR_MASK|
			PSYS_PART_INTERP_SCALE_MASK//|
			//PSYS_PART_FOLLOW_VELOCITY_MASK
			, // flags, glow etc
		PSYS_PART_START_COLOR, <.8, .9, 1>, // startcolor
		PSYS_PART_END_COLOR, <1, 1, 1>, // endcolor
		PSYS_PART_START_SCALE, <.05, .05, 0>, // startsize
		PSYS_PART_END_SCALE, <.05, .2, 0>, // endsize
		PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE, // pattern
		PSYS_SRC_BURST_RATE, 0.1, // rate
		PSYS_SRC_ACCEL, <0,0,-2.5>,  // push
		PSYS_SRC_BURST_PART_COUNT, 1, // count
		PSYS_SRC_BURST_RADIUS, 1.25, // radius
		PSYS_SRC_BURST_SPEED_MIN, 0, // minSpeed
		PSYS_SRC_BURST_SPEED_MAX, .1, // maxSpeed
		// PSYS_SRC_TARGET_KEY, NULL_KEY, // target
		PSYS_SRC_OMEGA, <0., 0., 0.>, // omega
		PSYS_SRC_MAX_AGE, 0, // life
		PSYS_SRC_TEXTURE, "dcab6cc4-172f-e30d-b1d0-f558446f20d4", // texture
		
		PSYS_PART_START_ALPHA, .0, // startAlpha
		PSYS_PART_END_ALPHA, 0.2, // endAlpha
		PSYS_PART_START_GLOW, 0.0,
		PSYS_PART_END_GLOW, 0,
		
		PSYS_SRC_ANGLE_BEGIN, .15, // angleBegin
		PSYS_SRC_ANGLE_END, .15 // angleend
	]);
}

key REZZER;

ptEvt( string id ){

	if( id == "A" ){
		
		if( llKey2Name(REZZER) == "" )
			llDie();
	
	}
	else if( id == "alpha" ){
		
		alpha -= 0.05;
		if( alpha <= 0 )
			alpha = 0;
		else{
		
			ptSet(id, 0.05, FALSE);			
		}
		
		llSetLinkPrimitiveParamsFast(P_RINGS, [PRIM_COLOR, ALL_SIDES, <1,1,1>, alpha]);
		
		if( alpha <= 0 )
			llSetLinkPrimitiveParamsFast(P_RINGS, [PRIM_SIZE, <0,.5,.5>]);
		
	}
	
	else if( id == "wet" )
		wetBody(FALSE);
		
	else if( id == "WT"){
		
		vector size = llGetAgentSize(llGetOwner());
		vector pos = prPos(llGetOwner());
		pos.z -= size.z/2;
		float offs = z_offset;
		if( offs <= 0 )
			offs = 0.05;
		pos.z += offs;
		llSetRegionPos(pos);
		
	}

}


default{
    
    on_rez( integer total ){
        llResetScript();
    }
    
	
	timer(){
		ptRefresh();
	}
	
    state_entry(){
        
		llSetStatus(STATUS_DIE_AT_EDGE, TRUE);
        llListen(Primswim$partChan, "", "", "");
        memLim(1.5);
        llSetStatus(STATUS_PHANTOM, TRUE);
		REZZER = mySpawner();
		ptSet("A", 1, TRUE);
		
		links_each( nr, name,
			if( name == "RINGS" )
				P_RINGS = nr;
		)
		//waterEnterSplash(2);
		llLinkParticleSystem(LINK_SET, []);
		
		llRegionSay(Primswim$partChan, jasPrimswimParticles$kill);
		wetBody( FALSE );
		//waterEnterSplash(2);
		//emerge();
		//footstep(0);
		
    }
	
	listen( integer c, string n, key id, string message ){
		idOwnerCheck
		
		list data = llJson2List(message);
		string task = l2s(data, 0);
		data = llDeleteSubList(data, 0, 0);
		
		if( task == jasPrimswimParticles$onWaterEntered ){
		
			wetBody(FALSE);
			llSetRegionPos((vector)l2s(data,1));
			llSetRot((rotation)llList2Rot(data, 2));
			llSleep(.1);
			waterEnterSplash(l2i(data, 0));
			
			
		}
		
		else if( task == jasPrimswimParticles$onWaterExited )
			wetBody(TRUE);
		
		else if( task == jasPrimswimParticles$onFeetWetSplash ){
			
			llSetRegionPos((vector)l2s(data, 1));
			footstep(l2i(data, 0));
			
		}
		
		else if( task == jasPrimswimParticles$emerge ){
			
			llSetRegionPos((vector)l2s(data, 0));
			llSleep(.05);
			emerge();
			
		}

		else if( task == jasPrimswimParticles$kill )
			llDie();
		
	}

}


