class_name RunState
extends State
## Base for the run states. `run` is the Run that owns the machine, set on enter.

var run: Run


func enter(_previous: StringName) -> void:
	run = actor as Run
