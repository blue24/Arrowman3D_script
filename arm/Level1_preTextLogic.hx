package arm;


import armory.system.Event;
import zui.Canvas.TElement;
import armory.trait.internal.CanvasScript;


class Level1_preTextLogic extends iron.Trait {

	//These must be filled by whoever calls a scene with this trait.
	//---------------------------------------------------------------------------------
	public var sceneToStart:String;
	public var titleText:String;
	public var preTextImageName:String;
	public var screenshotName:String;

	//---------------------------------------------------------------------------------



	var canvas:CanvasScript;

	public function new() {
		super();
		notifyOnInit(init);
		notifyOnRemove(removed);
	}

	function removed(){
		Event.remove("btnBack_clicked");
		Event.remove("btnStart_clicked");
	}

	function init(){

		canvas = object.getTrait(CanvasScript);
		var txtTitle:TElement = canvas.getElement("txtTitle");
		var imgPreText:TElement = canvas.getElement("imgPreText");
		var imgScreenshot:TElement = canvas.getElement("imgScreenshot");
		

		txtTitle.text = titleText;

		trace("WHAT IS MY ASSET NOW A ? " + imgPreText.asset);
		trace("WHAT IS MY ASSET NOW B ? " + imgScreenshot.asset);

		//imgPreText.asset = "level_2_pre_text.png";
		imgPreText.asset = preTextImageName;
		imgScreenshot.asset = screenshotName;
		
		Event.add("btnBack_clicked", btnBack_clicked);
		Event.add("btnStart_clicked", btnStart_clicked);
	}

	
	function btnBack_clicked(){
		iron.Scene.setActive("scene_level_select", function(o:iron.object.Object) {
			
		});
	}

	function btnStart_clicked(){
		trace("PRETEXT: btnStart_clicked " + sceneToStart);
		iron.Scene.setActive(sceneToStart, function(o:iron.object.Object) {
			
		});
	}


}
