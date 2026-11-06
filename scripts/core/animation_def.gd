class_name AnimationDef
extends Resource
## One sprite-strip animation: a horizontal strip of `frames` frames.

@export var id: StringName
@export var path: String
@export var frame_size: Vector2i = Vector2i(32, 32)
@export var frames: int = 1
@export var fps: float = 8.0
@export var loop: bool = true
