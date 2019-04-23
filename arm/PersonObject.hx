





package arm;


import iron.data.Armature;
import kha.math.Random;
import iron.math.Quat;
import custom_lib.CustomLib;
import custom_lib.CustomGame;


import iron.Scene;
import iron.App;
import iron.system.Time;
import armory.system.Event;


import iron.math.Quat;
import iron.math.Vec4;
import iron.math.Mat4;

import iron.system.Input;
import iron.object.Object;
import iron.object.CameraObject;
import iron.object.BoneAnimation;
import iron.object.ObjectAnimation;


import iron.object.Transform;
import iron.object.Animation;
import armory.trait.physics.PhysicsWorld;
import armory.trait.physics.RigidBody;
import armory.trait.internal.CameraController;
import armory.trait.internal.CanvasScript;



//import armory.trait.physics.bullet.*;

import armory.trait.physics.bullet.RigidBody.ActivationState;


import iron.data.MaterialData;
import iron.object.MeshObject;

import kha.FastFloat;

//Custom trait.
import arm.CustomObject;


// Began as a clone of class "FirstPersonController" from the Bundled (Armory-provided) classes.
// Also including script from its parent "CameraController" so that this class
// may inherit from the base object for any object in the game, CustomObject (directly or indirectly) instead.
// UPDATE - no longer doing the "CustomObject" inheritence.
// CustomObject will instead be used separately for things expected to be retrievable for any game object.
// It would be better to get an object's CustomObject trait (that it must have) and act on that for finding
// more specific info.
// It would be fine to use classes meant to store otherwise redundant info as parents, such as "PersonObject" between
// "PlayerObject" and "PersonAIObject", but keep in mind only the actual specific trait used (Player / PersonAI)
// could be retrieved from Armory's "getTrait(...)" call, never more broadly from say "getTrait(PersonObject)".
// ANOTHER UPDATE - this is now the Person's trait instead of just for the player.
// PlayerObject and PersonAIObject will inherit from this and add functionality on top of this.
// They can be generated / used ingame, while PersonObject should never be used on its own.
// PersonObject is just structure. It only exists to store things common between PlayerObject and PersonAIOBject.
// And note that "PersonObject" has no parent (besides the mandatory "iron.Trait" as a parent).
// The "CustomObject" trait is independent of this and occurs at the same time to be called on by any game object
// for commonly needed variables.

class PersonObject extends iron.Trait {

	public var spawnCalled:Bool = false;

#if (!arm_physics)
	public function new() { super(); }
#else

	public var everAnimatedBefore:Bool = false;

	public var vecMoveSpeed:Float = 100 * 0.01;

	

	public var vecJumpForceMag:Float = 32;

	public static inline var personGravity:Float = -56;

//FROM CameraController.hx

	var body:RigidBody;

	var moveForward = false;
	var moveBackward = false;
	var moveLeft = false;
	var moveRight = false;
	var jump = false;

////////////////////////////////////////////////////////////

	// Stored separately as to not affect orientation.
	public var _pitch:Float = 90*(Math.PI/180);
	
	// The bow & arrow objects attached to the archer's hands. These are not collidable or part of any logic.
	public var bowObject:Object;
	public var arrowObject:Object;
	public var personArmatureObject:Object;  //raw object itself; don't trust its ".animation".
	public var personArmatureAnimation:BoneAnimation;  //the real way to play animations on the armature.


	// Configure to allow multi-jumping since reaching the ground. Never changes ingame.
	public var maxJumpsAllowed:Int = 1;
	// Current jumps allowed.
	public var jumpsAllowed:Int = 0;
	public var jumpResetBlockDelay:Float = 0;
	public var groundStickyTime:Float = 0;
	public var groundFloatTime:Float = 0;


	public var autoHealDelay:Float = 0;
	public var reloadDelay:Float = 0;
	public var currentHealth:Float = 0;

	public var animationPlayer:BoneAnimation;

	//public var idealAngle:Quat = new Quat();
	public var idealYawAngle:Float = 0;
	
