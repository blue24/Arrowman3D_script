package arm;


import armory.system.Event;
import armory.trait.internal.CanvasScript;



class SplashScreenLogic extends iron.Trait {

	var canvas:CanvasScript;

	public function new() {
		super();

		notifyOnInit(init);

	}

	function init(){
		canvas = object.getTrait(CanvasScript);
		
		Event.add("btnPlay_clicked", btnPlay_clicked);
		Event.add("btnInstructions_clicked", btnInstructions_clicked);
		Event.add("btnQuit_clicked", btnQuit_clicked);

	}//END OF init


	function btnPlay_clicked(){
		iron.Scene.setActive("scene_level_1", function(o:iron.object.Object) {
		});
	}
	function btnInstructions_clicked(){
		iron.Scene.setActive("scene_instructions", function(o:iron.object.Object) {
		});
	}//END OF btnInstructions_clicked
	function btnQuit_clicked(){
		kha.System.stop();
	}


}
