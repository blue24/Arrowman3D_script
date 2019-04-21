

package arm;

import custom_lib.CustomLib;
import custom_lib.CustomGame;


import zui.Canvas.TElement;
import armory.trait.internal.CanvasScript;
import armory.system.Event;

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
import arm.PersonAIObject;


// Child of Person that takes input from the user ("player"). No automatic behavior.
// Many remnants of FirstPersonController live on here (the user input parts and camera).
class PlayerObject extends PersonObject {

#if (!arm_physics)
		public function new() { super(); }
#else


	var topDownView:Bool = false;


	var lockingAllowed:Bool = true;



	//CONTROLS. Don't be afraid to point that out in a comment dude!  Those letters ain't gonna bite ya!
	#if arm_azerty
	static inline var keyUp = 'z';
	static inline var keyDown = 's';
	static inline var keyLeft = 'q';
	static inline var keyRight = 'd';
	static inline var keyStrafeUp = 'e';
	static inline var keyStrafeDown = 'a';
	#else
	static inline var keyUp = 'w';
	static inline var keyDown = 's';
	static inline var keyLeft = 'a';
	static inline var keyRight = 'd';
	static inline var keyStrafeUp = 'e';
	static inline var keyStrafeDown = 'q';
	#end

	// IN DEGREES!
	public static inline var cameraPitchMaxUp = 70;
	public static inline var cameraPitchMaxDown = -65;

	// IN RADIANS! and accounts for the odd camera rotation (add 90 degrees)
	public static var cameraPitchMaxUp_Absolute = (90 + cameraPitchMaxUp) * (Math.PI / 180);
	public static var cameraPitchMaxDown_Absolute = (90 + cameraPitchMaxDown) * (Math.PI / 180);


	public var canvas:CanvasScript = null;
	var ui_txtScore:TElement;
	var ui_txtHealth:TElement;

	public var score:Float = 0;

	//where to place the camera off of my origin before absorbing it into my heirarchy.
	public var cameraLocOffset:Vec4 = new Vec4(0, 0.97, 24.66/2);
	
	//Original value: 2.0
	public static inline var rotationSpeed:Float = 0.3; 


	public var camera:CameraObject = null;

	public function new(){
		super();
	}

	public override function spawned(arg_faction:Faction){

		super.spawned(arg_faction);

		canvas = CustomLib.getActiveScene().getTrait(CanvasScript);
		ui_txtScore = canvas.getElement("txtScore");
		ui_txtHealth = canvas.getElement("txtHealth");

		//Bring the world camera to me.
		var camera_container_ref:Object = iron.Scene.active.getChild("camera_player_container");
		if(camera_container_ref == null){
			trace("!!! CRITICAL ERROR. Player camera container not found, camera not attached!");
		}else{
			
			var vecForward:Vec4 = object.transform.look().normalize();
			trace("WHAT IS VECFORWARD " + vecForward);
			
			//camera_container_ref.transform.loc.set(object.transform.loc.x + cameraLocOffset.x * vecForward.x, object.transform.loc.y + cameraLocOffset.y * vecForward.y, object.transform.loc.z + cameraLocOffset.z);
			//camera_container_ref.transform.loc.set(object.transform.loc.x + 26 * vecForward.x, object.transform.loc.y + 26 * vecForward.y, object.transform.loc.z + cameraLocOffset.z);
			camera_container_ref.transform.loc.set(0,0,0);
			
			//camera_container_ref.transform.loc.set(object.transform.loc.x + cameraLocOffset.x, object.transform.loc.y + cameraLocOffset.y, object.transform.loc.z + cameraLocOffset.z);
			var myEuler:Vec4 = object.transform.rot.getEuler();
			//pitch, roll, yaw.
			camera_container_ref.transform.rot.fromEuler(0, 0, myEuler.z);
			// don't change scale. I think.

			camera_container_ref.transform.buildMatrix();

			//And attach the camera to me.
			CustomLib.setParent(camera_container_ref, this.object);

			//camera_container_ref.transform.loc.set(object.transform.loc.x + cameraLocOffset.x * vecForward.x, object.transform.loc.y + cameraLocOffset.y * vecForward.y, object.transform.loc.z + cameraLocOffset.z);
			//camera_container_ref.transform.loc.set(object.transform.loc.x, object.transform.loc.y, object.transform.loc.z);

			if(!topDownView){
				camera_container_ref.transform.loc.set(cameraLocOffset.x * vecForward.x / object.transform.scale.x, cameraLocOffset.y * vecForward.y / object.transform.scale.y, cameraLocOffset.z / object.transform.scale.z);
			}else{
				//move the camera slightly higher
				camera_container_ref.transform.loc.set(cameraLocOffset.x * vecForward.x / object.transform.scale.x, cameraLocOffset.y * vecForward.y / object.transform.scale.y, cameraLocOffset.z / object.transform.scale.z + 14);
			}
			camera_container_ref.transform.buildMatrix();
			

			//While we're at it, establish this then.
			//Interestingly enough, "getChild" does a recursive search too.  
			//Even if the camera is a child object's child object, it will catch it.
			camera = cast(camera_container_ref.getChild("camera_player"), CameraObject);
			trace("camera null? " + (camera!=null));

			//And start looking through the camera.
			if(camera!=null){
				CustomLib.setCameraFOV(camera, 0.8);

				var mouse = Input.getMouse();
				//start with the mouse locked.

				if(lockingAllowed){
					if(!mouse.locked) mouse.lock();
				}
				if(topDownView){
					//Make the camera look straight down
					camera.transform.rot.x = 0;
					camera.transform.buildMatrix();
				}
			}
			//Leave the active camera the way it is in the scene, may want to look at the player from 3rd person with another
			//camera set to active instead.
			//CustomLib.setActiveCamera(camera);
		}
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

		if (Input.occupied || (body!=null && !body.ready) ) return;

		var mouse = Input.getMouse();
		var kb = Input.getKeyboard();

		
		if (lockingAllowed && mouse.started() && !mouse.locked) mouse.lock();
		else if (kb.started("escape") && mouse.locked) mouse.unlock();
		
		
		if (mouse.locked || mouse.down()) {
			var headForward:Vec4 = camera.transform.look();
			var headUp:Vec4 = camera.transform.up();
			var headRight:Vec4 = camera.transform.right();
			
			var rotateAmount_x:FastFloat = -mouse.movementX / 250 * rotationSpeed;
			var rotateAmount_y:FastFloat = -mouse.movementY / 250 * rotationSpeed;

			//!!! This is the entire object rotating left/right, or floor-wise from a top-down view.
			object.transform.rotate(zVec, rotateAmount_x);

			var cameraEuler:Vec4 = camera.transform.rot.getEuler();
			var newCameraPitch = cameraEuler.x + rotateAmount_y;

			if(!topDownView){
				//pitch adjustments not allowed in topdown view.
				if(newCameraPitch > cameraPitchMaxUp_Absolute){
					//rotateAmount_y = (cameraPitchMaxUp_Absolute - cameraEuler.x);
					camera.transform.rot.fromEuler(cameraPitchMaxUp_Absolute, cameraEuler.y, cameraEuler.z);
					camera.transform.buildMatrix();
				}else if(newCameraPitch < cameraPitchMaxDown_Absolute){
					//rotateAmount_y = (cameraPitchMaxDown_Absolute - cameraEuler.x);
					camera.transform.rot.fromEuler(cameraPitchMaxDown_Absolute, cameraEuler.y, cameraEuler.z);
					camera.transform.buildMatrix();
				}else{
					if(Math.abs(rotateAmount_y) > 0.001){
						camera.transform.rotate(xVec, rotateAmount_y);
					}
				}

			}

			if(body != null){
				body.syncTransform();
			}
			object.transform.buildMatrix();

		}//END OF mouse.locked and mouse.down checks


	}//END OF preUpdate



