class_name EnemyData
extends GameConfig
## One enemy type's tunables. Units are pixels and seconds. The spawner sets `data` on an enemy
## before it enters the tree.

@export_group("Identity")
## Enemy id. Also the prefix of its animation ids.
@export var id: StringName = &""
## Scene the spawner instantiates.
@export var scene: PackedScene

@export_group("Health")
## Hit points.
@export var max_health: int = 3
## Share of the knockback taken that is ignored, 0 to 1.
@export_range(0.0, 1.0) var knockback_resistance: float = 0.0
## Time the enemy cannot act after a hit (s).
@export var hurt_stun: float = 0.25
## Time from death until the enemy is removed (s).
@export var death_time: float = 0.5

@export_group("Movement")
## Patrol speed (px/s).
@export var move_speed: float = 40.0
## Chase speed (px/s).
@export var chase_speed: float = 70.0
## Acceleration toward the target speed (px/s^2).
@export var accel: float = 600.0
## Gravity (px/s^2).
@export var gravity: float = 900.0
## Terminal fall speed (px/s).
@export var max_fall_speed: float = 420.0

@export_group("Senses")
## Horizontal and vertical distance at which the enemy spots the player (px).
@export var detect_range: Vector2 = Vector2(160, 48)
## Distance beyond which a chasing enemy gives up (px).
@export var lose_range: float = 220.0

@export_group("Contact")
## Damage dealt by touching the player.
@export var contact_damage: int = 1
## Knockback speed on the player (px/s).
@export var contact_knockback_force: float = 180.0
## Knockback direction (deg, 0 is away from the enemy, negative is up).
@export var contact_knockback_angle: float = -45.0

@export_group("Rewards")
## Currency dropped on death.
@export var currency_drop: int = 3
## Score for a kill.
@export var score_value: int = 100

@export_group("Body")
## Collision body size (px). Feet sit at the node origin.
@export var body_size: Vector2 = Vector2(14, 20)
## Animations the sprite builds.
@export var animations: Array[AnimationDef] = []


## Animation id for `suffix`: `<id>_<suffix>`.
func animation_id(suffix: String) -> StringName:
	return StringName("%s_%s" % [id, suffix])


func validate() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if id == &"":
		warnings.append("id must be set")
	if scene == null:
		warnings.append("scene must be set")
	if max_health <= 0:
		warnings.append("max_health must be positive")
	if move_speed <= 0.0 or chase_speed <= 0.0:
		warnings.append("speeds must be positive")
	if accel <= 0.0 or gravity <= 0.0 or max_fall_speed <= 0.0:
		warnings.append("accel, gravity, and max_fall_speed must be positive")
	if body_size.x <= 0.0 or body_size.y <= 0.0:
		warnings.append("body_size must be positive")
	if detect_range.x <= 0.0 or detect_range.y <= 0.0 or lose_range <= 0.0:
		warnings.append("detect_range and lose_range must be positive")
	if knockback_resistance < 0.0 or knockback_resistance > 1.0:
		warnings.append("knockback_resistance must be 0 to 1")
	for def: AnimationDef in animations:
		if def == null:
			warnings.append("animations has an empty entry")
			continue
		if def.frames < 1:
			warnings.append("animation '%s' needs at least 1 frame" % def.id)
		if def.path.is_empty():
			warnings.append("animation '%s' has an empty path" % def.id)
	return warnings
