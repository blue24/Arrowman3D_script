package custom_lib;



import iron.math.Quat;
import iron.math.Vec4;
import iron.math.Mat4;

import iron.Scene;


import iron.system.Input;
import iron.object.Object;
import arm.PlayerObject;
import arm.EndScreenLogic;
import arm.PersonAIObject;

import arm.Level1_preTextLogic;



@:enum abstract GameMode(Int) from Int to Int{
	var STORY:Int = 0;
	var ARCADE:Int = 1;
}



@:enum abstract Faction(Int) from Int to Int{
	var UNSET:Int = -1;
	var PLAYER:Int = 0;
	var ALLY:Int = 1;
	var ENEMY:Int = 2;
}


class CustomGame{


//////////////////////////////////////////////////////////////////////////////////////////////////
	// This is an easy flag for allowing markers to move on to spawning AI-controlled archers or not. Debug feature.
	public static var canSpawnThings:Bool = true;

	// These are cheats that help the player.
	public static var playerInvincible:Bool = false;
	public static var superArrowDamage:Bool = true;
	public static var playerRapidArrow:Bool = true;
	public static var playerSpeedy:Bool = true;
	public static var playerSuperJump:Bool = true;
//////////////////////////////////////////////////////////////////////////////////////////////////








	//how long arcade mode lasts. If the player survives this long, they win.
	public static var arcadeModeDuration =  60*3;
	//public static var arcadeModeDuration =  9;

	//For other places like screen_end to also draw from if needed.
	public static var gameEndTime:Float = 0;

	// Multiple applied to player speed. May varry per game mode.
	public static var playerSpeedFactor:Float = 1.0;

	//default.
	public static var currentGameMode:GameMode = GameMode.STORY;
	

	// Number of these types of archers currently present in a level.
	// Arcade mode doesn't want to spawn more if a limit is reached, and Story mode has a few missions that require 
	// enemy archers to be dealt with before the goal appears.
	public static var currentEnemyCount = 0;
	public static var currentAllyCount = 0;


	// Stored here as a cache since this may be called a lot.  It must be filled elsewhere when a new game scene loads (CustomGameInit's init).
	public static var currentSceneName:String = "";


	// These are global, to be retrieved by any object as needed.
	// They are assigned when a player object is created.
	public static var playerRef:Object = null;
	public static var playerRefTrait:PlayerObject = null;



	
	// One entry for each of the factions, starting with #0 (PLAYER).
	public static var aryStr_resource_person_materialList:Array<String> = [
		"player_mat",
		"ally_mat",
		"enemy_mat"
	];
	// same, for arrows.
	public static var aryStr_resource_arrow_materialList:Array<String> = [
		"player_arrow_mat",
		"ally_arrow_mat",
		"enemy_arrow_mat"
	];



	public static function playSoundForPlayer(arg_soundPath:String, arg_soundLocation:Vec4, arg_baseVolume:Float = 1.0, arg_attenuation:Float = 1.0){
		// Custom method for this game. Same as CustomLib.playSoundAtLocation, but sends the player's location as the listener automatically.
		if(CustomGame.playerRef != null){
			CustomLib.playSoundAtLocation(arg_soundPath, CustomGame.playerRef.transform.loc, arg_soundLocation, arg_baseVolume, arg_attenuation);
		}
	}//END OF playSoundForPlayer

	//a squad can have been 3 and 5 archers, and are spawned close to each other. Same faction.
	//Spawn at the specified coordinates (centered around that randomly a short distance)
	public static function spawnRandomArcherSquad(arg_spawnLoc_x:Float, arg_spawnLoc_y:Float){
		
		var destFaction:Faction;
		if(Math.random() <= 0.34){
			//it's a friendly squad.
			destFaction = Faction.ALLY;
		}else{
			//enemy.
			destFaction = Faction.ENEMY;
		}

		var expirationTime:Float = CustomLib.randomInRange_float(32, 45);

		var spawnLoc:Vec4 = new Vec4(
			arg_spawnLoc_x + CustomLib.randomInRange_float(-210, 210),
			arg_spawnLoc_y + CustomLib.randomInRange_float(-210, 210),
			600 + CustomLib.randomInRange_float(0, 80)
		);
		var spawnAng:Vec4 = new Vec4(
			0,
			0,
			CustomLib.randomInRange_float(0, 2*Math.PI)
		);

		var squadSize:Int = CustomLib.randomInRange_int(3, 5);
		for(i in 0...squadSize){
			CustomLib.spawnObject(CustomGame.currentSceneName + "_" + "person_cylinder_template", spawnLoc, spawnAng, new Vec4(6, 6, 12.8), 
			    function(o:Object){
					
					if(destFaction == Faction.ENEMY){
						CustomGame.currentEnemyCount += 1;
					}else if(destFaction == Faction.ALLY){
						CustomGame.currentAllyCount += 1;
					}
					
					var traitGen:PersonAIObject = new PersonAIObject();
					o.addTrait(traitGen);
					traitGen.spawned(destFaction);
					
					//if(destFaction==Faction.ENEMY){
					//var personAI_Trait:PersonAIObject = o.getTrait(PersonAIObject);
					traitGen.setExpirationTimer(expirationTime);
					//}

				}
			);
		}//END OF for each squad member to spawn

		
	}//END OF spawnRandomArcherSquad



	
	public static function buildTimeString(arg_rawSeconds:Float):String{

			
		//how many minutes?
		var minutesLeft:Float = Math.floor(arg_rawSeconds / 60);
		//how many remainder seconds?
		var secondsLeft:Float = Math.floor(arg_rawSeconds - (minutesLeft*60));


		if(secondsLeft < 10){
			//filler 0 for seconds.
			return minutesLeft + ":" + "0" + secondsLeft;
		}else{
			return minutesLeft + ":" + secondsLeft;
		}
	}

