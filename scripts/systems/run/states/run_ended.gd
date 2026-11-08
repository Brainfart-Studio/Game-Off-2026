class_name RunEnded
extends RunState
## The run is over. Pauses the tree so nothing keeps moving behind the results.


func enter(previous: StringName) -> void:
	super.enter(previous)
	Game.phase = Game.Phase.ENDED
	if run.pause_tree_on_end:
		get_tree().paused = true
