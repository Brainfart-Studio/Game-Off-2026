class_name Pickup
extends Area2D
## A currency pickup. It pops out of a drop, waits `pickup_delay`, then is pulled toward a
## player magnet or collected by touching the player. Time is counted in `_physics_process`,
## so a frozen world stops it.

var _amount: int = 1
var _config: EconomyConfig
var _velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0
var _target: Node2D
var _fly_speed: float = 0.0
var _collected: bool = false

@onready var _visual: Node2D = $Visual
@onready var _sprite: ActorSprite = $Visual/Sprite
@onready var _shape: CollisionShape2D = $CollisionShape2D


## Sets the value, the tunables, and the pop velocity. Call before adding.
func setup(amount: int, config: EconomyConfig, velocity: Vector2) -> void:
	_amount = amount
	_config = config
	_velocity = velocity


func _ready() -> void:
	if _config == null:
		_config = EconomyConfig.new()
	collision_layer = Layers.PICKUP
	collision_mask = Layers.PLAYER
	monitorable = false
	add_to_group(Groups.PICKUP)
	if _config.pickup_animation != null:
		_sprite.build([_config.pickup_animation])
		_sprite.play_id(_config.pickup_animation.id)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= _config.lifetime:
		queue_free()
		return
	_update_blink()
	if _age >= _config.pickup_delay and not is_instance_valid(_target):
		_target = _find_magnet()
	if is_instance_valid(_target):
		_fly(delta)
	else:
		_pop(delta)
		if _age >= _config.pickup_delay and _touches_player():
			_collect()


func _update_blink() -> void:
	var blinking: bool = _age >= _config.lifetime - _config.blink_time
	_visual.visible = not blinking or fmod(_age * _config.blink_rate, 1.0) < 0.5


func _pop(delta: float) -> void:
	position += _velocity * delta
	_velocity = _velocity.lerp(Vector2.ZERO, 1.0 - exp(-_config.pop_damping * delta))


func _fly(delta: float) -> void:
	_fly_speed = minf(_fly_speed + _config.fly_accel * delta, _config.max_fly_speed)
	var to_target: Vector2 = _target.global_position - _shape.global_position
	if to_target.length() <= _config.collect_distance:
		_collect()
		return
	global_position += to_target.normalized() * minf(_fly_speed * delta, to_target.length())


func _find_magnet() -> Node2D:
	for area: Area2D in get_overlapping_areas():
		if area.is_in_group(Groups.MAGNET):
			return area
	return null


func _touches_player() -> bool:
	for body: Node2D in get_overlapping_bodies():
		if body.is_in_group(Groups.PLAYER):
			return true
	return false


func _collect() -> void:
	if _collected:
		return
	_collected = true
	set_physics_process(false)
	Events.currency_collected.emit(_amount)
	queue_free()
