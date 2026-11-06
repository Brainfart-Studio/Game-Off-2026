extends GdUnitTestSuite

var _camera: GameCamera


func before_test() -> void:
	_camera = GameCamera.new()


func after_test() -> void:
	_camera.free()


func test_arena_wider_than_view_uses_arena_edges() -> void:
	assert_vector(_camera._axis_limits(0.0, 960.0, 480.0)).is_equal(Vector2(0.0, 960.0))


func test_arena_equal_to_view_uses_arena_edges() -> void:
	assert_vector(_camera._axis_limits(0.0, 480.0, 480.0)).is_equal(Vector2(0.0, 480.0))


func test_arena_narrower_than_view_centers_on_arena() -> void:
	assert_vector(_camera._axis_limits(100.0, 300.0, 480.0)).is_equal(Vector2(-40.0, 440.0))
