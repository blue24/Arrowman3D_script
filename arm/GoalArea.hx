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


class GoalArea extends iron.Trait {

	public var checkmark_meshRef:Object;
	public var rigidBodyTrait:RigidBody;
	public var physics:PhysicsWorld;

	public function new() {
		super();
		notifyOnInit(init);
		notifyOnUpdate(update);
	}

	function init(){
		checkmark_meshRef = object.getChild("checkmark_mesh");
		
		rigidBodyTrait = object.getTrait(RigidBody);
		physics = armory.trait.physics.PhysicsWorld.active;

	}
	function update(){
		//rotate passively.
		checkmark_meshRef.transform.rotate(new Vec4(0, 0, 1), 0.011);

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
	}//END OF update

}