	//Do I want to fire an arrow right now?  Must also have an arrow ready to fire to actually do that.
	public var fireArrowIntent:Bool = false;

	public var actionTest:String = "Player ArmatureAction";
	public var dir:Vec4 = new Vec4();
	var xVec = Vec4.xAxis();
	var zVec = Vec4.zAxis();

	var clickMem:Int = 0;

	var physics:armory.trait.physics.PhysicsWorld;

	public var myFaction:Faction = Faction.UNSET;


	public function new() {
		super();

		// NOTICE. "nofity" calls moved to "setupEventLinks".
		setupEventLinks();
		
	}//END OF new


	// This method must be overridden by a child class to link each of these events
	// to a child's own events, which each call "super" to call the parent's methods here.
	// DON'T call "super.setupEventLinks", replace it entirely. And provide all methods here.
	// This way, only the child establishes the links by "notify" and calls all parent methods
	// as expected.
	public function setupEventLinks(){
		PhysicsWorld.active.notifyOnPreUpdate(preUpdate);
		notifyOnUpdate(update);
		notifyOnRemove(removed);
	}//END OF setupEventLinks

	// Same for here, don't call "super" in child classes. Just remove your own link in there.
	public function removePreUpdateLink(){
		PhysicsWorld.active.removePreUpdate(preUpdate);
	}

