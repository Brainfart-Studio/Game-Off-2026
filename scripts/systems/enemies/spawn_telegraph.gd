class_name SpawnTelegraph
extends Node2D
## A warning where an enemy is about to appear. After `time` it places the enemy under the combat
## content and frees itself. Time is counted in `_physics_process`, so a frozen world stops it.

var _data: EnemyData
var _time: float = 0.0
var _animation: AnimationDef
var _age: float = 0.0

@onready var _sprite: ActorSprite = $Visual/Sprite


## Sets what to spawn, how long to warn, and the warning animation. Call before adding.
func setup(data: EnemyData, time: float, animation: AnimationDef) -> void:
	_data = data
	_time = time
	_animation = animation


func _ready() -> void:
	add_to_group(Groups.SPAWN_TELEGRAPH)
	if _animation != null:
		_sprite.build([_animation])
		_sprite.play_id(_animation.id)
	Events.enemy_spawn_warned.emit(global_position)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= _time:
		_spawn()


func _spawn() -> void:
	set_physics_process(false)
	var parent: Node2D = Game.content_parent(World.Id.COMBAT)
	if parent != null and _data != null and _data.scene != null:
		var enemy: Enemy = _data.scene.instantiate() as Enemy
		enemy.data = _data
		enemy.position = parent.to_local(global_position)
		parent.add_child(enemy)
	queue_free()
