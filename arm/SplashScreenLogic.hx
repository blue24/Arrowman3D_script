package arm;


import armory.system.Event;
import armory.trait.internal.CanvasScript;



class SplashScreenLogic extends iron.Trait {

	var canvas:CanvasScript;

	public function new() {
		super();

		notifyOnInit(init);
		notifyOnRemove(removed);
	}

	function removed(){
		Event.remove("btnStoryMode_clicked");
		Event.remove("btnArcadeMode_clicked");
		Event.remove("btnInstructions_clicked");
		Event.remove("btnQuit_clicked");
	}

	function init(){
		canvas = object.getTrait(CanvasScript);
		
		Event.add("btnStoryMode_clicked", btnStoryMode_clicked);
		Event.add("btnArcadeMode_clicked", btnArcadeMode_clicked);

		Event.add("btnInstructions_clicked", btnInstructions_clicked);
		Event.add("btnQuit_clicked", btnQuit_clicked);

	}//END OF init


	function btnStoryMode_clicked(){
		iron.Scene.setActive("scene_level_select", function(o:iron.object.Object) {
		});
	}
	function btnArcadeMode_clicked(){
		iron.Scene.setActive("scene_arcade", function(o:iron.object.Object) {
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
