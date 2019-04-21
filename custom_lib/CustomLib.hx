package custom_lib;


import iron.math.Quat;
import iron.math.Vec4;
import iron.math.Mat4;


import iron.Scene;
import iron.App;
import iron.system.Time;
import armory.system.Event;

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


import haxe.ds.Vector;
import iron.Trait;
import iron.object.*;
import iron.data.*;
import iron.data.SceneFormat;



import iron.data.MaterialData;
import iron.object.MeshObject;
import iron.object.CameraObject;



//Custom trait.
import arm.CustomObject;



// This class has several static utility methods to act as one place for several commonly needed features
// across Armory, such as spawning objects, changing the scene, or setting an object's material.
// Copying all the script from a logic node script and fitting it to a new scenario can be error-prone. 
// Do it right once and make it a method here.

class CustomLib{
	

	//based off the "BoneFKNode" logic node.
	public static function moveBone(arg_armatureAnim:BoneAnimation, arg_boneName:String, arg_newTransformMat:Mat4){
		var bone:TObj = arg_armatureAnim.getBone(arg_boneName);
		var notified = false;
		var m:Mat4 = null;
		var w:Mat4 = null;
		var iw = Mat4.identity();

		//arg_newTransformMat.


		//arg_armatureAnim.getBoneMatBlend(
		
		m = arg_armatureAnim.getBoneMat(bone);
		w = arg_armatureAnim.getAbsMat(bone);
		
		

		//function moveBone() {
			/*
			m.setFrom(w);
			m.multmat(arg_newTransformMat);
			iw.getInverse(w);
			m.multmat(iw);
			*/
			//m.setFrom(w);
			//m.multmat(arg_newTransformMat);
			//iw.getInverse(w);
			//m.multmat(iw);
			
			m.multmat(arg_newTransformMat);
			
			

				
				/*
				var matBlend = arg_armatureAnim.getBoneMatBlend(bone);
				if(matBlend != null){
					matBlend.setFrom(arg_newTransformMat);
					trace("matBlend??");
				}
				*/

			
			///trace("whut " + w);

			// anim.removeUpdate(moveBone);
			// notified = false;
		//}

		/*
		if (!notified) {
			arg_armatureAnim.notifyOnUpdate(moveBone);
			notified = true;
		}
		*/
	}//END OF moveBone












	public static var tempQ = new Quat();

	

	// WOW. Scene's method "getParentArmature"'s name is a bit misleading
	// It does not get the Armature itself, which is separate of Objects and animations entirely,
	// but fetches the animation that is linked(?) to an armature of the given name.
	// And on top of that, the parent of the current object in question plays no role in the
	// lookup.
	// A global list of animations is searched to see which one is associated with the correctly
	// named armature. This method may as well be named, "getAnimationFromNamedObject". And
	// be static instead then. And why make the parameter's name "name" just like an instance
	// variable of object already is? GAH.

	// Anyways, this method will get the animation associated with a given armature.
	// Or skip that and give it an object instead with the method further below.
	public static function getArmatureAnimationOfArmature(arg_arm:Armature) : BoneAnimation{
		for(thisAnimation in Scene.active.animations){
			if(thisAnimation.armature != null){
				if(thisAnimation.armature.uid == arg_arm.uid){
					//match? good. This is the animation we want.
					return cast(thisAnimation, BoneAnimation);
				}
			}
		}
		return null;
	}//END OF getAnimationOfArmature

	// Little transitive relationship here.
	// Since we know an armature connected to an object has the same "uid" number as the object,
	// and an animation whose armature's "uid" matches that of a target armature is the right
	// animation, we know an animation whose armature uid matches that of an object, belongs
	// to that object as well.  I think.
	public static function getArmatureAnimationOfObject(arg_obj:Object) : BoneAnimation{
		for(thisAnimation in Scene.active.animations){
			if(thisAnimation.armature != null){
				if(thisAnimation.armature.uid == arg_obj.uid){
					//match? good. This is the animation we want.
					return cast(thisAnimation, BoneAnimation);
				}
			}
		}
		return null;
	}//END OF getAnimationOfArmature

