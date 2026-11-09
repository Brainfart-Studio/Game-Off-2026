class_name Hitbox
extends Area2D
## Deals hits to the hurtboxes of the other team. Two modes: an attack (`activate`) hits each
## hurtbox once; a contact box (`set_contact`) hits every physics frame, and the target's
## invulnerability gates repeats.

## A hurtbox took a hit from this hitbox.
signal landed(info: DamageInfo)

@export var team: Team.Id = Team.Id.PLAYER

var _active: bool = false
var _contact: bool = false
var _facing: int = 1
var _amount: int = 0
var _force: float = 0.0
var _angle: float = 0.0
var _attack_id: StringName = &""
var _tags: Array[StringName] = []
var _feedback: StringName = &""
var _sound: StringName = &""
## Instance ids of the hurtboxes already hit by the current activation.
var _hit: Dictionary[int, bool] = {}
var _shape: CollisionShape2D


func _ready() -> void:
	collision_layer = Layers.PLAYER_HITBOX if team == Team.Id.PLAYER else Layers.ENEMY_HITBOX
	collision_mask = Layers.ENEMY_HURTBOX if team == Team.Id.PLAYER else Layers.PLAYER_HURTBOX
	monitorable = false
	monitoring = true
	_shape = get_node_or_null("Shape") as CollisionShape2D
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.name = "Shape"
		add_child(_shape)
	var rect: RectangleShape2D = _shape.shape as RectangleShape2D
	_shape.shape = rect.duplicate() as RectangleShape2D if rect != null else RectangleShape2D.new()
	_shape.disabled = true


func _physics_process(_delta: float) -> void:
	if not _active:
		return
	for area: Area2D in get_overlapping_areas():
		var hurtbox: Hurtbox = area as Hurtbox
		if hurtbox == null:
			continue
		if not _contact and _hit.has(hurtbox.get_instance_id()):
			continue
		var info: DamageInfo = _make_info(hurtbox)
		if hurtbox.receive(info):
			if not _contact:
				_hit[hurtbox.get_instance_id()] = true
			landed.emit(info)


## Starts an attack hit. `facing` is 1 for right and -1 for left; `reach` scales size and offset.
func activate(data: AttackData, facing: int, damage_amount: int, reach: float = 1.0) -> void:
	_contact = false
	_facing = facing
	_amount = damage_amount
	_force = data.knockback_force
	_angle = data.knockback_angle
	_attack_id = data.id
	_tags = data.tags.duplicate()
	_feedback = data.hit_feedback
	_sound = data.hit_sound
	_place(data.hitbox_size * reach, Vector2(data.hitbox_offset.x * facing * reach, data.hitbox_offset.y))
	_hit.clear()
	_active = true
	_shape.set_deferred("disabled", false)


## Starts a contact hit that repeats every physics frame. Knockback points away from this box.
func set_contact(size: Vector2, offset: Vector2, damage_amount: int, force: float, angle: float) -> void:
	_contact = true
	_facing = 1
	_amount = damage_amount
	_force = force
	_angle = angle
	_attack_id = &""
	_tags = []
	_feedback = &""
	_sound = &""
	_place(size, offset)
	_hit.clear()
	_active = true
	_shape.set_deferred("disabled", false)


func deactivate() -> void:
	_active = false
	_hit.clear()
	_shape.set_deferred("disabled", true)


func is_active() -> bool:
	return _active


func _place(size: Vector2, offset: Vector2) -> void:
	(_shape.shape as RectangleShape2D).size = size
	_shape.position = offset


func _make_info(hurtbox: Hurtbox) -> DamageInfo:
	var side: int = _facing
	if _contact:
		side = 1 if hurtbox.global_position.x >= _shape.global_position.x else -1
	var direction: Vector2 = Vector2.from_angle(deg_to_rad(_angle))
	direction.x *= side
	var info: DamageInfo = DamageInfo.new()
	info.amount = _amount
	info.knockback = direction * _force
	info.source = get_parent() as Node2D
	info.attack_id = _attack_id
	info.position = (_shape.global_position + hurtbox.global_position) * 0.5
	info.tags = _tags.duplicate()
	info.feedback = _feedback
	info.sound = _sound
	return info
