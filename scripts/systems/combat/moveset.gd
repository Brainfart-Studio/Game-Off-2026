class_name Moveset
extends GameConfig
## The attacks of one fighter, by where it stands and which way the input points.

enum Direction { NEUTRAL, SIDE, UP, DOWN }

@export_group("Ground")
@export var ground_neutral: AttackData
@export var ground_side: AttackData
@export var ground_up: AttackData
@export var ground_down: AttackData

@export_group("Air")
@export var air_neutral: AttackData
@export var air_side: AttackData
@export var air_up: AttackData
@export var air_down: AttackData


## Attack direction for an input vector. Up and down win over side when at least as strong.
static func direction_from(input: Vector2, threshold: float = 0.5) -> Direction:
	var vertical: float = absf(input.y)
	if input.y <= -threshold and vertical >= absf(input.x):
		return Direction.UP
	if input.y >= threshold and vertical >= absf(input.x):
		return Direction.DOWN
	if absf(input.x) >= threshold:
		return Direction.SIDE
	return Direction.NEUTRAL


## The attack for a stance and direction. Air falls back to the ground slot of the same direction,
## then to `ground_neutral`; ground falls back to `ground_neutral`.
func attack_for(grounded: bool, direction: Direction) -> AttackData:
	var ground_slot: AttackData = _ground(direction)
	if grounded:
		return ground_slot if ground_slot != null else ground_neutral
	var air_slot: AttackData = _air(direction)
	if air_slot != null:
		return air_slot
	return ground_slot if ground_slot != null else ground_neutral


func validate() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if ground_neutral == null:
		warnings.append("ground_neutral is not set")
	var slots: Dictionary[String, AttackData] = {
		"ground_neutral": ground_neutral,
		"ground_side": ground_side,
		"ground_up": ground_up,
		"ground_down": ground_down,
		"air_neutral": air_neutral,
		"air_side": air_side,
		"air_up": air_up,
		"air_down": air_down,
	}
	for slot: String in slots:
		if slots[slot] == null:
			continue
		for warning: String in slots[slot].validate():
			warnings.append("%s: %s" % [slot, warning])
	return warnings


func _ground(direction: Direction) -> AttackData:
	match direction:
		Direction.SIDE:
			return ground_side
		Direction.UP:
			return ground_up
		Direction.DOWN:
			return ground_down
	return ground_neutral


func _air(direction: Direction) -> AttackData:
	match direction:
		Direction.SIDE:
			return air_side
		Direction.UP:
			return air_up
		Direction.DOWN:
			return air_down
	return air_neutral
