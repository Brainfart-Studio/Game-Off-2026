extends GdUnitTestSuite


func test_node2d_argument_gives_target_and_position() -> void:
	var node: Node2D = auto_free(Node2D.new())
	add_child(node)
	node.global_position = Vector2(30, 40)
	var context: FeedbackContext = FeedbackContext.from_args(&"hit", [5, node, Vector2(1, 2)])
	assert_str(String(context.event)).is_equal("hit")
	assert_object(context.target).is_same(node)
	assert_vector(context.position).is_equal(Vector2(30, 40))
	assert_bool(context.has_position).is_true()


func test_vector2_argument_gives_position_only() -> void:
	var context: FeedbackContext = FeedbackContext.from_args(&"burst", [Vector2(7, 8)])
	assert_object(context.target).is_null()
	assert_vector(context.position).is_equal(Vector2(7, 8))
	assert_bool(context.has_position).is_true()


func test_no_arguments_gives_an_empty_context() -> void:
	var context: FeedbackContext = FeedbackContext.from_args(&"shift_denied", [])
	assert_object(context.target).is_null()
	assert_bool(context.has_position).is_false()
	assert_vector(context.position).is_equal(Vector2.ZERO)
