class_name Player
extends CharacterBody2D
## Player body. Owns the physics verbs; states own the transitions.
## Frame order: input read, state physics_update (move, gravity, jump), move_and_slide.

@onready var stats: Stats = $Stats
@onready var input: PlayerInput = $PlayerInput
@onready var machine: StateMachine = $StateMachine
@onready var visual: Node2D = $Visual

## 1 faces right, -1 faces left. Only `visual` is flipped, never the body.
var facing: int = 1


func _ready() -> void:
	stats.config.check()
	# The player drives the machine so the order stays: input, state, move_and_slide.
	machine.set_physics_process(false)
	var spawn: Node2D = get_tree().get_first_node_in_group(&"player_spawn") as Node2D
	if spawn != null:
		global_position = spawn.global_position
	Events.player_spawned.emit(self)


func _physics_process(delta: float) -> void:
	input.read(stats.value(&"analog_run") > 0.5)
	if machine.current != null:
		machine.current.physics_update(delta)
	move_and_slide()


## Horizontal movement toward the input direction, with ground or air accel and decel.
func move(delta: float) -> void:
	var speed: float = stats.value(&"run_speed")
	if is_apex():
		speed *= stats.value(&"apex_speed_multiplier")
	var target: float = input.move_x * speed
	var rate: float
	if is_on_floor():
		rate = stats.value(&"ground_accel") if input.move_x != 0.0 else stats.value(&"ground_decel")
	else:
		rate = stats.value(&"air_accel") if input.move_x != 0.0 else stats.value(&"air_decel")
	velocity.x = move_toward(velocity.x, target, rate * delta)
	if input.move_x != 0.0:
		_set_facing(1 if input.move_x > 0.0 else -1)


## Jump gravity, scaled when falling and in the apex band, clamped to max fall speed.
func apply_gravity(delta: float) -> void:
	var height: float = stats.value(&"jump_height")
	var time: float = stats.value(&"time_to_apex")
	var gravity: float = 2.0 * height / (time * time)
	if velocity.y > 0.0:
		gravity *= stats.value(&"fall_gravity_multiplier")
	if is_apex():
		gravity *= stats.value(&"apex_gravity_multiplier")
	velocity.y = minf(velocity.y + gravity * delta, stats.value(&"max_fall_speed"))


## True while airborne with vertical speed inside the apex band.
func is_apex() -> bool:
	return not is_on_floor() and absf(velocity.y) < stats.value(&"apex_threshold")


func _set_facing(direction: int) -> void:
	facing = direction
	visual.scale.x = float(direction)
