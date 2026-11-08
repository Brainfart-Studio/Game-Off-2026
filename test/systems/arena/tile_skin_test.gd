extends GdUnitTestSuite

var _root: Node2D
var _skin: TileSkin


func before_test() -> void:
	_root = auto_free(Node2D.new())
	var collision: TileMapLayer = TileMapLayer.new()
	collision.name = &"Collision"
	collision.tile_set = load("res://scenes/arena/collision_tileset.tres")
	_root.add_child(collision)
	for x: int in 3:
		for y: int in 2:
			collision.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
	_skin = TileSkin.new()
	_skin.collision_path = ^"../Collision"
	_skin.id = "test_skin"
	_root.add_child(_skin)
	add_child(_root)
	await get_tree().process_frame


func test_edge_selection() -> void:
	assert_vector(_skin.get_cell_atlas_coords(Vector2i(0, 0))).is_equal(Vector2i(0, 0))
	assert_vector(_skin.get_cell_atlas_coords(Vector2i(1, 0))).is_equal(Vector2i(1, 0))
	assert_vector(_skin.get_cell_atlas_coords(Vector2i(2, 0))).is_equal(Vector2i(2, 0))
	assert_vector(_skin.get_cell_atlas_coords(Vector2i(0, 1))).is_equal(Vector2i(0, 1))
	assert_vector(_skin.get_cell_atlas_coords(Vector2i(1, 1))).is_equal(Vector2i(1, 1))
	assert_vector(_skin.get_cell_atlas_coords(Vector2i(2, 1))).is_equal(Vector2i(2, 1))


func test_copies_every_used_cell() -> void:
	assert_int(_skin.get_used_cells().size()).is_equal(6)
