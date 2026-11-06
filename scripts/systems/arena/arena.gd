class_name Arena
extends Node2D
## Test arena root. Owns the shared collision layer; skins and worlds read from it.

## Width of the superflat default floor, in tiles.
@export var width_tiles: int = 60
## First row of the superflat default floor (two rows thick).
@export var floor_top: int = 15

@onready var collision: TileMapLayer = $Collision


func _ready() -> void:
	if collision.get_used_cells().is_empty():
		_fill_superflat()
	collision.visible = false


func _fill_superflat() -> void:
	for x: int in width_tiles:
		for y: int in range(floor_top, floor_top + 2):
			collision.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
