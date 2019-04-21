package arm;


import iron.Scene;
import custom_lib.CustomLib;
import custom_lib.CustomGame;

import haxe.ds.Vector;
import iron.object.Transform;
import iron.math.Quat;
import iron.math.Vec4;
import iron.math.Mat4;
import iron.object.Object;

import iron.data.Armature;
import iron.data.SceneFormat.TObj;

import iron.object.Constraint;
import iron.data.SceneFormat.TConstraint;

import iron.object.Animation;
import iron.object.ObjectAnimation;
import iron.object.BoneAnimation;


// This trait must belong to the current scene and give the "arm.CustomObject" class to every object in the scene.
// A few don't need it but it's not much.  Doesn't do any frame-per-frame logic on its own, only stores extra data
// possibly needed by game objects.
class CustomGameInit extends iron.Trait {


	var newObject:Object;
	var matrices:Array<Mat4> = [];

	public function new() {
		super();

		// Perhaps this form is redundant, seeing how "this" trait must belong to the current scene?
		// Or maybe not. Strangely a Scene isn't a child of "Object", so having the same method is more of a 
		// coincidence.
		//...then what is the "object" attached to this script if it's supposed to be the "scene"?
		// ("iron.Scene.active" is the Scene instance)
		iron.Scene.active.notifyOnInit(init);
		//notifyOnInit(init);

		notifyOnUpdate(update);

		notifyOnRemove(removed);
	}//END OF new() function


