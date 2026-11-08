class_name RunRunning
extends RunState
## The countdown. Announces each second that passes, and the last `warning_time` of them.
## After the player dies the timer stops and `death_delay` runs out before the run ends.

var _second: int = 0
var _death_elapsed: float = 0.0


func enter(previous: StringName) -> void:
	super.enter(previous)
	Game.phase = Game.Phase.RUNNING
	# One above the current second, so the first frame announces its own second.
	_second = ceili(Game.time_left) + 1
	_death_elapsed = 0.0


func update(delta: float) -> void:
	if run.died:
		_death_elapsed += delta
		if _death_elapsed >= run.config.death_delay:
			machine.transition_to(&"Ended")
		return
	Game.time_left = maxf(Game.time_left - delta, 0.0)
	var second: int = ceili(Game.time_left)
	if second != _second:
		_second = second
		Events.time_changed.emit(Game.time_left)
		if second >= 1 and second <= run.config.warning_time:
			Events.time_warning.emit(second)
	if Game.time_left <= 0.0:
		machine.transition_to(&"Ended")
