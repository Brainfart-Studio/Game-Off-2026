class_name PlayerDead
extends PlayerState
## The player is dead. No input, no hits taken or dealt, gravity only. There is no way out.


func enter(previous: StringName) -> void:
	super(previous)
	player.velocity.x = 0.0
	player.hurtbox.enabled = false
	player.attack_hitbox.deactivate()


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
