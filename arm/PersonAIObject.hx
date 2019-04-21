



package arm;


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



	public override function spawned(arg_faction:Faction){
		super.spawned(arg_faction);
		

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

			_pitch = lookAng.x;

			object.transform.rot = thatQuat;
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
							var distTo:Float = new Vec4(otherLoc.x - myLoc.x, otherLoc.y - myLoc.y, otherLoc.z - myLoc.z).length();
							//trace("DIST TO? " + distTo);
							if(distTo < bestDistanceYet){
								bestDistanceYet = distTo;
								objClosestYet = thisChild;
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


	#end

}//END OF class PersonAIObject
