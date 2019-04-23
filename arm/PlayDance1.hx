package arm;

import custom_lib.CustomLib;
import iron.object.BoneAnimation;


class PlayDance1 extends iron.Trait {
	public function new() {
		super();

		notifyOnInit(init);

		// notifyOnUpdate(function() {
		// });

		// notifyOnRemove(function() {
		// });
	}


	public function init(){
		var myAnim:BoneAnimation = CustomLib.getArmatureAnimationOfObject(object);
		myAnim.play("dance_1", null, 0, 1, true);
	}//END OF init



}