	public override function update(){
		if(!spawnCalled)return;
		
		// Collect inputs from the keyboard for movement. The PersonObject's parent method can apply this.
		var keyboard = Input.getKeyboard();
		var mouse = Input.getMouse();
		moveForward = keyboard.down(keyUp);
		moveRight = keyboard.down(keyRight);
		moveBackward = keyboard.down(keyDown);
		moveLeft = keyboard.down(keyLeft);
		jump = keyboard.started("space");

		//If the player holds own the left mouse button, firing is desired.
		fireArrowIntent = mouse.down("left");

		super.update();

		//Is this a good idea?  The firstpersoncontroller did it, no idea what it does.
		camera.buildMatrix();

		if(ui_txtScore!=null){
			ui_txtScore.text = "Score: " + this.score;
		}
		if(ui_txtHealth!=null){
			ui_txtHealth.text = "Health: " + this.currentHealth + " / " + this.getMaxHealth();
		}

	}//END OF update

	//include the camera. The user wants an arrow to come from where they're looking.
	public override function getArrowFirePoint():Vec4{
		var myLoc:Vec4 = object.transform.loc;
		
		if(camera==null)return myLoc; //how.

		//var myLoc:Vec4 = object.transform.loc;
		var myForward:Vec4 = object.transform.look().normalize();

		//this gets the "forward" direction of the camera... okay.
		var cameraForward:Vec4 = camera.transform.up().normalize();

		cameraForward.x *= -1;
		cameraForward.y *= -1;
		cameraForward.z *= -1;

		return new Vec4(myLoc.x + 8 * myForward.x, myLoc.y + 8 * myForward.y, myLoc.z + cameraLocOffset.z + cameraForward.z * 15);
		//return new Vec4(myLoc.x, myLoc.y, myLoc.z);
	}//END OF getArrowFirePoint

	public override function getYawAngle():Float{
		return object.transform.rot.getEuler().z;
	}
	public override function getPitchAngle():Float{
		if(camera==null)return 0; //how.

		if(!topDownView){
			//use the camera instead, it's looking around.
			return camera.transform.rot.getEuler().x;
		}else{
			//can't control this in topdown view.
			return (90*(Math.PI/180));
		}
	}
	
	//defaults.
	public override function getMaxHealth():Float{
		return 100;
	}
	public override function getReloadTime():Float{
		return 0.17;
	}
	public override function getAutoHealAmount():Float{
		return 4;
	}

	public override function takeDamage(arg_damage:Float){
		currentHealth -= arg_damage;
		if(currentHealth <= 0){
			//change scenes. goodbye.
			CustomGame.endGame(false, this.score);
		}
	}//END OF takeDamage


#end

}//END OF class PlayerObject




