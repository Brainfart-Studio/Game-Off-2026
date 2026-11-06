extends GdUnitTestSuite


func test_view_size_is_480_by_270() -> void:
	assert_vector(Display.view_size()).is_equal(Vector2i(480, 270))
