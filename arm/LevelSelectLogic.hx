package arm;


import armory.system.Event;
import armory.trait.internal.CanvasScript;


class LevelSelectLogic extends iron.Trait {
	public function new() {
		super();
		notifyOnInit(init);
		notifyOnRemove(removed);
	}
	function removed(){
		Event.remove("btnBackToSplash_clicked");
		Event.remove("btnSelectLevel1_clicked");
		Event.remove("btnSelectLevel2_clicked");
		Event.remove("btnSelectLevel3_clicked");
		Event.remove("btnSelectLevel4_clicked");
	}

	function init(){
		
		Event.add("btnBackToSplash_clicked", btnBackToSplash_clicked);
		Event.add("btnSelectLevel1_clicked", btnSelectLevel1_clicked);
		Event.add("btnSelectLevel2_clicked", btnSelectLevel2_clicked);
		Event.add("btnSelectLevel3_clicked", btnSelectLevel3_clicked);
		Event.add("btnSelectLevel4_clicked", btnSelectLevel4_clicked);
	}

	
	function btnBackToSplash_clicked(){
		iron.Scene.setActive("scene_splash_screen", function(o:iron.object.Object) {
			
		});
	}

	function btnSelectLevel1_clicked(){
		iron.Scene.setActive("scene_level_pre", function(o:iron.object.Object) {
			var theTrait:Level1_preTextLogic = o.getTrait(Level1_preTextLogic);
			theTrait.sceneToStart = "scene_level_1";
			theTrait.titleText = "Level 1";
			theTrait.preTextImageName = "level_1_pre_text.png";
			theTrait.screenshotName = "level_1_screenshot.png";

		});
	}
	function btnSelectLevel2_clicked(){
		iron.Scene.setActive("scene_level_pre", function(o:iron.object.Object) {
			var theTrait:Level1_preTextLogic = o.getTrait(Level1_preTextLogic);
			theTrait.sceneToStart = "scene_level_2";
			theTrait.titleText = "Level 2";
			theTrait.preTextImageName = "level_2_pre_text.png";
			theTrait.screenshotName = "level_2_screenshot.png";
			
		});
	}
	function btnSelectLevel3_clicked(){
		iron.Scene.setActive("scene_level_pre", function(o:iron.object.Object) {
			var theTrait:Level1_preTextLogic = o.getTrait(Level1_preTextLogic);
			theTrait.sceneToStart = "scene_level_3";
			theTrait.titleText = "Level 3";
			theTrait.preTextImageName = "level_3_pre_text.png";
			theTrait.screenshotName = "level_3_screenshot.png";
			
		});
	}
	function btnSelectLevel4_clicked(){
		iron.Scene.setActive("scene_level_pre", function(o:iron.object.Object) {
			var theTrait:Level1_preTextLogic = o.getTrait(Level1_preTextLogic);
			theTrait.sceneToStart = "scene_level_4";
			theTrait.titleText = "Level 4";
			theTrait.preTextImageName = "level_4_pre_text.png";
			theTrait.screenshotName = "level_4_screenshot.png";
			
		});
	}


	
}