	// What armature is connected to the given object?
	// ...Why don't all objects have some "armature" instance variable pointer to directly
	// find this like "animation"?  No idea.
	// Script borrowed from Scene's "createObject" method for mesh objects.
	public static function getArmatureOfObject(arg_obj:Object) : Armature{
		var armatures:Array<Armature> = Scene.active.armatures;
		
		//Counting from the end to the front instead because it's more likely we're doing this
		//shortly after creating a new object. The newly created armature is most likely to
		//occur near the end of the list.
		//for(thisArmature in armatures){
		var i:Int = armatures.length - 1;
		while(i >= 0){
			var thisArmature:Armature = armatures[i];
		    if(thisArmature.uid == arg_obj.uid){
				return thisArmature;
			}
			i--;
		}
		//didn't find one.
		return null;
	}//END OF getArmatureOfObject
	

	// This method is similar to any object's getChild method, but only scans for direct children
	// of the given object (nonrecursive; not including the children's children or deeper), and
	// also checks for a child with an automatic name appended at the end of its name.
	// In clones of objects, new objects of the child sometimes also get names with new unique
	// numbers appended to the end, separated by a period.
	// Example: a clone of object "person_cylinder_template" with child "person_armature"
	// may have the name "person_cylinder_template.001" and its child may be named
	// "person_armature.001".
	// This means, on any clone told to check for children, it will fail to find
	// the "person_armature" child because it occurs with that ".001" in the name: inexact match.
	// This method allows a name that only differs by that period section.
	// IN SHORT, for this to work right, don't use periods in manually given names. Anything
	// after the last period in a name gets ignored as far as this method is concerned.
	// A recursive version of this could be supported but there doesn't seem to be a need
	// yet.
	public static function getDirectChild(arg_obj:Object, arg_strSearchName:String):Object{
		for(thisChild in arg_obj.children){
			var filteredName:String;
			var periodPos:Int = thisChild.name.indexOf(".");

			if(periodPos != -1){
				//cut out the numbered portion
				filteredName = thisChild.name.substring(0, periodPos);
			}else{
				//no period, nothing to cut.
				filteredName = thisChild.name;
			}
			if(filteredName == arg_strSearchName){
				//this is the child we want, auto-numbered or not.
				return thisChild;
			}
		}//END OF children for-loop

		//Didn't return a child of that name? Failure.
		return null;
	}//END OF getDirectChild_nameStartsWith

	public static function snapToGround(arg_obj:Object){

		var rayCastResult = armory.trait.physics.PhysicsWorld.active.rayCast(arg_obj.transform.loc, new Vec4(arg_obj.transform.loc.x, arg_obj.transform.loc.y, arg_obj.transform.loc.z - 600 )  );
		//trace("rayCastResult? " + (rayCastResult!=null) );
		if(rayCastResult != null){
			if(rayCastResult.object != null){
				var pointHit:Vec4 = armory.trait.physics.PhysicsWorld.active.hitPointWorld;
				arg_obj.transform.loc = new Vec4(arg_obj.transform.loc.x, arg_obj.transform.loc.y, pointHit.z + 12 + 2.4);
				arg_obj.transform.buildMatrix();
				var rigidBodyTest = rayCastResult.object.getTrait(RigidBody);
				if(rigidBodyTest!=null){
					rigidBodyTest.syncTransform();
				}
			}
		}
		
	}//END OF snapToGround

	//logic node, sortof. This also includes "visibleMesh" and "visibleShadow".
	public static function setObjectVisibility(arg_obj:Object, arg_visible:Bool){
		arg_obj.visible = arg_visible;
		arg_obj.visibleMesh = arg_visible;
		arg_obj.visibleShadow = arg_visible;
	}//END OF setEntityVisibility

	//logic node.
	public static function playSound(arg_soundPath:String){
		iron.data.Data.getSound(arg_soundPath, function(sound:kha.Sound){
			iron.system.Audio.play(sound, false, false);
		});
	}//END OF playSound

	public static function setObjectScale(arg_obj:Object, arg_vecScale:Vec4){
		arg_obj.transform.scale.setFrom(arg_vecScale);
		arg_obj.transform.buildMatrix();
		#if arm_physics
		var rigidBody = arg_obj.getTrait(RigidBody);
		if (rigidBody != null) rigidBody.syncTransform();
		#end
	}//END OF setObjectScale

