package arm;


// This trait marks an object to only be cloned, so that gravity / visibility should be turned off at startup.
// Then delete this trait to make sure no objects made from this inherit the dummy trait (even though they probably
// need to turn gravity / undo other things that were disabled).
// Not from this trait itself but from CustomGameInit's run-through of all gameobjects, upon seeing this trait.
class TemplateObject extends iron.Trait {
	public function new() {
		super();
	}
}