	function init(){
		
		// NOTE: A scene can get any member of a collection as a child, but not a colleciton itself.
		//       Are collections only for organization in Blender and have nothing to do with
		//       the heirarchy as far as Armory (script / nodes / game logic) is concerned?
		
		trace("CUSTOMGAMEINIT...");
		trace("object.uid? " + this.object.uid);
		if(iron.Scene.active!=null){
			trace("iron.Scene.active.uid? " + " " + iron.Scene.active.uid);
			//trace(iron.Scene.active.children);
		}
		if(iron.Scene.global!=null){
			trace("iron.Scene.global.uid? " + " " + iron.Scene.global.uid);
			//trace(iron.Scene.global.children);
		}
		if(iron.Scene.active.root!=null){
			trace("iron.Scene.active.root.uid? " + " " + iron.Scene.active.root.uid);
			//trace(iron.Scene.active.root.children);
		}




		
		//Now wait a minute...
		/*
		
		var person_cylinder_template:Object = object.getChild("person_cylinder_template");
		var person_armature:Object = person_cylinder_template.getChild("person_armature");
		var anim:BoneAnimation = CustomLib.getArmatureAnimationOfObject(person_armature);

		var person_bow_mesh:Object = person_armature.getChild("person_bow_mesh");
		var animBow:ObjectAnimation = cast(person_bow_mesh.animation, ObjectAnimation);


		for(thisAct in anim.armature.actions){
			trace("ANIM NAME: " + thisAct.name);
		}
		
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





		


		/*
		
		var person_cylinder_template:Object = object.getChild("person_cylinder_template");
		//var person_cylinder_template:Object = Scene.active.root.getChild("person_cylinder_template");
		var person_armature:Object = person_cylinder_template.getChild("person_armature");
		var originalAnim:BoneAnimation = CustomLib.getArmatureAnimationOfObject(person_armature);
		//var armRef:Armature = CustomLib.getArmatureOfObject(person_armature);
		
		originalAnim.play("bow_backwaver", function done(){}, 0, 1, true);
		
		*/
		
		//var spawnLoc:Vec4 = new Vec4(person_cylinder_template.transform.loc.x, person_cylinder_template.transform.loc.y + 8, person_cylinder_template.transform.loc.z);
		
		
		/*
		var spawnLoc:Vec4 = new Vec4(0,0,6);
		for(i in -6...6){
			for(i2 in -6...6){
				
				var spawnLocGreater:Vec4 = new Vec4(spawnLoc.x + i2*9, spawnLoc.y + i*9, spawnLoc.z + 0);
				CustomLib.spawnObject(
					"person_cylinder_template", spawnLocGreater, person_armature.transform.rot.getEuler(), new Vec4(6,6,12.8), 
					function done(someObj:Object){
						//var person_armature:Object = someObj.getChild("person_armature");
						var person_armature:Object = CustomLib.getDirectChild(someObj, "person_armature");
						var armatureAnimSub:BoneAnimation = CustomLib.getArmatureAnimationOfObject(person_armature);
						armatureAnimSub.play("bow_backwaver");

						trace("WHAT ARE ME ANIMS");
						for(anim in armatureAnimSub.armature.actions){
							trace("whut " + anim.name);
						}

						//hide the cylinder collision zone.
						CustomLib.setObjectVisibility(someObj, false);

					}
				);


			}
		}
		*/
		






		/*
		var testarmature:Object = object.getChild("testarm");
		var armatureAnim:BoneAnimation = CustomLib.getArmatureAnimationOfObject(testarmature);
		armatureAnim.play("testarm_anim_test", function thingy(){}, 0, 1, true);
		

		var spawnLocTest:Vec4 = new Vec4(testarmature.transform.loc.x, testarmature.transform.loc.y + 12, testarmature.transform.loc.z);
		CustomLib.spawnObject(
			"testarm", spawnLocTest, testarmature.transform.rot.getEuler(), new Vec4(1,1,1), 
			function done(someObj:Object){
				var armatureAnimSub:BoneAnimation = CustomLib.getArmatureAnimationOfObject(someObj);
				armatureAnimSub.play("testarm_anim_test");
			}
		);
		*/
		

		/*
		CustomLib.spawnObject(
			"Suzanne.030", new Vec4(32, 0, 12), new Vec4(0, 0, 0), new Vec4(1,1,1), 
			function done(someObj:Object){
				var testinstanceA:CustomObject = new CustomObject();
				someObj.addTrait(testinstanceA);
				
			}
		);
		*/


		
		//for(thisChild in object.children){
		//	trace("AAA Child Name? " + thisChild.name);
		//}//END OF for loop through children

		// IMPORTANT - keep a clone of the children before adding any traits.
		// This cloned list, unaffected by deletions/additions of children
		// caused by the CustomObject's init script, will ensure more consistent
		// behavior. Otherwise, children in the list could be skipped or newly generated
		// ones could be covered instead (not the intention) as the children list is
		// changed in real time throughout the for loop.
		// Only entities placed from Blender itself should receive this CustomObject trait,
		// at least from the scene startup here (the initial state of object.children).
		// 
		//var childrenClone:Array<Object> = new Array<Object>();
		var childrenClone:Array<Object> = object.children.copy();
		

		//for(thisChild in object.children){
		for(thisChild in childrenClone){
			//trace("BBB Child Name? " + thisChild.name);
			
			var testinstance:CustomObject = new CustomObject();
			thisChild.addTrait(testinstance);
		}//END OF for loop through children


	}//END OF init



	public var deg:Float = 0;

	function update(){

		
		/*

		//return;

		var person_cylinder_template:Object = object.getChild("person_cylinder_template");
		//var person_cylinder_template:Object = Scene.active.root.getChild("person_cylinder_template");
		var person_armature:Object = person_cylinder_template.getChild("person_armature");
		var originalAnim:BoneAnimation = CustomLib.getArmatureAnimationOfObject(person_armature);
		var armRef:Armature = CustomLib.getArmatureOfObject(person_armature);
		
		//var someBone:TObj = originalAnim.getBone("");
		//someBone.transform.target

		trace("DEG: " + deg);
		deg = 0.6;
		//deg = 35;

		var tempQuat:Quat = new Quat();
		tempQuat.fromEuler(0, deg*(Math.PI/180), 0 );

		var theMat:Mat4 = Mat4.identity();
		theMat.compose(new Vec4(0,0,0), tempQuat, new Vec4(1,1,1)); 
		//theMat.setLookAt( theMat.getLoc(), 
		//rotateQuatByAxisAngle
		//matrix "compose" function
		//theMat.toRotation

		//getLookAngle

		CustomLib.moveBone(originalAnim, "spine_upper", theMat);
		
		*/


		
	}

	function removed(){

	}


}
