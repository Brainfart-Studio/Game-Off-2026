class_name Arena
extends Node2D
## Test arena root. Owns the shared collision layer; skins and worlds read from it.

## Width of the superflat default floor, in tiles.
@export var width_tiles: int = 60
## First row of the superflat default floor (two rows thick).
@export var floor_top: int = 15

@onready var collision: TileMapLayer = $Collision
@onready var _bounds: ArenaBounds = $ArenaBounds
@onready var _peaceful_skin: TileSkin = $PeacefulWorld/Skin
@onready var _combat_skin: TileSkin = $CombatWorld/Skin
@onready var _peaceful_content: Node2D = $PeacefulWorld/Content
@onready var _combat_content: Node2D = $CombatWorld/Content


## Builds the arena. Run calls this once, after every child is ready.
func setup() -> void:
	if collision.get_used_cells().is_empty():
		_fill_superflat()
	collision.visible = false
	_peaceful_skin.build()
	_combat_skin.build()
	_bounds.setup()
	Game.register_content(World.Id.PEACEFUL, _peaceful_content)
	Game.register_content(World.Id.COMBAT, _combat_content)


func player_spawn_position() -> Vector2:
	return $PlayerSpawn.global_position


func _fill_superflat() -> void:
	for x: int in width_tiles:
		for y: int in range(floor_top, floor_top + 2):
			collision.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
