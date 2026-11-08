class_name RunRunning
extends RunState
## The countdown. Announces each second that passes, and the last `warning_time` of them.

var _second: int = 0


func enter(previous: StringName) -> void:
	super.enter(previous)
	Game.phase = Game.Phase.RUNNING
	# One above the current second, so the first frame announces its own second.
	_second = ceili(Game.time_left) + 1


func update(delta: float) -> void:
	Game.time_left = maxf(Game.time_left - delta, 0.0)
	var second: int = ceili(Game.time_left)
	if second != _second:
		_second = second
		Events.time_changed.emit(Game.time_left)
		if second >= 1 and second <= run.config.warning_time:
			Events.time_warning.emit(second)
	if Game.time_left <= 0.0:
		machine.transition_to(&"Ended")
