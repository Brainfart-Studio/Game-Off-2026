class_name PlayerJump
extends PlayerState


func enter(previous: StringName) -> void:
	super(previous)
	player.jump()


func physics_update(delta: float) -> void:
	player.move(delta)
	player.apply_gravity(delta)
	player.cut_jump()
	if player.can_attack():
		machine.transition_to(&"Attack")
	elif player.velocity.y >= 0.0:
		machine.transition_to(&"Fall")
