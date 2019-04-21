package arm;

// Doesn't have any behavior on its own.
// Meant to be read by "CustomGameInit" and replaced
// with an enemy using my transform details
// (position and rotation, but not scale). Scale and colorr
// of the marker are only for the editor.
class MARKER_spawnEnemy extends iron.Trait {
	public function new() {
		super();
	}
}
