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

@export_group("Combat")
## Health the player starts a run with.
@export var max_health: int = 3
## Invulnerability after a hit (s).
@export var hurt_iframes: float = 1.0
## Time the player cannot act after a hit (s).
@export var hurt_stun: float = 0.3
## Multiplier on the knockback taken from a hit.
@export var hurt_knockback_multiplier: float = 1.0
## Blink speed while invulnerable (Hz).
@export var iframe_blink_rate: float = 12.0
## How long an attack press is remembered (s).
@export var attack_buffer_time: float = 0.12
## Attack speed multiplier. Above 1 shortens startup, active, and recovery.
@export var attack_speed: float = 1.0
## Multiplier on the hitbox size and offset.
@export var attack_reach: float = 1.0
## Multiplier on attack damage.
@export var attack_damage: float = 1.0
## The player's attacks.
@export var moveset: Moveset

@export_group("Audio")
## Time between footstep sounds while running (s).
@export var step_interval: float = 0.3

@export_group("Animation")
## One def per player animation, looked up by id.
@export var animations: Array[AnimationDef] = []


## Gravity (px/s^2) that reaches `height` in `time`.
static func gravity_for(height: float, time: float) -> float:
	return 2.0 * height / (time * time)


## Launch speed (px/s) that reaches `height` in `time`.
static func velocity_for(height: float, time: float) -> float:
	return 2.0 * height / time


## Gravity (px/s^2) that reaches `jump_height` in `time_to_apex`.
func jump_gravity() -> float:
	return gravity_for(jump_height, time_to_apex)


## Launch speed (px/s) that reaches `jump_height` in `time_to_apex`.
func jump_velocity() -> float:
	return velocity_for(jump_height, time_to_apex)


func validate() -> PackedStringArray:
	var warnings := PackedStringArray()
	if jump_height <= 0.0:
		warnings.append("jump_height must be positive")
	if time_to_apex <= 0.0:
		warnings.append("time_to_apex must be positive")
	if run_speed <= 0.0:
		warnings.append("run_speed must be positive")
	if step_interval <= 0.0:
		warnings.append("step_interval must be positive")
	if max_fall_speed <= 0.0:
		warnings.append("max_fall_speed must be positive")
	if ground_accel <= 0.0 or ground_decel <= 0.0 or air_accel <= 0.0 or air_decel <= 0.0:
		warnings.append("accel and decel values must be positive")
	if max_health < 1:
		warnings.append("max_health must be at least 1")
	if hurt_iframes < 0.0 or hurt_stun < 0.0 or attack_buffer_time < 0.0:
		warnings.append("hurt_iframes, hurt_stun, and attack_buffer_time must not be negative")
	if hurt_knockback_multiplier < 0.0 or attack_damage < 0.0:
		warnings.append("hurt_knockback_multiplier and attack_damage must not be negative")
	if iframe_blink_rate <= 0.0:
		warnings.append("iframe_blink_rate must be positive")
	if attack_speed <= 0.0 or attack_reach <= 0.0:
		warnings.append("attack_speed and attack_reach must be positive")
	if moveset == null:
		warnings.append("moveset is not set")
	else:
		warnings.append_array(moveset.validate())
	for def: AnimationDef in animations:
		if def == null:
			warnings.append("animations has an empty entry")
			continue
		if def.frames < 1:
			warnings.append("animation '%s' needs at least 1 frame" % def.id)
		if def.path.is_empty():
			warnings.append("animation '%s' has an empty path" % def.id)
	return warnings
