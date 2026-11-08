class_name Player
extends CharacterBody2D
## Player body. Owns the physics verbs; states own the transitions.
## Frame order: input read, state physics_update (move, gravity, jump), move_and_slide.

@onready var stats: Stats = $Stats
@onready var input: PlayerInput = $PlayerInput
@onready var machine: StateMachine = $StateMachine
@onready var visual: Node2D = $Visual
@onready var sprite: ActorSprite = $Visual/Sprite
@onready var attack_hitbox: Hitbox = $AttackHitbox

## 1 faces right, -1 faces left. Only `visual` is flipped, never the body.
var facing: int = 1
## Seconds left in which a floor-leaving jump is still allowed.
var coyote_left: float = 0.0
## Seconds left in which a remembered jump press is still valid.
var buffer_left: float = 0.0
## Seconds left in which a remembered attack press is still valid.
var attack_buffer_left: float = 0.0
## The attack being played. Set by the Attack state, read by the animator.
var current_attack: AttackData
## True while an attack holds the facing.
var facing_locked: bool = false

## The player's config, read directly for non-numeric and structural values.
var config: PlayerConfig

var _jump_consumed: bool = false
var _jump_cut_done: bool = false
var _was_on_floor: bool = false
var _step_left: float = 0.0


func _ready() -> void:
	config = stats.config as PlayerConfig
	config.check()
	# The player drives the machine so the order stays: input, state, move_and_slide.
	machine.set_physics_process(false)
	_build_sprite()
	add_to_group(Groups.PLAYER)


## Flashes the sprite. Feedback calls this on the event's target.
func flash(color: Color, duration: float) -> void:
	sprite.flash(color, duration)


## Places the player and announces it. Run calls this once, after the arena is set up.
func spawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	Events.player_spawned.emit(self)


func _physics_process(delta: float) -> void:
	input.read(config.analog_run)
	_update_timers(delta)
	if machine.current != null:
		machine.current.physics_update(delta)
	move_and_slide()
	_emit_ground_events(delta)


## Horizontal movement toward the input direction, with ground or air accel and decel.
## `control` scales the accel and decel rate: 1 is normal, 0 gives no steering or braking.
func move(delta: float, control: float = 1.0) -> void:
	var speed: float = stats.value(&"run_speed")
	if is_apex():
		speed *= stats.value(&"apex_speed_multiplier")
	var target: float = input.move_x * speed
	var rate: float
	if is_on_floor():
		rate = stats.value(&"ground_accel") if input.move_x != 0.0 else stats.value(&"ground_decel")
	else:
		rate = stats.value(&"air_accel") if input.move_x != 0.0 else stats.value(&"air_decel")
	velocity.x = move_toward(velocity.x, target, rate * control * delta)
	if input.move_x != 0.0:
		set_facing(1 if input.move_x > 0.0 else -1)


## Jump gravity, scaled when falling and in the apex band, clamped to max fall speed.
func apply_gravity(delta: float) -> void:
	var height: float = stats.value(&"jump_height")
	var time: float = stats.value(&"time_to_apex")
	var gravity: float = PlayerConfig.gravity_for(height, time)
	if velocity.y > 0.0:
		gravity *= stats.value(&"fall_gravity_multiplier")
	if is_apex():
		gravity *= stats.value(&"apex_gravity_multiplier")
	velocity.y = minf(velocity.y + gravity * delta, stats.value(&"max_fall_speed"))


## True when a buffered or pressed jump can start now: on floor or in coyote time, not consumed.
func can_jump() -> bool:
	var wants_jump: bool = input.jump_pressed or buffer_left > 0.0
	var allowed: bool = is_on_floor() or coyote_left > 0.0
	return wants_jump and allowed and not _jump_consumed


## True when a remembered attack press is waiting.
func can_attack() -> bool:
	return attack_buffer_left > 0.0


## Uses up the remembered attack press.
func consume_attack() -> void:
	attack_buffer_left = 0.0


## Faces `direction` (1 right, -1 left). Ignored while an attack holds the facing.
func set_facing(direction: int) -> void:
	if facing_locked:
		return
	facing = direction
	visual.scale.x = float(direction)


## Launches the jump and consumes the buffer and coyote time.
func jump() -> void:
	velocity.y = -PlayerConfig.velocity_for(stats.value(&"jump_height"), stats.value(&"time_to_apex"))
	_jump_consumed = true
	_jump_cut_done = false
	buffer_left = 0.0
	coyote_left = 0.0
	Events.player_jumped.emit()


## Shortens the jump once, when jump is released while rising.
func cut_jump() -> void:
	if _jump_cut_done or not input.jump_released or velocity.y >= 0.0:
		return
	velocity.y *= stats.value(&"jump_cut_multiplier")
	_jump_cut_done = true


## True while airborne with vertical speed inside the apex band.
func is_apex() -> bool:
	return not is_on_floor() and absf(velocity.y) < stats.value(&"apex_threshold")


func _update_timers(delta: float) -> void:
	if is_on_floor():
		coyote_left = stats.value(&"coyote_time")
		if velocity.y >= 0.0:
			_jump_consumed = false
	else:
		coyote_left = maxf(coyote_left - delta, 0.0)
	if input.jump_pressed:
		buffer_left = stats.value(&"jump_buffer_time")
	else:
		buffer_left = maxf(buffer_left - delta, 0.0)
	if input.attack_pressed:
		attack_buffer_left = stats.value(&"attack_buffer_time")
	else:
		attack_buffer_left = maxf(attack_buffer_left - delta, 0.0)


## Emits `player_landed` on touching the floor and `player_stepped` every `step_interval` while
## running on it. The step countdown is 0 while stopped or airborne, so the first step is at once.
func _emit_ground_events(delta: float) -> void:
	var on_floor: bool = is_on_floor()
	if on_floor and not _was_on_floor:
		Events.player_landed.emit()
	_was_on_floor = on_floor
	if on_floor and absf(velocity.x) > 1.0:
		_step_left -= delta
		if _step_left <= 0.0:
			Events.player_stepped.emit()
			_step_left = stats.value(&"step_interval")
	else:
		_step_left = 0.0


func _build_sprite() -> void:
	sprite.build(config.animations)
	sprite.play_id(&"player_idle")
