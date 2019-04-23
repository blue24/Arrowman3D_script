



package arm;


import custom_lib.CustomLib;
import custom_lib.CustomGame;

import iron.object.MeshObject;

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
import iron.object.Transform;
import iron.object.Animation;
import armory.trait.physics.PhysicsWorld;
import armory.trait.physics.RigidBody;
import armory.trait.internal.CameraController;
import armory.trait.internal.CanvasScript;

import kha.FastFloat;

//Custom trait.
import arm.CustomObject;




// Child of Person that acts on its own, firing at archers of the opposite faction.
class PersonAIObject extends PersonObject {

	#if (!arm_physics)
		public function new() { super(); }
	#else
	public function new(){
		super();
	}

	public var nextLongThink:Float = 0;
	public var enemyObject:Object = null;

	public var expirationTime:Float = 0;



	public override function spawned(arg_faction:Faction){
		super.spawned(arg_faction);

		

		personArmatureAnimation.play(CustomGame.currentSceneName + "_" + "aim", null, 0, 1, false);
		
		// this shapekey animation is not working.  It's hard to say how to do this then.
		/*
		var myBow:Object = CustomLib.getDirectChild(myArmatureObject, "person_bow_mesh");
		var myBowMesh:MeshObject = cast(myBow, MeshObject);
		myBowMesh.animation.play("BowStringMaxPull", null, 0, 1, false);
		//myBowMesh.raw.
		//myBow.raw.anim.tracks
		*/
		
		
	}//END OF spawned

	// DONT call "super" versions of either of these, replace entirely!
	// Otherwise we could end up calling both child / parent methods in
	// different orders, and parent methods possibly twice in the same frame.
	public override function setupEventLinks(){
		PhysicsWorld.active.notifyOnPreUpdate(preUpdate);
		notifyOnUpdate(update);
		notifyOnRemove(removed);
	}//END OF setupEventLinks

	// Remove my own preUpdate method from the PhysicsWorld.
	public override function removePreUpdateLink(){
		PhysicsWorld.active.removePreUpdate(preUpdate);
	}

	public override function removed(){
		super.removed();

	}//END OF removed

	public override function preUpdate(){
		if(!spawnCalled)return;
		super.preUpdate();
	}//END OF preUpdate

