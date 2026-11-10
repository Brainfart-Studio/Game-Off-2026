extends GdUnitTestSuite


func test_view_size_is_320_by_180() -> void:
	assert_vector(Display.view_size()).is_equal(Vector2i(320, 180))
