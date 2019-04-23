package arm;


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


import custom_lib.CustomLib;
import custom_lib.CustomGame;


@:enum abstract AppearCondition(Int) from Int to Int{
    var ALWAYS = 0;
    var REMOVE_ALL_ENEMIES = 1;
    var REMOVE_NEARBY_ENEMIES = 2;
}

class GoalArea extends iron.Trait {

	public var myAppearCondition:AppearCondition = AppearCondition.ALWAYS;

	public var checkmark_meshRef:Object;
	public var rigidBodyTrait:RigidBody;
	public var physics:PhysicsWorld;

	var nextNearbyCheck:Float = 0;


	public function new() {
		super();
		notifyOnInit(init);
		notifyOnUpdate(update);
	}

	function init(){
		checkmark_meshRef = CustomLib.getDirectChild(object, "checkmark_mesh");
		
		rigidBodyTrait = object.getTrait(RigidBody);
		physics = armory.trait.physics.PhysicsWorld.active;


		//The object receiving the goal is the cube collider. Hide it.
		CustomLib.setObjectVisibility(object, false);
		

		var Goal_RemoveAllEnemiesConditionTest:Goal_RemoveAllEnemiesCondition = object.getTrait(Goal_RemoveAllEnemiesCondition);
		var Goal_RemoveNearbyEnemiesConditionTest:Goal_RemoveNearbyEnemiesCondition = object.getTrait(Goal_RemoveNearbyEnemiesCondition);
		
		if(Goal_RemoveAllEnemiesConditionTest != null){
			myAppearCondition = AppearCondition.REMOVE_ALL_ENEMIES;
			CustomLib.setObjectVisibility(checkmark_meshRef, false);
		}else if(Goal_RemoveNearbyEnemiesConditionTest != null){
			nextNearbyCheck = CustomLib.getCurrentTime() + 2;
			myAppearCondition = AppearCondition.REMOVE_NEARBY_ENEMIES;
			CustomLib.setObjectVisibility(checkmark_meshRef, false);
		}else{
			//start visible then.
			myAppearCondition = AppearCondition.ALWAYS;
			CustomLib.setObjectVisibility(checkmark_meshRef, true);
		}

	}
	function update(){
		//rotate passively.
		checkmark_meshRef.transform.rotate(new Vec4(0, 0, 1), 0.011);


		if(myAppearCondition == AppearCondition.ALWAYS){
			// Allowed to show the goal and check for collisions for ending the game.
			if(rigidBodyTrait != null){
				var rbs:Array<RigidBody> = physics.getContacts(rigidBodyTrait);
				if (rbs != null) {
					//var individua:armory.trait.physics.bullet.RigidBody = rbs[0];
					for (rb in rbs){
						if(rb.object != null){
							var playerTraitTest:PlayerObject = rb.object.getTrait(PlayerObject);
							if(playerTraitTest != null){
								//the player touched me and has won the game. Move to the end screen.
								CustomGame.endGame(true, playerTraitTest.score);
							}
						}
					}
				}
			}//END OF rigidBodyTrait check

		}else if(myAppearCondition == AppearCondition.REMOVE_ALL_ENEMIES){
			//is the global count of enemies 0 yet?
			if(CustomGame.currentEnemyCount <= 0){
				//proceed.
				myAppearCondition = AppearCondition.ALWAYS;
				CustomLib.setObjectVisibility(checkmark_meshRef, true);
				CustomGame.playerRefTrait.goalVisibleNotice();  //let the player know the goal appeared.
			}
		}else if(myAppearCondition == AppearCondition.REMOVE_NEARBY_ENEMIES){

			if(CustomLib.getCurrentTime() > nextNearbyCheck){
				// The current time has passed the nextNearbyCheck time? Reset that and do another check.
				
				nextNearbyCheck = CustomLib.getCurrentTime() + 2;

				var isEnemyNearby:Bool = false;  //see if I'm proven wrong?
				var theScene:iron.Scene = CustomLib.getActiveScene();
				
				for(thatChild in theScene.root.children){
					var personAI_TraitTest:PersonAIObject = thatChild.getTrait(PersonAIObject);
					if(personAI_TraitTest != null){
						if(personAI_TraitTest.myFaction == Faction.ENEMY){
							var theDist:Float = CustomLib.getDistance(object.transform.loc, thatChild.transform.loc);
							if(theDist < 300){
								//won't work.
								isEnemyNearby = true;
								break;
							}
						}
					}
				}//END OF for each object in the scene

				if(!isEnemyNearby){
					//success.
					myAppearCondition = AppearCondition.ALWAYS;
					CustomLib.setObjectVisibility(checkmark_meshRef, true);
					CustomGame.playerRefTrait.goalVisibleNotice();  //let the player know the goal appeared.
				}
				
			}//END OF time check

		}//END OF condition check if-then chain



	}//END OF update

}
