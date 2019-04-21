package arm;


import armory.system.Event;
import armory.trait.internal.CanvasScript;


class LevelSelectLogic extends iron.Trait {
	public function new() {
		super();
		notifyOnInit(init);
	}

	function init(){
		Event.add("btnBackToSplash_clicked", btnBackToSplash_clicked);
		Event.add("btnSelectLevel1_clicked", btnSelectLevel1_clicked);
		
	}
	function btnSelectLevel1_clicked(){
		iron.Scene.setActive("scene_level_1", function(o:iron.object.Object) {
			
		});
	}
	function btnBackToSplash_clicked(){
		iron.Scene.setActive("scene_splash_screen", function(o:iron.object.Object) {
			
		});
	}
	
}
