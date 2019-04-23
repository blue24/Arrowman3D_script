package arm;

import custom_lib.CustomLib;
import custom_lib.CustomGame;

import zui.Canvas.TElement;
import armory.trait.internal.CanvasScript;
import armory.system.Event;

import iron.system.Input;


import iron.Scene;




class EndScreenLogic extends iron.Trait {



	// These should be set by the scene that's changing to here to tell
	// this end scene how to set itself up (Game Over or Victory text) and
	// what the next scene and scene to play again (restart) are.
	// Note that the next scene can be implied from the current one that ended 
	// (the CustomGame.getNextSceneName method uses the name of a scene to tell what the
	// name of the next scene to run is, if there is one).
	
	public var endedSceneName:String = "";
	public var wasVictory:Bool = false;
	public var scoreStore:Float = 0;
	//public var levelCompleted:String = "";

	// Don't set this from elsewhere. This will be set in this file.
	var nextSceneName:String = "";

	public function new() {
		super();
		notifyOnInit(init);
		notifyOnRemove(removed);
	}


	function removed(){
		Event.remove("btnNext_clicked");
		Event.remove("btnRestart_clicked");
		Event.remove("btnBackToSplash_clicked");
		Event.remove("btnQuit_clicked");
	}

	function init(){

		//Just being safe, unlock the mouse.
		var mouse = Input.getMouse();
		if(mouse.locked) mouse.unlock();
		
		var canvas:CanvasScript = object.getTrait(CanvasScript);

		var eleRef:TElement = canvas.getElement("txtTitle");
		var otherVariable:TElement = canvas.getElement("txtScore");
		var lastLine:TElement = canvas.getElement("txtExtraLine");
		var btnNext:TElement = canvas.getElement("btnNext");

		nextSceneName = CustomGame.getNextSceneName(endedSceneName);
		if(!wasVictory || nextSceneName == ""){
			//hide the button if we're out of levels or the player lost.
			btnNext.visible = false;
		}else{
			//show it.
			btnNext.visible = true;
		}

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

		if(CustomGame.currentGameMode == GameMode.ARCADE && !wasVictory && CustomGame.gameEndTime != 0){
			//point out how long the user lasted if they lost in arcade mode.
			var lastedTime = CustomGame.arcadeModeDuration - (CustomGame.gameEndTime - CustomLib.getCurrentTime());
			var timerString:String = CustomGame.buildTimeString(lastedTime);

			lastLine.text = "You lasted " + timerString + ".";
		}
		
		Event.add("btnNext_clicked", btnNext_clicked);
		Event.add("btnRestart_clicked", btnRestart_clicked);
		Event.add("btnBackToSplash_clicked", btnBack_clicked);
		Event.add("btnQuit_clicked", btnQuit_clicked);

	}//END OF init


	function btnNext_clicked(){
		// Clicking the Next button shouldn't even be possible if a Next scene wasn't provided (Next button is invisible), but
		// just to be safe.
		trace("***NEXT CLICKED. Ended scene: " + endedSceneName + " " + " Next Scene: " + nextSceneName);
		if(wasVictory && nextSceneName != ""){
			//iron.Scene.setActive( nextSceneName, function(o:iron.object.Object) {
			//});
			CustomGame.gotoPreLevel(nextSceneName);
		}
	}//END OF btnNext_clicked
	function btnRestart_clicked(){
		// CustomLib.getActiveSceneName() ?
		//   No, not that. We're in scene_end here, restarting the end scene isn't what we want.
		//   Store the recently ended scene here. Expect that scene to give us its name (and nextSceneName for that matter).

		trace("AND WHAT IS THE SCENE THAT JUST ENDED " + endedSceneName);
		iron.Scene.setActive( endedSceneName, function(o:iron.object.Object) {
		});
	}//END OF btnRestart_clicked
	function btnBack_clicked(){
		iron.Scene.setActive("scene_splash_screen", function(o:iron.object.Object) {
		});
	}//END OF btnBack_clicked
	
	function btnQuit_clicked(){
		kha.System.stop();
	}//END OF btnQuit_clicked



}
