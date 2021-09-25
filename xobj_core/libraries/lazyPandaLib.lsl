#ifndef _lazyPandaLib
#define _lazyPandaLib

// Aliasing functions into constants
#define AST llAvatarOnSitTarget()
#define OWNER llGetOwner()
#define ROT_BACKWARDS <0,0,1,0>

// Event aliases
// run_time_permissions
#define rtp(perm) run_time_permissions( integer perm )

#define reqPerm llRequestPermissions

// Macros for frequent code blocks
#define reqAstPerm( perms ) \
	if( AST ) \
		llRequestPermissions(AST, perms)
		
#define resetOnLink() \
	changed( integer change ){ \
		if( change & CHANGED_LINK ) \
			llResetScript(); \
	}

// Requests avatar on sit target animation permissions
#define reqAstAnim() \
	reqAstPerm(PERMISSION_TRIGGER_ANIMATION)

#define animOn( anim ) llStartAnimation(anim)
#define animOff( anim ) llStopAnimation(anim)

#define objAnimOn( anim ) llStartObjectAnimation(anim)
#define objAnimOff( anim ) llStopObjectAnimation(anim)




#endif
