class_name PlayerFall
extends PlayerState


func enter(previous: StringName) -> void:
	super(previous)


func physics_update(delta: float) -> void:
	player.move(delta)
	player.apply_gravity(delta)
	if player.can_jump():
		machine.transition_to(&"Jump")
	elif player.is_on_floor():
		if player.input.move_x != 0.0:
			machine.transition_to(&"Run")
		else:
			machine.transition_to(&"Idle")