	// This method should be overridden in child classes for dynamically generated objects.
	// But still call this parent method because it sets up the material to use, which always works the same way.
	public function spawned( arg_faction:Faction){
		

		

		// to where I am looking now to start.
		idealYawAngle = getYawAngle();
		

		this.myFaction = arg_faction;

		this.currentHealth = this.getMaxHealth();

		// depending on the faction, pick a material to use for myself and the dummy arrow (in this object's heirarchy) for animations.
		var myMeshMat:String = CustomGame.aryStr_resource_person_materialList[ myFaction ];
		var myArrowMat:String = CustomGame.aryStr_resource_arrow_materialList[ myFaction ];

		
		
		trace("HERE I GO A1");
		// The top-most object, the collider, has a cylinder only for showing the size of the collider.
		// Don't render it.
		CustomLib.setObjectVisibility(object, false);
		trace("HERE I GO A2");


		
		personArmatureObject = CustomLib.getDirectChild(object, "person_armature");
		personArmatureAnimation = CustomLib.getArmatureAnimationOfObject(personArmatureObject);

		bowObject = CustomLib.getDirectChild(personArmatureObject, "person_bow_mesh");
		arrowObject = CustomLib.getDirectChild(personArmatureObject, "person_arrow_mesh");




		CustomLib.getMaterial(myMeshMat,
			function(mat:MaterialData){
				var myMeshObject:Object = CustomLib.getDirectChild(personArmatureObject, "person_mesh");
				if(myMeshObject!=null){
					var tempMeshRef:MeshObject = cast(myMeshObject, MeshObject);

					trace("HEY MAT LENGTH WHAT " + tempMeshRef.materials.length);

					CustomLib.setTexturesFromMaterial(tempMeshRef, mat);
					//you. YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU-wuh!
					
				}
			}
		);

		
		CustomLib.getMaterial(myArrowMat,
			function(mat:MaterialData){
				if(arrowObject!=null){
					trace("WOO HOOO");
					CustomLib.setTexturesFromMaterial_obj(arrowObject, mat);
					
				}
			}
		);

		//CustomLib.setObjectVisibility(arrowObject, false);
		
		
		

		//The rest of init script has been moved to "spawn".
		
		body = object.getTrait(RigidBody);

		physics = armory.trait.physics.PhysicsWorld.active;

		//NOTICE - don't use the engine's damping. It affects the fall speed too.
		//We only want damping to affect groundwise motion to slow down fast if no keys
		//are pressed, so it must be implemented manually.
		CustomSetDamping(0.0, 0.0);
		
		if(body != null){
			body.setGravity(new Vec4(0, 0, personGravity) );
			body.setFriction(0);
			
			body.body.setActivationState( ActivationState.Active);

			/*
			//This is not as effective as once thought.
			var CF_STATIC_OBJECT = 1; // bullet.Bt.CollisionObject.CF_STATIC_OBJECT
			trace("MY FLAGS A " + body.body.getCollisionFlags());
			//Remove the STATIC_OBJECT flag we're starting with that keeps the template
			//from falling.
			body.body.setCollisionFlags( body.body.getCollisionFlags() & ~CF_STATIC_OBJECT  );
			trace("MY FLAGS B " + body.body.getCollisionFlags());
			*/
		}
		
		
		if(object.animation != null){
			animationPlayer = cast(object.animation, BoneAnimation);
		}else{
			// that won't work now.
			//animationPlayer = object.getParentArmature(object.name);


			trace("------------------CHILD LIST START");
			for(thing in object.children){
				trace("MY CHILD???! " + thing.name);
			}
			trace("------------------CHILD LIST END");

			// do this
			//var armatureTest:iron.object.Object = object.getChild("person_armature");
			var armatureTest:iron.object.Object = CustomLib.getDirectChild(object, "person_armature");
			trace("IS IT notNULL THOUGH?! " + (armatureTest!=null) );
			if(armatureTest != null){
				//trace("Is animation notNull? " + (armatureTest.animation!=null));

				//var armRaw:Armature = cast(armatureTest.raw, Armature);
				
				/*
				var armRaw:Armature = CustomLib.getArmatureOfObject(armatureTest);
				trace("IS armature notnull? " + (armRaw!=null));
				if(armRaw != null){
					//trace("Is armature anim notnull? " + (armRaw.anim));
				}
				*/


				var someAnim:BoneAnimation = CustomLib.getArmatureAnimationOfObject(armatureTest);
				trace("PLEASE BE HERE " + (someAnim!=null));

				//someAnim.play("bow_backwaver", function(){}, 0, 1.0, true);
				

				//animationPlayer = cast(armatureTest.animation, BoneAnimation);
				animationPlayer = someAnim;

				//armatureTest.setupAnimation()
				//animationPlayer.data.format.frame_time.
				
			}

			/*
			if(armatureTest != null){
				trace("armatureTest.animation?  " + (armatureTest.animation!=null) );

				if(armatureTest != null){
					var daMesh:Object = armatureTest.getChild("person_mesh");
					trace("person_armature null? " + (daMesh.getParentArmature("person_armature")!=null) );

					//animationPlayer = cast(object.getChild("person_armature").animation, BoneAnimation);
					animationPlayer = daMesh.getParentArmature("person_armature");
				}
			}
			*/
		}

		/*
		trace("animationPlayer present? " + (animationPlayer!=null) );
		



		//var person_armature:Object = object.getChild("person_armature");
		var person_armature:Object = CustomLib.getDirectChild(object, "person_armature");
		var anim:BoneAnimation = CustomLib.getArmatureAnimationOfObject(person_armature);

		var person_bow_mesh:Object = person_armature.getChild("person_bow_mesh");
		var animBow:ObjectAnimation = cast(person_bow_mesh.animation, ObjectAnimation);

		for(thisAct in anim.armature.actions){
			trace("ANIM NAME: " + thisAct.name);
		}

		trace("My object ID? " + object.uid);
		trace("My armature ID? " + person_armature.uid);
		trace("My animation\'s armature ID? " + anim.armature.uid);
		
		person_armature.name = "person_armature";
		
		anim.play(
			"bow_backwaver",
			function onComplete(){
				
			},
			0, 1, true
		);
		*/
		
		/*
		animBow.play(
			"person_bow_flipAround",
			function onComplete(){
				
			},
			0, 1, true
		);
		*/







		// Why yes, you were.
		spawnCalled = true;

	}//END OF spawned

	function removed(){
		if(!spawnCalled)return;
		// For whatever class this is, remove its own linked method only.
		// Any child class overriding "removed" and calling "super" will also accomplish this.
		removePreUpdateLink();
	}

	function preUpdate() {
		if(!spawnCalled)return;
		
		
	}//END OF preUpdate


