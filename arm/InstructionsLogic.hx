package arm;


import armory.system.Event;
import armory.trait.internal.CanvasScript;

//import zui.Canvas;
import zui.Canvas.TElement;
import armory.trait.internal.CanvasScript;


class InstructionsLogic extends iron.Trait {

	public function new() {
		super();
		notifyOnInit(init);
		notifyOnRemove(removed);
	}

	function removed(){
		Event.remove("btnBackToSplash_clicked");
	}

	function init(){
		Event.add("btnBackToSplash_clicked", btnBackToSplash_clicked);
		
		var canvas:CanvasScript = object.getTrait(CanvasScript);
		var eleRef:TElement = canvas.getElement("txtTitle");
	}
	
	function btnBackToSplash_clicked(){
		iron.Scene.setActive("scene_splash_screen", function(o:iron.object.Object) {
		});
	}


}