	//logic node.
	public static function setParent(arg_objChild:Object, arg_objParent:Object){
		if(arg_objChild.parent == arg_objParent){
			//shouldn't do this. already its parent.
			return;
		}
		var parent:Object;
		var isUnparent = false;

		// ok then.
		isUnparent = (arg_objParent == iron.Scene.active.root);
		
		if(arg_objChild.parent != null){
			//didn't have a objChild.parent null check in the original node? huh.
			arg_objChild.parent.removeChild(arg_objChild, isUnparent); // keepTransform
			arg_objParent.addChild(arg_objChild, !isUnparent); // applyInverse
		}
	}//END OF setParent

	//logic node.
	public static function clearParent(arg_objChild:Object, arg_keepTransform:Bool){
		if(arg_objChild.parent == null){
			//no parent already, nevermind.
			return;
		}
		arg_objChild.parent.removeChild(arg_objChild, arg_keepTransform);
		iron.Scene.active.root.addChild(arg_objChild, false);
	}//END OF clearParent

	public static function changeScene(arg_newSceneName:String, arg_funDone:Object->Void){
		iron.Scene.setActive(arg_newSceneName, function(o:Object){
			arg_funDone(o);
		});
	}//END OF changeScene

	//logic node, "look at".  Find what angles would look at a vector from A to B.
	//NOTICE - abandoning the logic node, using my own implementation. That one just isn't working.
	// Going for treating it as a floor-wise angle (from x & y difference), and a pitch angle. No roll.
	public static function getLookAngle(vfrom:Vec4, vto:Vec4):Vec4{
		/*
		var v1:Vec4 = new Vec4();
		var v2:Vec4 = new Vec4();
		var q:Quat = new Quat();

		v1.set(0, 0, 1);

		v2.setFrom(vto).sub(vfrom).normalize();
		
		q.fromTo(v1, v2);
		return q.getEuler();
		*/


		// The floor angle (yaw) is best visualized from a top-down view. What angle will let me face the 
		// target this way?
		var vecDelta:Vec4 = new Vec4(vto.x - vfrom.x, vto.y - vfrom.y, vto.z - vfrom.z);
		// why the -90 degree offset?  Engines be wack, yo.
		var yawAng:Float = Math.atan2(vecDelta.y, vecDelta.x) - 90*(Math.PI/180);

		// The pitch angle is best viewed sideways.  Form a triangle with one perpendicular line on the bottom (flat against the ground),
		// and the 2nd perpendicular line going up to the target.  What is this angle, treating the floor-wise length as "x"
		// and the height line as "y"?
		//(built-in tools... what are those)
		var floorLength = Math.sqrt(vecDelta.x*vecDelta.x + vecDelta.y*vecDelta.y);
		var pitchAng:Float = Math.atan2(vecDelta.z, floorLength);

		return new Vec4(pitchAng, 0, yawAng);
	}//END OF getLookAngle



	// logic node.
	public static function getRandomFloat(arg_min:Float, arg_max:Float):Float{
		return arg_min + (Math.random() * (arg_max - arg_min));
	}//END OF getRandomFloat



	//logic node.
	public static function setCameraFOV(arg_camera:CameraObject, arg_fov:Float){
		arg_camera.data.raw.fov = arg_fov;
		arg_camera.buildProjection();
	}//END OF setCameraFOV
	//same, for plain object.
	public static function setCameraFOV_obj(arg_obj:Object, arg_fov:Float){
		var arg_camera:CameraObject = cast(arg_obj, CameraObject);
		arg_camera.data.raw.fov = arg_fov;
		arg_camera.buildProjection();
	}//END OF setCameraFOV

	// bassed off of the "SetCamera" logic node.
	public static function setActiveCamera(arg_camera:CameraObject){
		arg_camera.buildProjection();
		iron.Scene.active.camera = arg_camera;
	}//END OF setActiveCamera
	// Same as above, but comes with an automatic cast for a plain object.
	public static function setActiveCamera_obj(arg_obj:Object){
		var arg_camera:CameraObject = cast(arg_obj, CameraObject);
		arg_camera.buildProjection();
		iron.Scene.active.camera = arg_camera;
	}//END OF setActiveCamera_obj

	public static function getActiveScene():Scene{
		return iron.Scene.active;
	}

