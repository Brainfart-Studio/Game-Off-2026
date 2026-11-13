class_name AnimationDef
extends Resource
## One sprite-strip animation: a horizontal strip of `frames` frames.

@export var id: StringName
@export var path: String
@export var frame_size: Vector2i = Vector2i(24, 24)
@export var frames: int = 1
@export var fps: float = 8.0
@export var loop: bool = true
## Shift of the drawn frames from the feet-at-origin position (px, positive y is down). For
## frames where the character is not at the bottom edge.
@export var draw_offset: Vector2i = Vector2i.ZERO
