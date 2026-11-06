class_name GameCamera
extends Camera2D
## Follow camera. Tracks the player from `Events.player_spawned` and eases a
## look-ahead offset toward the player's facing.

@export var config: CameraConfig

const VIEW_SIZE: Vector2 = Vector2(480, 270)

var _target: Player
var _look_ahead: float = 0.0


func _ready() -> void:
	config.check()
	position_smoothing_enabled = true
	position_smoothing_speed = config.smoothing_speed
	drag_horizontal_enabled = true
	drag_vertical_enabled = true
	drag_left_margin = config.drag_margin_h
	drag_right_margin = config.drag_margin_h
	drag_top_margin = config.drag_margin_v
	drag_bottom_margin = config.drag_margin_v
	Events.player_spawned.connect(_on_player_spawned)
	Events.arena_bounds_changed.connect(_on_arena_bounds_changed)


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var goal: float = config.look_ahead_x * float(_target.facing)
	_look_ahead = lerpf(_look_ahead, goal, 1.0 - exp(-config.look_ahead_speed * delta))
	global_position = _target.global_position + Vector2(_look_ahead, 0.0)


func _on_player_spawned(player: Node2D) -> void:
	_target = player as Player
	if _target == null:
		return
	_look_ahead = config.look_ahead_x * float(_target.facing)
	global_position = _target.global_position + Vector2(_look_ahead, 0.0)
	reset_smoothing()


func _on_arena_bounds_changed(bounds: Rect2) -> void:
	var x: Vector2 = _axis_limits(bounds.position.x, bounds.end.x, VIEW_SIZE.x)
	var y: Vector2 = _axis_limits(bounds.position.y, bounds.end.y, VIEW_SIZE.y)
	limit_left = roundi(x.x)
	limit_right = roundi(x.y)
	limit_top = roundi(y.x)
	limit_bottom = roundi(y.y)


## Limits for one axis. If the arena is smaller than the view, centers on the arena.
func _axis_limits(low: float, high: float, view: float) -> Vector2:
	if high - low >= view:
		return Vector2(low, high)
	var center: float = (low + high) * 0.5
	return Vector2(center - view * 0.5, center + view * 0.5)
