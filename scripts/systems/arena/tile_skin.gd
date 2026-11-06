class_name TileSkin
extends TileMapLayer
## Visual skin for one world. Copies the used cells of the shared `Collision` layer and
## picks an atlas cell from each cell's empty neighbors. Has no collision.

const TILE_SIZE: Vector2i = Vector2i(16, 16)
const ATLAS_SIZE: Vector2i = Vector2i(48, 32)

@export var texture_path: String = ""
@export var id: String = ""
@export var collision_path: NodePath = ^"../../Collision"


func _ready() -> void:
	# Deferred so the Arena has filled its superflat default first.
	_build.call_deferred()


func _build() -> void:
	var source: TileMapLayer = get_node(collision_path) as TileMapLayer
	var tex: Texture2D = AssetLoader.texture(texture_path, ATLAS_SIZE, id)
	tile_set = _make_tile_set(tex)
	clear()
	var used: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in source.get_used_cells():
		used[cell] = true
	for cell: Vector2i in used:
		var column: int = 1
		if not used.has(cell + Vector2i.LEFT):
			column = 0
		elif not used.has(cell + Vector2i.RIGHT):
			column = 2
		var row: int = 0 if not used.has(cell + Vector2i.UP) else 1
		set_cell(cell, 0, Vector2i(column, row))


func _make_tile_set(tex: Texture2D) -> TileSet:
	var result: TileSet = TileSet.new()
	result.tile_size = TILE_SIZE
	var atlas: TileSetAtlasSource = TileSetAtlasSource.new()
	atlas.texture = tex
	atlas.texture_region_size = TILE_SIZE
	for x: int in 3:
		for y: int in 2:
			atlas.create_tile(Vector2i(x, y))
	result.add_source(atlas, 0)
	return result
