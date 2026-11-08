class_name EnemyDie
extends EnemyState
## The enemy is dead. It takes and deals no hits, falls, and is removed after `death_time`.

var _time: float = 0.0


func enter(previous: StringName) -> void:
	super(previous)
	enemy.hurtbox.enabled = false
	enemy.contact_hitbox.deactivate()
	enemy.velocity.x = 0.0
	_time = 0.0
	Events.enemy_killed.emit(enemy, enemy.data, enemy.last_hit)


func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	_time += delta
	if _time >= enemy.stats.value(&"death_time"):
		enemy.queue_free()
