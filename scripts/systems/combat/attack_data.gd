class_name AttackData
extends GameConfig
## One attack: its animation, hitbox, timing, damage, knockback, and effects. Units are px and seconds.

## Unique id of the attack.
@export var id: StringName = &""
## Animation the attacker plays.
@export var animation: StringName = &""

@export_group("Hitbox")
## Hitbox size (px).
@export var hitbox_size: Vector2 = Vector2(24, 16)
## Hitbox center from the attacker's feet, facing right (px).
@export var hitbox_offset: Vector2 = Vector2(16, -12)

@export_group("Timing")
## Time before the hitbox turns on (s).
@export var startup: float = 0.05
## Time the hitbox stays on (s).
@export var active: float = 0.1
## Time after the hitbox turns off before the attacker is free (s).
@export var recovery: float = 0.15

@export_group("Hit")
## Health removed.
@export var damage: int = 1
## Knockback direction in degrees: 0 forward, -90 up, 90 down.
@export var knockback_angle: float = -30.0
## Knockback speed (px/s).
@export var knockback_force: float = 160.0
## Share of normal acceleration kept during the attack, 0 to 1.
@export var move_control: float = 0.5
## Upward speed given to the attacker on a hit (px/s).
@export var pogo_velocity: float = 0.0
## Feedback entry id played on a hit.
@export var hit_feedback: StringName = &"hit_light"
## Sound id played on a hit.
@export var hit_sound: StringName = &"hit_enemy"
## Tags copied to the damage info.
@export var tags: Array[StringName] = []


## Startup time at attack speed `speed` (s).
func startup_time(speed: float) -> float:
	return startup / maxf(speed, 0.01)


## Active time at attack speed `speed` (s).
func active_time(speed: float) -> float:
	return active / maxf(speed, 0.01)


## Recovery time at attack speed `speed` (s).
func recovery_time(speed: float) -> float:
	return recovery / maxf(speed, 0.01)


## Whole attack time at attack speed `speed` (s).
func total_time(speed: float) -> float:
	return startup_time(speed) + active_time(speed) + recovery_time(speed)


func validate() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if id == &"":
		warnings.append("id is not set")
	if hitbox_size.x <= 0.0 or hitbox_size.y <= 0.0:
		warnings.append("hitbox_size must be positive")
	if startup < 0.0 or recovery < 0.0:
		warnings.append("startup and recovery must not be negative")
	if active <= 0.0:
		warnings.append("active must be above 0")
	if damage < 0:
		warnings.append("damage must not be negative")
	if move_control < 0.0 or move_control > 1.0:
		warnings.append("move_control must be between 0 and 1")
	return warnings
