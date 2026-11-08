class_name RunStarting
extends RunState
## The pause before the countdown. Modules announce their starting values on `run_started`.

var _elapsed: float = 0.0


func enter(previous: StringName) -> void:
	super.enter(previous)
	_elapsed = 0.0
	Game.phase = Game.Phase.STARTING
	Events.run_started.emit()
	Events.time_changed.emit(Game.time_left)


func update(delta: float) -> void:
	_elapsed += delta
	if run.died or _elapsed >= run.config.start_delay:
		machine.transition_to(&"Running")
