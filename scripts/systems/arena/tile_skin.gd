@tool
class_name TileSkin
extends TileMapLayer
## Visual skin for one world. Copies the used cells of the shared `Collision` layer and
## picks an atlas cell from each cell's empty neighbors. Has no collision.
## In the editor it only draws a preview over the collision cells and stores no cells.

const TILE_SIZE: Vector2i = Vector2i(16, 16)
const ATLAS_SIZE: Vector2i = Vector2i(48, 32)

@export var texture_path: String = "":
	set(value):
		texture_path = value
		queue_redraw()
@export var id: String = ""
@export var collision_path: NodePath = ^"../../Collision"

## Collision layer the editor preview follows. Null outside the editor.
var _preview_source: TileMapLayer


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	_preview_source = get_node_or_null(collision_path) as TileMapLayer
	if _preview_source != null:
		_preview_source.changed.connect(queue_redraw)
	queue_redraw()


## Copies the shared collision cells and picks the atlas cells. Arena calls this in `setup()`,
## after the superflat default is filled.
func build() -> void:
	var source: TileMapLayer = get_node(collision_path) as TileMapLayer
	var tex: Texture2D = AssetLoader.texture(texture_path, ATLAS_SIZE, id)
	tile_set = _make_tile_set(tex)
	clear()
	var used: Dictionary[Vector2i, bool] = used_cells(source)
	for cell: Vector2i in used:
		set_cell(cell, 0, atlas_cell(cell, used))


## The used cells of `layer` as a set.
static func used_cells(layer: TileMapLayer) -> Dictionary[Vector2i, bool]:
	var used: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in layer.get_used_cells():
		used[cell] = true
	return used


## The atlas cell for `cell`: the column from its left and right neighbors (edge, fill, edge),
## the row from the one above (top or fill).
static func atlas_cell(cell: Vector2i, used: Dictionary[Vector2i, bool]) -> Vector2i:
	var column: int = 1
	if not used.has(cell + Vector2i.LEFT):
		column = 0
	elif not used.has(cell + Vector2i.RIGHT):
		column = 2
	var row: int = 0 if not used.has(cell + Vector2i.UP) else 1
	return Vector2i(column, row)


## Editor only: draws the skin over the collision cells, so the scene shows the world without
## saving any cells or generated tile set into it.
func _draw() -> void:
	if not Engine.is_editor_hint() or _preview_source == null:
		return
	var tex: Texture2D = AssetLoader.texture(texture_path, ATLAS_SIZE, id)
	var used: Dictionary[Vector2i, bool] = used_cells(_preview_source)
	var half: Vector2 = Vector2(TILE_SIZE) / 2.0
	for cell: Vector2i in used:
		var corner: Vector2 = _preview_source.to_global(_preview_source.map_to_local(cell) - half)
		var source_rect: Rect2 = Rect2(Vector2(atlas_cell(cell, used) * TILE_SIZE), Vector2(TILE_SIZE))
		draw_texture_rect_region(tex, Rect2(to_local(corner), Vector2(TILE_SIZE)), source_rect)


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
