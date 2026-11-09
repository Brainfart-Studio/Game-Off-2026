class_name PlayerRun
extends PlayerState


func enter(previous: StringName) -> void:
	super(previous)


func physics_update(delta: float) -> void:
	player.move(delta)
	player.apply_gravity(delta)
	if player.can_attack():
		machine.transition_to(&"Attack")
	elif player.input.move_x == 0.0:
		machine.transition_to(&"Idle")
	elif player.can_jump():
		machine.transition_to(&"Jump")
	elif not player.is_on_floor():
		machine.transition_to(&"Fall")