	function update(){
		if(!spawnCalled)return;
		if (body==null || !body.ready) return;

		//"armory.trait.physics.bullet.RigidBody" is the more specific form seen in an example.  Maintaining this for safety.
		//The "Rigidbody" used so  far, armory.trait.physics.Rigidbody, is actualy a typedef that likely links to that same thing.

		if(body!=null){
			//Every frame, do a raycast below.  If it hits the ground, we need to be told to float above it very slightly.
			
			if(jumpResetBlockDelay <= iron.system.Time.time() ){
				var myLoc:Vec4 = object.transform.loc;
				var physics = armory.trait.physics.PhysicsWorld.active;
				
				
				var rayCastResult:RigidBody = physics.rayCast(object.transform.loc, new Vec4(myLoc.x, myLoc.y, myLoc.z - (12 + 2.1) )  );
				//trace("rayCastResult? " + (rayCastResult!=null) );
				if(rayCastResult != null){
					var tempRef:CustomObject = rayCastResult.object.getTrait(CustomObject);
					if(tempRef != null && tempRef.isGround() ){

						if(groundFloatTime == 0){
							var pointHit:Vec4 = physics.hitPointWorld;
							body.disableGravity();
							object.transform.loc = new Vec4(myLoc.x, myLoc.y, pointHit.z + 12 + 1.5);
							object.transform.buildMatrix();
							body.syncTransform();
							if (body != null) body.syncTransform();
							
						}
						jumpsAllowed = maxJumpsAllowed;

						groundFloatTime = iron.system.Time.time() + 0.2;
						
						//body.restitution
					}
				}
				
				
			}//END OF jumpResetBlockDelay check

			if(groundFloatTime != 0){
				if(groundFloatTime <= iron.system.Time.time()){
					//if groundFloatTime has expired, drop to the ground.
					groundFloatTime = 0;
					body.enableGravity();
					body.setGravity(new Vec4(0, 0, personGravity) );
				}else{
					//still active? Forbid Z velocity.
					var myVel:Vec4 = body.getLinearVelocity();
					body.setLinearVelocity(myVel.x, myVel.y, 0);
				}
			}

			var rbs:Array<RigidBody> = physics.getContacts(body);

			if (rbs != null) {
				//var individua:armory.trait.physics.bullet.RigidBody = rbs[0];
				for (rb in rbs){
					if( rb.object != null){
						var tempRef:CustomObject = rb.object.getTrait(CustomObject);
						if(tempRef != null){
							if(tempRef.isGround() && jumpResetBlockDelay <= iron.system.Time.time()){
								// Touching any object marked "ground" allows the player to jump again.
								// Although, this doesn't check for colliding with something above or below me.
								// Would be good to check if this were possible or else bumping a ground-marked
								// platform from below would count as "hitting the ground" for a jump allowed, 
								// even in mid-air.
								jumpsAllowed = maxJumpsAllowed;

								// Also, forbid getting thrust into the air by... snagging on the flat terrain mesh.
								// Gotta love a beta.
								groundStickyTime = iron.system.Time.time() + 0.2;
								
							}
						}
					}//END OF rb.object null check
				}//END OF for each object collided with this frame
			}
		}//END OF body null check

		if (jump) {
			//Only jump if I have at least one jump remaining.
			if(jumpsAllowed > 0){
				var myVel:Vec4 = body.getLinearVelocity();

				//In case of double jumping, cancel all Z velocity first. It's the standard.
				//Otherwise a mid-air double jump in the middle of falling might just look like
				//it slows down the fall a little, not very exciting.
				body.setLinearVelocity(myVel.x, myVel.y, 0);


				if(this.myFaction == Faction.PLAYER && CustomGame.playerSuperJump){
					// cheat: player super jump
					body.applyImpulse(new Vec4(0, 0, vecJumpForceMag * 6));
				}else{
					// normal jump.
					body.applyImpulse(new Vec4(0, 0, vecJumpForceMag));
				}


				jumpsAllowed -= 1;

				// Can't reset the jump number again from collisions with the ground until
				// this short delay has passed. While jumping off the ground, a collision with
				// the ground would still occur and reset the jump number without this check.
				jumpResetBlockDelay = iron.system.Time.time() + 0.35;
				
				// Don't allow groundStickyTime to stop the jump's vertical velocity.
				groundStickyTime = 0;
				groundFloatTime = 0;  //same.
				body.enableGravity();
				body.setGravity(new Vec4(0, 0, personGravity) );
			}

			jump = false;
		}//END OF "jump" input check

		if(groundStickyTime > 0 && groundStickyTime >= iron.system.Time.time()){
			// If groundStickyTime is set and hasn't expired, forbid vertical velocity
			// to stop thrusts from snagging on flat meshes. Yes, that happens.
			// ...unforunately this approach didn't work fully. It does stop the vertical thrust,
			// but there's still a slowdown to the floorwise motion. Or even a thrust in a 
			// random direction floorwise.
			//var myVel:Vec4 = body.getLinearVelocity();
			//body.setLinearVelocity(myVel.x, myVel.y, 0);
		}//END OF groundStickyTime check


		// Move
		var vecForward:Vec4 = object.transform.look();
		var vecRight:Vec4 = object.transform.right();

		dir.set(0, 0, 0);
		if (moveForward) dir.add(vecForward);
		if (moveBackward) dir.add(vecForward.mult(-1));
		if (moveLeft) dir.add(vecRight.mult(-1));
		if (moveRight) dir.add(vecRight);

		// Push down
		// ...wait, why was this in FirstPersonController? Is this any different from upping the gravity?
		//var btvec = body.getLinearVelocity();
		//body.setLinearVelocity(0.0, 0.0, btvec.z - 1.0 );

		if(body != null){

			if (moveForward || moveBackward || moveLeft || moveRight) {

				if(this.myFaction == Faction.PLAYER && CustomGame.playerSpeedy){
					// cheat: super speed for the player.
					dir.mult(500 * 0.01);
				}else{
					// normal speed.
					dir.mult(vecMoveSpeed);
				}

				body.activate();

				//body.setLinearVelocity(dir.x, dir.y, btvec.z - 1.0 );

				
				/*
				if(animationPlayer!=null && !everAnimatedBefore){
					everAnimatedBefore = true;
					
					// If blending is on...
					// Resetting time but not frameIndex can cause issues.
					// Otherwise no difference between setting both at the same time, or neither at the same time?
					animationPlayer.time = 0;
					animationPlayer.frameIndex = -1;
					
					
					// It appears "blendTime" is how long the animation runs at a minimum? unsure.
					// Such as, even if it has enough speed to play once under a blendtime of 2,
					// it will continue playing until the blendtime (2) seconds have passed.
					// Although in an extreme example, such as blendtime of 8, and a speed of 8
					// (parameter after that), the first time is really slow across the 8 seconds.
					// Then it plays rapidly at the 8x speed (probably?) as expected.
					// To summarize, really unsure, sticking with one animation play and a blendtime
					// of 0 (as long as it needs but no longer) should work fine.
					

					//setAction(armature.actions[0].name)
					trace("PRINT ARRAY!!!");
					for(acto in animationPlayer.armature.actions){
						trace(acto.name);
					}
					
					trace("***ANIM START***");
					animationPlayer.play(
						"bow_backwaver",
						function(){
							//This is a callback. Anything to do when this animation finishes?
							trace("anim COMPLETE?");
							everAnimatedBefore = false;
						},
						0,
						1.0,
						false
					);
					
				}
				*/
				


				// Movement speed decreases fairly quickly so that changing direction while moving still
				// has a bit of slide to it.
				var myVel:Vec4 = body.getLinearVelocity();
				body.setLinearVelocity( myVel.x * 0.94 + dir.x, myVel.y * 0.94 + dir.y, myVel.z );
				
				object.transform.buildMatrix();
				body.syncTransform();
			}else{
				// Nothing pressed? slow down faster.
				var myVel:Vec4 = body.getLinearVelocity();
				body.setLinearVelocity( myVel.x * 0.8, myVel.y * 0.8, myVel.z );
			}
			//Do I want to rotate to face anywhere?

			// Keep vertical
			body.setAngularFactor(0, 0, 0);

		}//END OF body null check

		if(autoHealDelay <= iron.system.Time.time()){
			autoHealDelay = iron.system.Time.time() + 6;
			currentHealth += getAutoHealAmount();
			//cannot exceed maxHealth.
			if(currentHealth > getMaxHealth()){
				currentHealth = getMaxHealth();
			}
		}

		if(fireArrowIntent && reloadDelay <= iron.system.Time.time()){
			
			reloadDelay = iron.system.Time.time() + getReloadTime();

			var vecFireOrigin:Vec4 = getArrowFirePoint();
			var myForward:Vec4 = object.transform.look();


			/*
			var myEul:Vec4 = object.transform.rot.getEuler();
			
			//var myEul:Vec4 = new Vec4(0,0,0);
			trace("WHAT BE MY ANGLE THOUGH " + myEul);
			trace("IM TERRIBLE " + object.transform.rot);
			//trace("WHATS MY PITCH " + getPitchAngle());

			//CustomLib.getLookAngle(object.transform.loc, new Vec4(object.transform.loc.x + myForward.x, object.transform.loc.y + myForward.y, object.transform.loc.z + myForward.z) );
			*/
			var myPitch:Float = getPitchAngle() - (90*(Math.PI/180));
			
			//myEul.x += myPitch;
			
			

			
			

			var thewhat:Quat = new Quat(object.transform.rot.x, object.transform.rot.y, object.transform.rot.z, object.transform.rot.w);
			
			CustomLib.rotateQuatByAxisAngle(thewhat, object.transform.right().normalize(), myPitch);



			CustomLib.spawnObject_quat(CustomGame.currentSceneName + "_" + "person_ap_temp", new Vec4(vecFireOrigin.x, vecFireOrigin.y, vecFireOrigin.z), thewhat, new Vec4(0.12, 0.42, 0.12),
				function(o:Object){
					
					var traitGen:ArrowProjectileObject = new ArrowProjectileObject();
					o.addTrait(traitGen);
					traitGen.spawned(myFaction);

				},
			null, true
			);
			
		}
	}//END OF update


