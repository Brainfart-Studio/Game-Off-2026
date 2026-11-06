@tool
class_name ArenaBounds
extends Node2D
## Constraint system for an arena (R-040): invisible walls on the enabled edges and the
## rect other systems (camera) read through `Events.arena_bounds_changed`.

## Local rect size, measured from this node's position.
@export var size: Vector2 = Vector2(960, 270):
	set(value):
		size = value
		queue_redraw()
@export var wall_left: bool = true
@export var wall_right: bool = true
@export var ceiling: bool = true
@export var wall_thickness: float = 32.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_build_walls()
	# Deferred so listeners added in the same frame (camera) receive it.
	Events.arena_bounds_changed.emit.call_deferred(global_rect())


func global_rect() -> Rect2:
	return Rect2(global_position, size)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.8, 0.2), false, 1.0)


func _build_walls() -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.name = "Walls"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var t: float = wall_thickness
	if wall_left:
		_add_wall(body, Rect2(-t, -t, t, size.y + t))
	if wall_right:
		_add_wall(body, Rect2(size.x, -t, t, size.y + t))
	if ceiling:
		_add_wall(body, Rect2(-t, -t, size.x + 2.0 * t, t))


func _add_wall(body: StaticBody2D, rect: Rect2) -> void:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = rect.size
	var owner_shape: CollisionShape2D = CollisionShape2D.new()
	owner_shape.shape = shape
	owner_shape.position = rect.get_center()
	body.add_child(owner_shape)
