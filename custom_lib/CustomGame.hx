package custom_lib;




import iron.Scene;


import iron.system.Input;
import iron.object.Object;
import arm.PlayerObject;
import arm.EndScreenLogic;



@:enum abstract Faction(Int) from Int to Int{
	var UNSET:Int = -1;
	var PLAYER:Int = 0;
	var ALLY:Int = 1;
	var ENEMY:Int = 2;
}


class CustomGame{

	public static var canSpawnThings:Bool = false;
	

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


	public static function endGame(arg_victory:Bool, arg_score:Float ){
		
		//Be sure to unlock the mouse first.
		var mouse = Input.getMouse();
		if(mouse.locked) mouse.unlock();

		var previousScene:Scene = iron.Scene.active;
		
		//iron.Scene.active.remove();  //is that ok?
		
		CustomLib.changeScene("scene_end", 
			function(o:Object){
				var theTrait:EndScreenLogic = o.getTrait(EndScreenLogic);
				theTrait.wasVictory = arg_victory;
				theTrait.scoreStore = arg_score;
				
				//for(thisChild in o.children){
				//	trace("!!! CHILD IN NEW SCENE: " + thisChild.name);
				//}

				//previousScene.remove();  //is this acceptable?
				theTrait.previousSceneRef = previousScene;
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