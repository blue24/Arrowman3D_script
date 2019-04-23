package arm;


import haxe.ds.Vector;
import custom_lib.CustomLib;
import custom_lib.CustomGame;

import iron.math.Vec4;
import iron.object.Object;


import iron.data.MaterialData;
import iron.object.MeshObject;

import armory.trait.physics.RigidBody;

import iron.object.BoneAnimation;




class CustomObject extends iron.Trait {

	public var _isGround:Bool = false;

	public function new(){
		super();

		notifyOnAdd(added);

	}


	public function added(){


		//not that this should be an issue.
		if(object != null){

			var templateObjectTest:TemplateObject = object.getTrait(TemplateObject);
			if(templateObjectTest != null){
				//see if I have a rigidbody, turn it off if so.
				var rigidBodyTest:RigidBody = object.getTrait(RigidBody);
				if(rigidBodyTest != null){
					trace("***TEMPLATE FOUND: " + object.name);
					rigidBodyTest.disableGravity();
				}
				// Remove this trait, no need to show up on any objects cloned from this template.
				// Any difference between these two ways to delete a trait?
				// Doing it from the object's end for safety.
				// or... maybe both?
				object.removeTrait(templateObjectTest);
				templateObjectTest.remove();


				var animationPlayer:BoneAnimation = null;
				//var armatureTest:iron.object.Object = object.getChild("person_armature");
				var armatureTest:iron.object.Object = CustomLib.getDirectChild(object, "person_armature");

				//var otherTest:BoneAnimation = object.getParentArmature("person_armature");

				if(armatureTest != null){
					//animationPlayer = cast(armatureTest.animation, BoneAnimation);

					/*
					var someAnim:BoneAnimation = CustomLib.getArmatureAnimationOfObject(armatureTest);
					trace("PLEASE BE HEREEEEE " + (someAnim!=null));

					someAnim.play("anim_bow_waver", function(){}, 0, 1.0, true);
					*/
					
					//armatureTest.setupAnimation()

					

//////////////////////////////////////////

				/*
				var daMesh:Object = armatureTest.getChild("person_mesh");
				trace("person_armature null? " + (daMesh.getParentArmature("person_armature")!=null) );

				//animationPlayer = cast(object.getChild("person_armature").animation, BoneAnimation);
				animationPlayer = daMesh.getParentArmature("person_armature");


				
				trace("PRINT ARRAY AHHH!!!");
				for(acto in animationPlayer.armature.actions){
					trace(acto.name);
				}
				*/
				
//////////////////////////////////////////
				}




/*
				if(animationPlayer != null){
					
					animationPlayer.play(
						"bow_backwaver",
						function onComplete(){

						},
						0, 1, true
					);
					
				}
*/

			}//END OF TemplateObject trait check

			if(object.getTrait(MARKER_spawnEnemy) != null){

				if(!custom_lib.CustomGame.canSpawnThings)return;
				
				//This entity is marked to be replaced by an enemy (PersonAI, enemy diplomacy)
				//NOTICE: does not automatically set the scale to that of the target object to start, have to hardcode that for now.
				//ex: even if the template has a scale of (0.3,0.3,0.3), spawning it starts the clone with a scale of (1,1,1).
				//    An option to start from the template's scale would be nice.
				CustomLib.spawnObject_quat(CustomGame.currentSceneName + "_" + "person_cylinder_template", object.transform.loc, object.transform.rot, new Vec4(6, 6, 12.8),
					function(o:Object){
						
						//that's another enemy.
						CustomGame.currentEnemyCount += 1;
						
						//Create the relevant trait and customize if necessary.
						var traitGen:PersonAIObject = new PersonAIObject();
						o.addTrait(traitGen);
						traitGen.spawned(Faction.ENEMY);
						
						
						
						//Why are the monkeys facing backwards? who knows. Correcting.
						o.transform.rotate(new Vec4(0,0,1), 180*(Math.PI/180) );
						CustomLib.snapToGround(o);
						o.transform.buildMatrix();
						o.getTrait(RigidBody).syncTransform();
						

						
						
						//iron.system.Tween.timer(5.0,
						//	function(){
								//object.remove();

								/*
								var person_armature:Object = CustomLib.getDirectChild(o, "person_armature");
								var armatureAnim:BoneAnimation = CustomLib.getArmatureAnimationOfObject(person_armature);
								armatureAnim.play(
									"bow_backwaver", function eee(){}, 0, 1.0, true
								);
								*/


						//	}
						//);



					}, null, true
				);
				
				//object.visible = false;
				//object.visibleMesh = false;
				//object.visibleShadow = false;
				CustomLib.setObjectVisibility(object, false);

				//Delete this object with a delay since this is early on when things are being loaded in some linear list.
				//Deleting things could cause some entities in the list (all of the scene's children).
				//UPDATE: This delay is no longer necessary. Now using a clone of the child list made 
				//        before adding any traits so that additions/deletions to the child list
				//        while the for-loop is running do not affect what entities are picked.
				//iron.system.Tween.timer(5.0,
				//	function(){
						object.remove();
				//	}
				//);

				//this results in deleting the currently attached entity, so stop the method.
				return;
			}//END OF MARKER_spawnEnemy check

			if(object.getTrait(MARKER_spawnAlly) != null){
				
				if(!custom_lib.CustomGame.canSpawnThings)return;

				CustomLib.spawnObject_quat(CustomGame.currentSceneName + "_" + "person_cylinder_template", object.transform.loc, object.transform.rot, new Vec4(6, 6, 12.8),
					function(o:Object){
						
						//that's another ally.
						CustomGame.currentAllyCount += 1;

						//Create the relevant trait and customize if necessary.
						var traitGen:PersonAIObject = new PersonAIObject();
						o.addTrait(traitGen);
						traitGen.spawned(Faction.ALLY);

						
						//Why are the monkeys facing backwards? who knows. Correcting.
						o.transform.rotate(new Vec4(0,0,1), 180*(Math.PI/180) );
						CustomLib.snapToGround(o);
						o.transform.buildMatrix();
						o.getTrait(RigidBody).syncTransform();

					}, null, true
				);

				//trace("Ya? A1");
				CustomLib.setObjectVisibility(object, false);
				//trace("Ya? A2");
				object.remove();
				
				//this results in deleting the currently attached entity, so stop the method.
				return;
			}//END OF MARKER_spawnAlly check


			if(object.getTrait(MARKER_spawnPlayer) != null){
				
				CustomLib.spawnObject_quat(CustomGame.currentSceneName + "_" + "person_cylinder_template", object.transform.loc, object.transform.rot, new Vec4(6, 6, 12.8),
					function(o:Object){
						
						//Create the relevant trait and customize if necessary.
						var traitGen:PlayerObject = new PlayerObject();
						o.addTrait(traitGen);
						traitGen.spawned(Faction.PLAYER);

						//Why are the monkeys facing backwards? who knows. Correcting.
						o.transform.rotate(new Vec4(0,0,1), 180*(Math.PI/180) );
						CustomLib.snapToGround(o);

						o.transform.buildMatrix();
						o.getTrait(RigidBody).syncTransform();

						CustomGame.playerRef = o;
						CustomGame.playerRefTrait = traitGen;

					}, null, true
				);
				
				CustomLib.setObjectVisibility(object, false);
				
				object.remove();

				//this results in deleting the currently attached entity, so stop the method.
				return;
			}//END OF MARKER_spawnPlayer check

			var groundObjectTrait:GroundObject = object.getTrait(GroundObject);
			if(groundObjectTrait != null ){
				//this is meant to count as ground, mark it so.
				_isGround = true;
				//and no need to keep the trait around.
				object.removeTrait(groundObjectTrait);
				groundObjectTrait.remove();
			}//END OF GroundObject check
			
		}//END OF object null check
	}//END OF added

	public function isGround(){
		return _isGround;
	}

}
