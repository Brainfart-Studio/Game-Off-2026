class_name GroundPatrol
extends EnemyState
## Walks the way it faces, turns at a wall or a ledge, and chases a player who comes in range.


func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	if enemy.at_wall() or enemy.at_ledge():
		enemy.set_facing(-enemy.facing)
	enemy.walk(enemy.facing, enemy.stats.value(&"move_speed"), delta)
	if enemy.target_in(enemy.data.detect_range):
		machine.transition_to(&"Chase")
