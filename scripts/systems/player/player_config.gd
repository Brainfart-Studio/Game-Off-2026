class_name PlayerConfig
extends GameConfig
## Player tunables. Units are pixels and seconds. Defaults port Laser Beast.

@export_group("Run")
## Top horizontal speed (px/s).
@export var run_speed: float = 120.0
## Acceleration on the ground (px/s^2).
@export var ground_accel: float = 1800.0
## Deceleration on the ground (px/s^2).
@export var ground_decel: float = 2400.0
## Acceleration in the air (px/s^2).
@export var air_accel: float = 1400.0
## Deceleration in the air (px/s^2).
@export var air_decel: float = 900.0
## When false, a stick past the deadzone runs at full speed, like the d-pad.
@export var analog_run: bool = false

@export_group("Jump")
## Jump height (px). 56 is 3.5 tiles.
@export var jump_height: float = 56.0
## Time to reach the apex (s).
@export var time_to_apex: float = 0.36
## Vertical speed multiplier applied once when jump is released while rising.
@export var jump_cut_multiplier: float = 0.5
## How long a jump press is remembered before landing (s).
@export var jump_buffer_time: float = 0.2
## How long jumping is still allowed after leaving the floor (s).
@export var coyote_time: float = 0.2

@export_group("Gravity")
## Extra gravity multiplier while falling.
@export var fall_gravity_multiplier: float = 1.0
## Terminal fall speed (px/s).
@export var max_fall_speed: float = 420.0

@export_group("Apex")
## Band around zero vertical speed that counts as the apex (px/s).
@export var apex_threshold: float = 40.0
## Gravity multiplier inside the apex band while airborne.
@export var apex_gravity_multiplier: float = 0.3
## Horizontal speed multiplier inside the apex band.
@export var apex_speed_multiplier: float = 1.2

@export_group("Body")
## Collision body size (px). Feet sit at the node origin.
@export var body_size: Vector2 = Vector2(12, 22)

@export_group("Animation")
## Filled in by the animation branch.
@export var animations: Array[AnimationDef] = []


## Gravity (px/s^2) that reaches `jump_height` in `time_to_apex`.
func jump_gravity() -> float:
	return 2.0 * jump_height / (time_to_apex * time_to_apex)


## Launch speed (px/s) that reaches `jump_height` in `time_to_apex`.
func jump_velocity() -> float:
	return 2.0 * jump_height / time_to_apex


func validate() -> PackedStringArray:
	var warnings := PackedStringArray()
	if jump_height <= 0.0:
		warnings.append("jump_height must be positive")
	if time_to_apex <= 0.0:
		warnings.append("time_to_apex must be positive")
	if run_speed <= 0.0:
		warnings.append("run_speed must be positive")
	if max_fall_speed <= 0.0:
		warnings.append("max_fall_speed must be positive")
	if ground_accel <= 0.0 or ground_decel <= 0.0 or air_accel <= 0.0 or air_decel <= 0.0:
		warnings.append("accel and decel values must be positive")
	return warnings
