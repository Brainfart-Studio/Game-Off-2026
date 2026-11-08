class_name EconomyConfig
extends GameConfig
## Currency tunables. Units are pixels and seconds.

@export_group("Wallet")
## Currency the player has at the start of a run.
@export var start_currency: int = 0

@export_group("Drops")
## A drop never splits into more pickups than this.
@export var max_pickups_per_drop: int = 8
## Speed range of the pop when a pickup drops: x is the sideways range, y the upward range (px/s).
@export var pop_speed: Vector2 = Vector2(70, 110)
## How fast the pop slows down (1/s).
@export var pop_damping: float = 5.0

@export_group("Pickup")
## Time after dropping before a pickup can be collected or attracted (s).
@export var pickup_delay: float = 0.35
## Acceleration toward the magnet (px/s^2).
@export var fly_accel: float = 900.0
## Top speed toward the magnet (px/s).
@export var max_fly_speed: float = 360.0
## Distance to the magnet at which a pickup is collected (px).
@export var collect_distance: float = 8.0
## Time before an uncollected pickup disappears (s).
@export var lifetime: float = 12.0
## Time at the end of the lifetime during which a pickup blinks (s).
@export var blink_time: float = 2.0
## Blink speed (Hz).
@export var blink_rate: float = 10.0
## Animation of a pickup.
@export var pickup_animation: AnimationDef


func validate() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if start_currency < 0:
		warnings.append("start_currency must not be negative")
	if max_pickups_per_drop < 1:
		warnings.append("max_pickups_per_drop must be at least 1")
	if pop_speed.x < 0.0 or pop_speed.y < 0.0 or pop_damping < 0.0:
		warnings.append("pop values must not be negative")
	if pickup_delay < 0.0 or collect_distance < 0.0 or blink_time < 0.0:
		warnings.append("times and distances must not be negative")
	if fly_accel <= 0.0 or max_fly_speed <= 0.0:
		warnings.append("fly_accel and max_fly_speed must be positive")
	if lifetime <= 0.0:
		warnings.append("lifetime must be positive")
	if blink_rate <= 0.0:
		warnings.append("blink_rate must be positive")
	if blink_time > lifetime:
		warnings.append("blink_time must not exceed lifetime")
	if pickup_animation == null:
		warnings.append("pickup_animation must be set")
	return warnings
