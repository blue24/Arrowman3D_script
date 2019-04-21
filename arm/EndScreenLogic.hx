package arm;

import custom_lib.CustomGame;

import zui.Canvas.TElement;
import armory.trait.internal.CanvasScript;
import armory.system.Event;

import iron.system.Input;


import iron.Scene;




class EndScreenLogic extends iron.Trait {

	public var previousSceneRef:Scene = null;

	public var wasVictory:Bool = false;
	public var scoreStore:Float = 0;
	//public var levelCompleted:String = "";

	public function new() {
		super();
		notifyOnInit(init);
	}

	
	function btnQuit_clicked(){
		kha.System.stop();
	}//END OF btnQuit_clicked
	function btnRestart_clicked(){
		iron.Scene.setActive("scene_level_1", function(o:iron.object.Object) {
		});
	}//END OF btnRestart_clicked
	function btnBack_clicked(){
		iron.Scene.setActive("scene_splash_screen", function(o:iron.object.Object) {
		});
	}//END OF btnBack_clicked

	function init(){

		//Just being safe, unlock the mouse.
		var mouse = Input.getMouse();
		if(mouse.locked) mouse.unlock();
		
		var canvas:CanvasScript = object.getTrait(CanvasScript);

		var eleRef:TElement = canvas.getElement("txtTitle");
		var otherVariable:TElement = canvas.getElement("txtScore");

		//color values found through picking a color in the Canvas editor (Blender) and printing out "eleRef.color" to see what it was.
		if(wasVictory == true){
			eleRef.text = "VICTORY";
			eleRef.color = -16482560;  //green
		}else{
			eleRef.text = "GAME OVER";
			eleRef.color = -7143424; //red
		}
		//trace("color?? " + eleRef.color);

		otherVariable.text = "Your score was " + scoreStore + ".";
		
		Event.add("btnRestart_clicked", btnRestart_clicked);
		Event.add("btnBack_clicked", btnBack_clicked);
		Event.add("btnQuit_clicked", btnQuit_clicked);

	}//END OF init





}
