class_name Hurtbox
extends Area2D
## Takes hits for its parent. Hitboxes of the other team find it by physics layer.

## A hit was taken.
signal hurt(info: DamageInfo)

@export var team: Team.Id = Team.Id.PLAYER
@export var health: Health

## Off turns the hurtbox down: it cannot be found and refuses hits.
var enabled: bool = true:
	set(value):
		enabled = value
		set_deferred("monitorable", value)


func _ready() -> void:
	collision_layer = Layers.PLAYER_HURTBOX if team == Team.Id.PLAYER else Layers.ENEMY_HURTBOX
	collision_mask = 0
	monitoring = false
	monitorable = enabled


## Gives the hit to the health. True when the health took it.
func receive(info: DamageInfo) -> bool:
	if not enabled or health == null:
		return false
	info.target = get_parent() as Node2D
	if not health.damage(info):
		return false
	hurt.emit(info)
	return true
