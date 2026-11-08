class_name EnemyState
extends State
## Base for enemy states. `enemy` is the machine's owner, typed.

var enemy: Enemy


func enter(_previous: StringName) -> void:
	enemy = actor as Enemy
