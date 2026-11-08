class_name GroundChase
extends EnemyState
## Walks toward the player's x. Gives up when the player is beyond `lose_range` or gone.

## Horizontal distance within which the enemy stops (px).
const STOP_DISTANCE: float = 4.0


func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	if not enemy.has_target():
		machine.transition_to(&"Patrol")
		return
	var offset: Vector2 = enemy.target_position() - enemy.global_position
	if offset.length() > enemy.data.lose_range:
		machine.transition_to(&"Patrol")
		return
	if absf(offset.x) <= STOP_DISTANCE:
		enemy.stop(delta)
		return
	enemy.walk(1 if offset.x > 0.0 else -1, enemy.stats.value(&"chase_speed"), delta)
