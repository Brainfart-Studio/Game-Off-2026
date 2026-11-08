class_name EnemyHurt
extends EnemyState
## Knocked back and stunned after a hit. Gravity only, then back to `resume_state`.

var _time: float = 0.0


func enter(previous: StringName) -> void:
	super(previous)
	var resistance: float = clampf(enemy.stats.value(&"knockback_resistance"), 0.0, 1.0)
	enemy.velocity = enemy.last_hit.knockback * (1.0 - resistance)
	_time = 0.0


func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	enemy.stop(delta)
	_time += delta
	if _time >= enemy.stats.value(&"hurt_stun"):
		machine.transition_to(enemy.resume_state)
