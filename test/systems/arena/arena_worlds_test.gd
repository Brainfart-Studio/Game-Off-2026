extends GdUnitTestSuite

var _arena: Node


func before_test() -> void:
	_arena = auto_free((load("res://scenes/arena/test_arena.tscn") as PackedScene).instantiate())
	add_child(_arena)
	await get_tree().process_frame


func after_test() -> void:
	Events.world_shifted.emit(World.Id.PEACEFUL)


func _peaceful() -> Node2D:
	return _arena.get_node("PeacefulWorld")


func _combat() -> Node2D:
	return _arena.get_node("CombatWorld")


func _assert_active(world: Node2D) -> void:
	assert_bool(world.visible).is_true()
	assert_int(world.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_bool((world.get_node("Background") as CanvasLayer).visible).is_true()


func _assert_inactive(world: Node2D) -> void:
	assert_bool(world.visible).is_false()
	assert_int(world.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)
	assert_bool((world.get_node("Background") as CanvasLayer).visible).is_false()


func test_starts_peaceful() -> void:
	_assert_active(_peaceful())
	_assert_inactive(_combat())


func test_shift_to_combat_freezes_peaceful() -> void:
	Events.world_shifted.emit(World.Id.COMBAT)
	_assert_active(_combat())
	_assert_inactive(_peaceful())


func test_shift_back_to_peaceful() -> void:
	Events.world_shifted.emit(World.Id.COMBAT)
	Events.world_shifted.emit(World.Id.PEACEFUL)
	_assert_active(_peaceful())
	_assert_inactive(_combat())
