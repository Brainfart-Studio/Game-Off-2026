class_name Arena
extends Node2D
## Test arena root. Owns the shared collision layer; skins and worlds read from it.

@onready var collision: TileMapLayer = $Collision


func _ready() -> void:
	collision.visible = false
