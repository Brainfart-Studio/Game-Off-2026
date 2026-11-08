class_name Enemy
extends CharacterBody2D
## Enemy body. Owns the physics verbs; states own the transitions. Set `data` before the enemy
## enters the tree (the spawner does). Frame order: state physics_update, move_and_slide.

## Share of the body size the contact hitbox covers.
const CONTACT_SCALE: float = 0.8

## The enemy's type. Never saved in a scene: that would make a resource cycle with `data.scene`.
@export var data: EnemyData
## State entered when a hit stun ends.
@export var resume_state: StringName = &"Chase"

## 1 faces right, -1 faces left. Only `visual` is flipped, never the body.
var facing: int = 1
## The last hit the enemy took. Read by the Hurt and Die states.
var last_hit: DamageInfo

@onready var stats: Stats = $Stats
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var contact_hitbox: Hitbox = $ContactHitbox
@onready var machine: StateMachine = $StateMachine
@onready var visual: Node2D = $Visual
@onready var sprite: ActorSprite = $Visual/Sprite
@onready var ledge_check: RayCast2D = $Visual/LedgeCheck


func _ready() -> void:
	if data == null:
		push_error("Enemy: data must be set before the enemy enters the tree")
		return
	stats.config = data
	data.check()
	_size_shape($CollisionShape2D, data.body_size)
	_size_shape($Hurtbox/Shape, data.body_size)
	var contact_size: Vector2 = data.body_size * CONTACT_SCALE
	contact_hitbox.set_contact(
		contact_size,
		Vector2(0.0, -data.body_size.y / 2.0),
		roundi(stats.value(&"contact_damage")),
		stats.value(&"contact_knockback_force"),
		data.contact_knockback_angle
	)
	# The enemy drives the machine so the order stays: state, move_and_slide.
	machine.set_physics_process(false)
	health.setup()
	sprite.build(data.animations)
	add_to_group(Groups.ENEMY)
	hurtbox.hurt.connect(_on_hurt)
	health.died.connect(_on_died)
	Events.enemy_spawned.emit(self)


func _physics_process(delta: float) -> void:
	if data == null:
		return
	if machine.current != null:
		machine.current.physics_update(delta)
	move_and_slide()


## Flashes the sprite. Feedback calls this on the event's target.
func flash(color: Color, duration: float) -> void:
	sprite.flash(color, duration)


## Gravity, clamped to the max fall speed.
func apply_gravity(delta: float) -> void:
	var fall: float = velocity.y + stats.value(&"gravity") * delta
	velocity.y = minf(fall, stats.value(&"max_fall_speed"))


## Accelerates toward `speed` in `direction` (1 right, -1 left) and faces that way.
func walk(direction: int, speed: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, float(direction) * speed, stats.value(&"accel") * delta)
	if direction != 0:
		set_facing(direction)


## Brakes to a stop.
func stop(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, stats.value(&"accel") * delta)


## Faces `direction` (1 right, -1 left).
func set_facing(direction: int) -> void:
	facing = direction
	visual.scale.x = float(direction)


## True while the player exists.
func has_target() -> bool:
	return Game.has_player()


## Global position of the player.
func target_position() -> Vector2:
	return Game.player.global_position


## True when the player is within `reach` horizontally and vertically.
func target_in(reach: Vector2) -> bool:
	if not has_target():
		return false
	var offset: Vector2 = target_position() - global_position
	return absf(offset.x) <= reach.x and absf(offset.y) <= reach.y


## True when pressed against a wall in the facing direction.
func at_wall() -> bool:
	return is_on_wall() and get_wall_normal().x * float(facing) < 0.0


## True when on the floor with no floor ahead.
func at_ledge() -> bool:
	if not is_on_floor():
		return false
	ledge_check.force_raycast_update()
	return not ledge_check.is_colliding()


func _size_shape(shape: CollisionShape2D, size: Vector2) -> void:
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = Vector2(0.0, -size.y / 2.0)


func _on_hurt(info: DamageInfo) -> void:
	last_hit = info
	Events.hit_landed.emit(info)
	if not health.is_dead():
		machine.transition_to(&"Hurt")


## Health emits `died` before the hurtbox emits `hurt`, so Die is entered first. `last_hit` is
## set here so the Die state already has the killing blow.
func _on_died(info: DamageInfo) -> void:
	last_hit = info
	machine.transition_to(&"Die")
