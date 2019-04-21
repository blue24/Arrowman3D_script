package arm;


import iron.math.Vec4;

class FastRotate extends iron.Trait {
	public function new() {
		super();

		notifyOnInit(init);

		notifyOnUpdate(update);
	}

	function init(){
		
	}
	function update(){
		object.transform.rotate(new Vec4(0, 0, 1), 0.004);
	}


}
