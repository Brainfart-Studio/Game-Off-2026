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


func test_damage_info_gives_target_and_position_before_other_arguments() -> void:
	var hit_target: Node2D = auto_free(Node2D.new())
	var other: Node2D = auto_free(Node2D.new())
	add_child(hit_target)
	add_child(other)
	other.global_position = Vector2(90, 90)
	var info: DamageInfo = DamageInfo.new()
	info.target = hit_target
	info.position = Vector2(5, 6)
	var context: FeedbackContext = FeedbackContext.from_args(&"hit", [info, other])
	assert_object(context.target).is_same(hit_target)
	assert_vector(context.position).is_equal(Vector2(5, 6))
	assert_bool(context.has_position).is_true()


func test_damage_info_without_target_still_gives_position() -> void:
	var info: DamageInfo = DamageInfo.new()
	info.position = Vector2(5, 6)
	var context: FeedbackContext = FeedbackContext.from_args(&"hit", [info])
	assert_object(context.target).is_null()
	assert_vector(context.position).is_equal(Vector2(5, 6))
	assert_bool(context.has_position).is_true()
