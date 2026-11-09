class_name PlayerHurt
extends PlayerState
## Knocked back and stunned after a hit. No input, gravity only.

var _time: float = 0.0


func enter(previous: StringName) -> void:
	super(previous)
	player.velocity = player.last_hit.knockback * player.stats.value(&"hurt_knockback_multiplier")
	_time = 0.0


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.stats.value(&"ground_decel") * delta)
	_time += delta
	if _time < player.stats.value(&"hurt_stun"):
		return
	machine.transition_to(&"Idle" if player.is_on_floor() else &"Fall")