	// Note that this method doesn't run on scene cleanup when changing scenes, unlike Removed above.
	// This is only for running out of health as a geneal event.
	public function killed(){

		//default behavior: delete this archer.  The player should move to a "Game Over" end screen instead.
		object.remove();

	}//END OF killed


	//Where should an arrow I'm firing spawn?
	public function getArrowFirePoint():Vec4{
		var myLoc:Vec4 = object.transform.loc;
		var myForward:Vec4 = object.transform.look().normalize();
		return new Vec4(myLoc.x + myForward.x * 3.9, myLoc.y + myForward.y * 3.9, myLoc.z + 7.4);
	}

	public function CustomSetDamping(arg_linearDamping:Float, arg_angularDamping:Float){
		if(body != null){
			body.linearDamping = arg_linearDamping;
			body.angularDamping = arg_angularDamping;
			body.body.setDamping(arg_linearDamping, arg_angularDamping);
		}
	}//END OF CustomSetDamping


	// for convenience.
	public function getYawAngle():Float{
		return object.transform.rot.getEuler().z;
	}
	public function getPitchAngle():Float{
		//return object.transform.rot.getEuler().x;
		//pitch is stored separately, to aim at whatever I'm looking at.
		return _pitch;
	}

	//defaults.
	public function getMaxHealth():Float{
		return 30;
	}
	public function getReloadTime():Float{
		return CustomLib.getRandomFloat(1.4, 2.4);
	}
	public function getAutoHealAmount():Float{
		return 2;
	}

	public function takeDamage(arg_damage:Float){
		currentHealth -= arg_damage;

		//...if only that worked.
		//CustomLib.playSound("snd/hit/hit_1.ogg");

		if(currentHealth <= 0){
			killed();
		}

	}//END OF takeDamage

	

#end

}//END OF class PersonObject




