package arm;


/*
The presence of this trait alone suggests this object should be treated as the ground.
The scene has a trait (CustomGameInit) to, at startup, read through each game object and
check for the presence of the "GroundObject" trait. If present, its CustomObject trait
(present in all game objects) will have "isGround" set to "true".
If there's a more direct way to accomplish this, I got nothing. 
Properties may work, but manually giving the same variable to everything feels sloppy and
error-prone.  Presence of a trait, less-so I suppose.
UPDATE: using each object's own CustomObject trait to handle this instead. After all, since it
is present on each object, that means any startup checks in there will have to work even
if the object is generated in real time (like spawned archers, if done, and arrows).

In short, this trait does nothing at all by itself.
Something else reads it and makes a change otherwise not (as) feasible to mark in Blender
otherwise.
*/
class GroundObject extends iron.Trait {
	public function new() {
		super();
	}

}
