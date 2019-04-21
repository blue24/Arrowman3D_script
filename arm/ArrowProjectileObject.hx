


package arm;


import arm.CustomObject;

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
import iron.object.Transform;
import iron.object.Animation;
import armory.trait.physics.PhysicsWorld;
import armory.trait.physics.RigidBody;
import armory.trait.internal.CameraController;
import armory.trait.internal.CanvasScript;


import armory.trait.physics.bullet.RigidBody.ActivationState;


import iron.data.MaterialData;
import iron.object.MeshObject;

import kha.FastFloat;




class ArrowProjectileObject extends iron.Trait {

	public static inline var arrowSpeed:Float = 1300;
	public static inline var arrowDamage:Float = 6;
	public static inline var beginDropTime_Setting:Float = 1.2;
	public static inline var maxLifeTime:Float = 10;
	
	public var myFaction:Faction = Faction.UNSET;

	public var body:RigidBody = null;
	public var physics:armory.trait.physics.PhysicsWorld;

	public var spawnCalled:Bool = false;

	//After hitting something unable to be damaged like the ground, how long do I stay before removing myself?
	public var removeHitDelay:Float = 0;

	//After how long since being fired do I start to tilt down?
	public var beginDropTime:Float = 0;
	//After how long, unconditionally, do I delete myself?
	public var lifeTime:Float = 0;


	public function new() {
		super();
		setupEventLinks();
	}

	public function setupEventLinks(){
		PhysicsWorld.active.notifyOnPreUpdate(preUpdate);
		notifyOnUpdate(update);
		notifyOnRemove(removed);
	}//END OF setupEventLinks

	public function removePreUpdateLink(){
		PhysicsWorld.active.removePreUpdate(preUpdate);
	}



	public function spawned(arg_faction:Faction){

		myFaction = arg_faction;
		
		body = object.getTrait(RigidBody);
		physics = armory.trait.physics.PhysicsWorld.active;


		//Start with gravity off actually.  It will apply after "beginDropTime" is reached.
		//body.enableGravity();
		body.disableGravity();

		
		body.body.setActivationState( ActivationState.Active);
		
		var vecForward:Vec4 = object.transform.look().normalize();

		body.setLinearVelocity(vecForward.x * arrowSpeed, vecForward.y * arrowSpeed, vecForward.z * arrowSpeed );

		// little variation for fun.
		beginDropTime = iron.system.Time.time() + beginDropTime_Setting + CustomLib.getRandomFloat(0, 0.26);
		lifeTime = iron.system.Time.time() + maxLifeTime;


		var arrowMat:String = CustomGame.aryStr_resource_arrow_materialList[ myFaction ];
		CustomLib.getMaterial(arrowMat,
			function(mat:MaterialData){
				if(object!=null){
					CustomLib.setTexturesFromMaterial_obj(object, mat);
				}
			}
		);




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

		if(body != null && removeHitDelay == 0){
			var rbs:Array<RigidBody> = physics.getContacts(body);

			if (rbs != null) {
				//var individua:armory.trait.physics.bullet.RigidBody = rbs[0];
				for (rb in rbs){

					if(rb.object != null){
						var tempRef:CustomObject = rb.object.getTrait(CustomObject);
						//Does the thing I hit have the PeronAIObject or PlayerObject traits?
						var personAIObjectTrait:PersonAIObject = rb.object.getTrait(PersonAIObject);
						var playerObjectTrait:PlayerObject = rb.object.getTrait(PlayerObject);
						var arrowProjectileObjectTrait:ArrowProjectileObject = rb.object.getTrait(ArrowProjectileObject);
						
						var rigidBodyTrait:RigidBody = rb.object.getTrait(RigidBody);
						var isOtherTrigger:Bool = false;
						var passThroughException:Bool = false;

						if(rigidBodyTrait != null){
							isOtherTrigger = ((rigidBodyTrait.body.getCollisionFlags() & 4) != 0);
						}

						passThroughException = (!rb.object.visible);

						//if(tempRef != null && tempRef.arrowsPassThrough){
						//	passThroughException = true;
						//}
						
						var personObjectTrait:PersonObject = null;
						if(playerObjectTrait != null){
							personObjectTrait = playerObjectTrait;
						}else if(personAIObjectTrait != null){
							personObjectTrait = personAIObjectTrait;
						}

						if(personObjectTrait != null){
							//What is their faction. Do I hate them?
							var playerDealt = (myFaction==Faction.PLAYER&&personObjectTrait.myFaction!=Faction.PLAYER);
							if(playerDealt || CustomGame.factionHates(myFaction, personObjectTrait.myFaction)){
								//do damage, delete self.
								personObjectTrait.takeDamage( arrowDamage);

								//last hit?
								if(personObjectTrait.currentHealth <= 0 && playerDealt){
									//is it friendly fire or not?
									if(personObjectTrait.myFaction == Faction.ENEMY){
										CustomGame.playerRefTrait.score += 10;
									}else if(personObjectTrait.myFaction == Faction.ALLY){
										CustomGame.playerRefTrait.score -= 20;
									}
								}

								object.remove();
								return;
							}
						}else if(arrowProjectileObjectTrait != null || isOtherTrigger || passThroughException ) {
							//other arrows, invisible bounds or the goal area? ignore.
						}else{
							// Hit anything else, marked ground or not?
							// stick in the ground for a little. LinearFactor of all 0's locks this in place. Same for angular.
							body.setLinearFactor(0, 0, 0);
							body.setAngularFactor(0, 0, 0);
							body.disableGravity();
							body.setLinearVelocity(0, 0, 0);
							body.setAngularFactor(0, 0, 0);
							removeHitDelay = iron.system.Time.time() + 3;
						}
					}//END OF rb.object null check
				}//END OF for each object collided with this frame
			} else {
				//obj.visible = false;
			}

			if(beginDropTime != 0){

				if(beginDropTime <= iron.system.Time.time()){
					beginDropTime = 0;
					body.enableGravity();
					body.setAngularFactor(0, 0, 0);
					body.setGravity(new Vec4(0, 0, -45));
				}
			}else{
				//if beginDropTime is 0, that means it has already passed.
				//Face whatever direction we're moving since gravity applied.
				//And damper the floorwise velocity a bit.

				
				var myVel:Vec4 = body.getLinearVelocity();
				/*
				var myNewVel:Vec4 = new Vec4(myVel.x * 0.992, myVel.y * 0.992, myVel.z + -0.03);
				body.setLinearVelocity(myNewVel.x,  myNewVel.y, myNewVel.z);
				*/
				if(myVel.length() > 20){
					/*
					var vecFrom:Vec4 = object.transform.loc;
					var vecTo:Vec4 = new Vec4(object.transform.loc.x + myVel.x, object.transform.loc.y + myVel.y, object.transform.loc.z + myVel.z );
					//face the way of myNewVel.
					var vecLook:Vec4 = CustomLib.getLookAngle(vecFrom, vecTo);
					object.transform.setRotation(vecLook.x, vecLook.y, vecLook.z);
					*/
					body.syncTransform();
				}
			}//END OF beginDropTime check
		}//END OF body null check and removeHitDelay check

		if(removeHitDelay != 0 && removeHitDelay <= iron.system.Time.time()){
			//remove.
			object.remove();
			return;
		}

		if(lifeTime <= iron.system.Time.time()){
			object.remove();
			return;
		}

	}//END OF update

}//END OF class ArrowProjectileObject