	public override function update(){
		
		if(!spawnCalled)return;




		super.update();
		
		if(expirationTime != 0 && CustomLib.getCurrentTime() >= expirationTime){
			// Time to expire. Remove me.
			checkArcherCounts();
			object.remove();
			return;
		}

		//By default, unless I have an enemy in mind and am aiming at them.
		this.fireArrowIntent = false;
		
		if(enemyObject != null){
			//Aim at the enemy and fire.
			var lookAng:Vec4 = CustomLib.getLookAngle(object.transform.loc, enemyObject.transform.loc);

			var thatQuat:Quat = new Quat();

			// Don't store lookAng.x to our own angle. This will adjust the pitch of the entire model, including the legs.
			// At extreme pitches, this model would appear to defy gravity to stare at us.  Adjust the pitch at the torso (bone)
			// instead later.
			thatQuat.fromEuler(0, lookAng.y, lookAng.z);

			_pitch = lookAng.x + 90*(Math.PI/180);

			object.transform.rot = thatQuat;




			
			/*
			//return;
			var myArmatureObject:Object = CustomLib.getDirectChild(object, "person_armature");
			var myArmature:BoneAnimation = CustomLib.getArmatureAnimationOfObject(myArmatureObject);
			//trace("??? " + object.uid + " " + myArmature.data.raw.skin.
			




			
			
			
			//var person_cylinder_template:Object = THESCENE.getChild(CustomGame.currentSceneName + "_" + "person_cylinder_template");
			////var person_cylinder_template:Object = Scene.active.root.getChild("person_cylinder_template");
			//var person_armature:Object = person_cylinder_template.getChild("person_armature");
			//var originalAnim:BoneAnimation = CustomLib.getArmatureAnimationOfObject(person_armature);
			//var armRef:Armature = CustomLib.getArmatureOfObject(person_armature);
			
			
			//var someBone:TObj = originalAnim.getBone("");
			//someBone.transform.target
			
			//_pitch

			var tempQuat:Quat = new Quat();
			tempQuat.fromEuler(0, 0.04, 0 );

			var theMat:Mat4 = Mat4.identity();
			theMat.compose(new Vec4(0,0,0), tempQuat, new Vec4(1,1,1)); 
			//theMat.setLookAt( theMat.getLoc(), 
			//rotateQuatByAxisAngle
			//matrix "compose" function
			//theMat.toRotation

			//getLookAngle

			CustomLib.moveBone(myArmature, "spine_upper", theMat);
			*/







			body.syncTransform();

			//We face the enemy instantly for now, go ahead and work.
			fireArrowIntent = true;
			
		}//END OF enemyObject null check

		if(nextLongThink <= iron.system.Time.time() ){
			var theScene:Scene = CustomLib.getActiveScene();
			
			var myLoc = object.transform.loc;
			
			// Of all objects in the map within a certain distance,
			// pick the closest one to be my enemy to aim / fire arrows at.
			var objClosestYet:Object = null;
			var bestDistanceYet:Float = 1400; //range

			var sceneActive:Scene = CustomLib.getActiveScene();
			
			//for(thisChild in sceneActive.children){
			for(thisChild in iron.Scene.active.root.children){

				//don't try to target "myself".
				//may need to check object.uid's? unsure.
				if(thisChild != this.object){
					
					//if(CustomGame.factionHates)

					var playerTrait:PlayerObject = thisChild.getTrait(PlayerObject);
					var personAITrait:PersonAIObject = thisChild.getTrait(PersonAIObject);

					var personTrait:PersonObject = null;

					if(playerTrait != null){
						personTrait = playerTrait;
					}else if(personAITrait != null){
						personTrait = personAITrait;
					}

					if(personTrait != null){
						//This is another archer of some sort.
						//Do we hate this one?
						if(CustomGame.factionHates(this.myFaction, personTrait.myFaction) ){
							//this counts as a possible enemy.
							//What's my distance to this one?
							var otherLoc:Vec4 = thisChild.transform.loc;
							//var distTo:Float = new Vec4(otherLoc.x - myLoc.x, otherLoc.y - myLoc.y, otherLoc.z - myLoc.z).length();
							var distTo:Float = CustomLib.getDistance(myLoc, otherLoc);
							//trace("DIST TO? " + distTo);
							if(distTo < bestDistanceYet){


								// One more check. Is there an unobstructed line between me and the potential target?
								var myEyeLocation:Vec4 = new Vec4(object.transform.loc.x, object.transform.loc.y, object.transform.loc.z + 21);
								var targetCenter:Vec4 = new Vec4(thisChild.transform.loc.x, thisChild.transform.loc.y, thisChild.transform.loc.z + 12);

								var rayCastResult:RigidBody = physics.rayCast(myEyeLocation, targetCenter );
								//trace("rayCastResult? " + (rayCastResult!=null) );
								if(rayCastResult != null){
									if(rayCastResult.object.uid == thisChild.uid){
										//successful hit. This path is clear.
										bestDistanceYet = distTo;
										objClosestYet = thisChild;
									}
								}


							}

						}//END OF factionHates check
					}//END OF null check
				}//END OF self check
			}//END OF for loop through children
			

			// There is a "closest" object (in range too, implied).
			// Pick it to be the enemy.
			// Re-picking the same enemy as the enemy again
			// (still the closest since last time) is fine, no change here.
			if(objClosestYet != null){
				enemyObject = objClosestYet;
			}else{
				//drop the enemy.
				enemyObject = null;
			}

			//Do this enemy-check every second instead of every frame.
			//Not much is bound to change every single frame.
			nextLongThink = iron.system.Time.time() + 1.0;

		}//END OF nextLongThink

	}//END OF update


	public override function killed(){
		
		checkArcherCounts();

		// Now remove me.
		super.killed();

	}//END OF killed


	public function checkArcherCounts(){
		// Reduce one of the ai-controlled archer counts.
		switch(myFaction){
			case ALLY:
				CustomGame.currentAllyCount -= 1;
			case ENEMY:
				CustomGame.currentEnemyCount -= 1;
			case PLAYER:
				//???
			default:
				//???
		}//END OF switch(myFaction)
		trace("I HAPPENED. ENEMY LEFT: " + CustomGame.currentEnemyCount + " ALLY LEFT: " + CustomGame.currentAllyCount);
	}//END OF checkArcherCounts


	public function setExpirationTimer(arg_lifeTime){
		expirationTime = CustomLib.getCurrentTime() + arg_lifeTime;
	}




	#end

}//END OF class PersonAIObject