	public static function buildTimerString_update():String{
		//how much time is left? This is in seconds.
		var timeLeft:Float = CustomGame.gameEndTime - CustomLib.getCurrentTime();

		//build the string.
		var timeString:String = buildTimeString(timeLeft);

		//set it for the player.
		//txtTimer.text = "Timer: " + timeString;
		return timeString;

	}//END OF setTimerString




	//Goto the generic pre-screen for the levels and set it up for this level in particular.
	public static function gotoPreLevel(arg_sceneName:String){
		iron.Scene.setActive( "scene_level_pre", function(o:iron.object.Object) {

			switch(arg_sceneName){
				case "scene_level_1":
					var theTrait:Level1_preTextLogic = o.getTrait(Level1_preTextLogic);
					theTrait.sceneToStart = "scene_level_1";
					theTrait.titleText = "Level 1";
					theTrait.preTextImageName = "level_1_pre_text.png";
					theTrait.screenshotName = "level_1_screenshot.png";
				case "scene_level_2":
					var theTrait:Level1_preTextLogic = o.getTrait(Level1_preTextLogic);
					theTrait.sceneToStart = "scene_level_2";
					theTrait.titleText = "Level 2";
					theTrait.preTextImageName = "level_2_pre_text.png";
					theTrait.screenshotName = "level_2_screenshot.png";
				case "scene_level_3":
					var theTrait:Level1_preTextLogic = o.getTrait(Level1_preTextLogic);
					theTrait.sceneToStart = "scene_level_3";
					theTrait.titleText = "Level 3";
					theTrait.preTextImageName = "level_3_pre_text.png";
					theTrait.screenshotName = "level_3_screenshot.png";
				case "scene_level_4":
					var theTrait:Level1_preTextLogic = o.getTrait(Level1_preTextLogic);
					theTrait.sceneToStart = "scene_level_4";
					theTrait.titleText = "Level 4";
					theTrait.preTextImageName = "level_4_pre_text.png";
					theTrait.screenshotName = "level_4_screenshot.png";
				default:
					//...what? how is that possible?
			}//END OF switch on sceneName

		});
	}


	// The name of the next scene depends on the name of the provided scene.
	// Using a parameter to provide the name of the "current" scene for finding the next of,
	// since being on the end screen (scene_end) doesn't tell much.
	public static function getNextSceneName(arg_ofScene:String):String{
		//var thisSceneName = CustomLib.getActiveSceneName();

		switch(arg_ofScene){
			case "scene_level_1":
				return "scene_level_2";
			case "scene_level_2":
				return "scene_level_3";
			case "scene_level_3":
				// No time for level 4 - this is fine as it is.
				return "";
				//return "scene_level_4";
			case "scene_level_4":
				//Blank signifies, out of levels. No more after this, hide the Next button when this scene ends.
				return "";
		}//END OF switch(thisSceneName)

		return "";  //none of the above (???)
	}//END OF getNextSceneName


	public static function endGame(arg_victory:Bool, arg_score:Float ){
		
		//Be sure to unlock the mouse first.
		var mouse = Input.getMouse();
		if(mouse.locked) mouse.unlock();

		var previousScene:Scene = iron.Scene.active;
		
		//iron.Scene.active.remove();  //is that ok?

		//name of the current scene ending. Need to tell scene_end what this is.
		var thisSceneName:String = CustomLib.getActiveSceneName();

		
	
		//trace("This scene is ending: " + CustomLib.getActiveScene().root.name + " : " + CustomLib.getActiveScene().world.name + " : " + CustomLib.getActiveScene().raw.name);
		//third one actually gets the name of the scene.  huh... Utility time.
		CustomLib.changeScene("scene_end", 
			function(o:Object){
				var theTrait:EndScreenLogic = o.getTrait(EndScreenLogic);

				theTrait.wasVictory = arg_victory;
				theTrait.scoreStore = arg_score;

				

				theTrait.endedSceneName = thisSceneName;
				
				//for(thisChild in o.children){
				//	trace("!!! CHILD IN NEW SCENE: " + thisChild.name);
				//}

			}
		);


	}

	// Does the first faction hate the second?  Not that order really matters here.
	public static function factionHates(arg_myFaction:Faction, arg_otherFaction:Faction):Bool{
		//trace("FACTION HATES? " + arg_myFaction + " " + arg_otherFaction);

		switch(arg_myFaction){
			case Faction.UNSET:{
				//what?  Assume neutral.
				return false;
			}
			case Faction.ALLY:{
				//I hate enemies.
				return (arg_otherFaction == Faction.ENEMY);
			}
			case Faction.ENEMY:{
				//I hate allies and players.
				return (arg_otherFaction == Faction.ALLY || arg_otherFaction == Faction.PLAYER);
			}
			case Faction.PLAYER:{
				return (arg_otherFaction == Faction.ENEMY);
			}
		}//END OF switch(arg_myFaction)

		return false;  //none? unset?
	}//END OF factionHates



}//END OF class CustomGame