	// Get the material with the given name and run the "arg_funDone" function when retrieved. also based off of a logic node.
	public static function getMaterial(arg_strMatName:String, arg_funDone:MaterialData->Void){
		iron.data.Data.getMaterial(iron.Scene.active.raw.name, arg_strMatName,
			function(mat:MaterialData) {
				//value = mat;
				arg_funDone(mat);
			}
		);

	}//END OF getMaterial

	
	// Spawn a clone of the object name given by "arg_strTemplateName" with the given location, euler angles,
	// and scale. Call "arg_funDone" on the object when retrieved.
	// OPTIONAL: what object will be the parent of the new clone, and whether this clone also gets copies of
	// the template object's children.
	public static function spawnObject(arg_strTemplateName:String, arg_vecLoc:Vec4, arg_vecAngEuler:Vec4, arg_vecScale:Vec4, arg_funDone:Object->Void, arg_objParent:Object=null, arg_blnIncludeChildren:Bool=true){
		//other attempt: add a first parameter: "arg_scnSpawner:Scene".
		//And, replace "arg_strTemplateName:String" with "arg_objToSpawn:Object".
		
		iron.Scene.active.spawnObject(arg_strTemplateName, arg_objParent,
		    function(o:Object){
				
				o.transform.loc = arg_vecLoc;
				//object.transform.rot = someQuat;
				o.transform.setRotation(arg_vecAngEuler.x, arg_vecAngEuler.y, arg_vecAngEuler.z);
				o.transform.scale = arg_vecScale;
				o.transform.buildMatrix();

				//Oh.  So sometimes forgetting this causes issues, sometimes forgetting it doesn't.
				//well great.  But do it for teleport stuff like this.  If not, worlds will burn.
				#if arm_physics
				var rigidBody = o.getTrait(RigidBody);
				if (rigidBody != null) rigidBody.syncTransform();
				#end

				/*
				//...Lucily it looks like I don't have to worry about storing something in a list
				// and retrieving it later when the object is done being made.
				// Did the logic node need to do this?
				var matrix = matrices.pop(); // Async spawn in a loop, order is non-stable
				if (matrix != null) {
					object.transform.setMatrix(matrix);
					#if arm_physics
					var rigidBody = object.getTrait(RigidBody);
					if (rigidBody != null) {
						object.transform.buildMatrix();
						rigidBody.syncTransform();
					}
					#end
				}
				*/
				o.visible = true;

				arg_funDone(o);
				
			},
		arg_blnIncludeChildren);


		/*
		public static function spawnObject(name:String, parent:Object, done:Object->Void, spawnChildren = true)
		// BLASTS - can't make a modified clone of Scene's "spawnObject" work (by contents, not just calling it).
		// Wanted to see if it's possible to supply a GameObject directly to spawn, instead of looking up a template
		// entity by name that we already might have a direct reference to. Oh well.
		var objectsTraversed = 0;
		//var obj = getObj(raw, name);

		var objectsCount = arg_blnIncludeChildren ? arg_scnSpawner.getObjectsCount([arg_objToSpawn], false) : 1;
		function spawnObjectTree(arg_objToSpawn:TObj, parent:Object, parentObject:TObj, done:Object->Void) {
			arg_scnSpawner.createObject(arg_objToSpawn, raw, arg_objToSpawn, parentObject, function(object:Object) {
				if (arg_blnIncludeChildren && arg_objToSpawn.children != null) {
					for (child in arg_objToSpawn.children) spawnObjectTree(child, object, arg_objToSpawn, done);
				}
				if (++objectsTraversed == objectsCount && done != null) done(object);
			});
		}
		spawnObjectTree(arg_objToSpawn, arg_objToSpawn, null, done);
		*/
	}//END OF spawnObject

