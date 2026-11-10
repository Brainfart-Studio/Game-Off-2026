extends GdUnitTestSuite
## The test arena's saved data, which is what the editor shows before the game runs.

var _arena: Arena


func before_test() -> void:
	_arena = auto_free((load("res://scenes/arena/test_arena.tscn") as PackedScene).instantiate())


func test_floor_is_saved_in_the_scene() -> void:
	var collision: TileMapLayer = _arena.get_node("Collision") as TileMapLayer
	assert_int(collision.get_used_cells().size()).is_equal(_arena.width_tiles * 2)
	var last: Vector2i = Vector2i(_arena.width_tiles - 1, _arena.floor_top + 1)
	assert_int(collision.get_cell_source_id(Vector2i(0, _arena.floor_top))).is_equal(0)
	assert_int(collision.get_cell_source_id(last)).is_equal(0)


func test_editor_shows_the_peaceful_world() -> void:
	assert_bool((_arena.get_node("PeacefulWorld") as Node2D).visible).is_true()
	assert_bool((_arena.get_node("CombatWorld") as Node2D).visible).is_false()
	assert_bool((_arena.get_node("CombatWorld/Background") as CanvasLayer).visible).is_false()


func test_bounds_fill_the_view_height() -> void:
	var bounds: ArenaBounds = _arena.get_node("ArenaBounds") as ArenaBounds
	var rect: Rect2 = Rect2(bounds.position, bounds.size)
	assert_float(rect.size.y).is_equal(float(Display.view_size().y))
	var floor_y: float = float(_arena.floor_top * 16)
	assert_bool(rect.end.y >= floor_y and rect.end.y <= floor_y + 32.0).is_true()
	var spawn: Marker2D = _arena.get_node("PlayerSpawn") as Marker2D
	assert_bool(rect.has_point(spawn.position)).is_true()