	//Overloaded version of above (with a sligtly different name, "_quat", since method overloading in Haxe is awkward).
	//Use this if supplying a quaternion instead of a euler.
	public static function spawnObject_quat(arg_strTemplateName:String, arg_vecLoc:Vec4, arg_qatAng:Quat, arg_vecScale:Vec4, arg_funDone:Object->Void, arg_objParent:Object=null, arg_blnIncludeChildren:Bool=true){


		iron.Scene.active.spawnObject(arg_strTemplateName, arg_objParent,
		    function(o:Object) {
				o.transform.loc = arg_vecLoc;
				
				// is this ok?
				o.transform.rot = arg_qatAng;

				//var vecAngAsEuler:Vec4 = arg_qatAng.getEuler();
				//o.transform.setRotation(vecAngAsEuler.x, vecAngAsEuler.y, vecAngAsEuler.z);
				
				o.transform.scale = arg_vecScale;
				o.transform.buildMatrix();
				#if arm_physics
				var rigidBody = o.getTrait(RigidBody);
				if (rigidBody != null) rigidBody.syncTransform();
				#end

				o.visible = true;

				arg_funDone(o);
			},
		arg_blnIncludeChildren);
	}//END OF spawnObject_quat
	

//Mimicks 
	public static function rotateQuatByAxisAngle(arg_dest:Quat, axis:Vec4, f:kha.FastFloat ){
		//var tempQ:Quat = new Quat();
		tempQ.fromAxisAngle(axis, f);
		arg_dest.multquats(tempQ, arg_dest);
		//buildMatrix();
	}//END OF rotateQuatByAxisAngle



	//Inspired by the "SetMaterial" node's script.
	//Note that the "arg_obj" input must be a MeshObject. The caller should handle the cast.
	public static function setMaterialSimple(arg_objMesh:MeshObject, arg_mat:MaterialData){
		for (i in 0...arg_objMesh.materials.length) {
			arg_objMesh.materials[i] = arg_mat;
		}
	}//END OF setMaterialSimple
	//...or call this alternate version ("_obj", supplied with a plain object, handles casting)
	public static function setMaterialSimple_obj(arg_obj:Object, arg_mat:MaterialData){
		var arg_objMesh:MeshObject = cast(arg_obj, MeshObject);

		for (i in 0...arg_objMesh.materials.length){
			arg_objMesh.materials[i] = arg_mat;
		}

	}//END OF setMaterialSimple_obj
	






	// This will only change the textures of an object to those from the given material.
	// This has only been tested on an object using one texture to change it to other textures meant
	// to apply to the same model.
	// It appears some portion of the mesh/bones for animation are stored in the material itself, so setting an
	// object's entire material to a newly loaded one will cause armature animations not to work.
	// The armature-affected mesh will remain frozen in place throughout an animation.
	// Changing only the material's texture instead, works.
	// However, the UV map is also required for this to work as expected. This method assumes the UV map from
	// this object's existing texture will allow the new texture to perfectly fit (meant for the same UV map).
	// For an object to begin with the correct UV map, it must be spawned (cloned) from some object that 
	// starts with one of the textures, such as a Person template object starting with the player, ally, or enemy
	// textures.
	// If the template starts without a texture, setting the texture will have no effect since 
	// it will be missing a UV map. Starting with a material gives the mesh the material's UV map,
	// which is otherwise unavailable from Armory (in-game)...
	// For evidence, print out "arg_objMesh.materials[i].data.geom.uvs" of an object made with a 
	// texture-UV-mapped material and one without any material at all. For the latter case, 
	// "arg_objMesh.materials[i].data.geom" will be null or arg_objMesh.materials[i].data.geom.uvs.length will be 0.
	public static function setTexturesFromMaterial(arg_objMesh:MeshObject, arg_mat:MaterialData){
		for (i in 0...arg_objMesh.materials.length) {
			arg_objMesh.materials[i] = new MaterialData(arg_objMesh.materials[i].raw, function done(newMat:MaterialData){}, "");
			arg_objMesh.materials[i].contexts[0].textures = arg_mat.contexts[0].textures;

			//arg_objMesh.data.geom.uvs.length;
			//arg_mat.
		}
	}//END OF setTexturesFromMaterial
	//...or call this alternate version ("_obj", supplied with a plain object, handles casting)
	public static function setTexturesFromMaterial_obj(arg_obj:Object, arg_mat:MaterialData){
		var arg_objMesh:MeshObject = cast(arg_obj, MeshObject);

		for (i in 0...arg_objMesh.materials.length){
			arg_objMesh.materials[i] = new MaterialData(arg_objMesh.materials[i].raw, function done(newMat:MaterialData){}, "");
			arg_objMesh.materials[i].contexts[0].textures = arg_mat.contexts[0].textures;
		}

	}//END OF setTexturesFromMaterial_obj






			
			
}//END OF class CustomLib

