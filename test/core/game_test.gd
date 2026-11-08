extends GdUnitTestSuite

var _game: Node


func before_test() -> void:
	_game = auto_free(load("res://scripts/core/game.gd").new())
	add_child(_game)


func after_test() -> void:
	# The autoload hears the same events as the fresh instance.
	Game.reset()


func test_reset_clears_every_field() -> void:
	var content: Node2D = auto_free(Node2D.new())
	_game.phase = _game.Phase.RUNNING
	_game.world = World.Id.COMBAT
	_game.player = auto_free(Node2D.new())
	_game.run_duration = 60.0
	_game.time_left = 20.0
	_game.register_content(World.Id.COMBAT, content)
	_game.reset()
	assert_int(_game.phase).is_equal(_game.Phase.NONE)
	assert_int(_game.world).is_equal(World.Id.PEACEFUL)
	assert_object(_game.player).is_null()
	assert_float(_game.run_duration).is_equal(0.0)
	assert_float(_game.time_left).is_equal(0.0)
	assert_object(_game.content_parent(World.Id.COMBAT)).is_null()


func test_world_follows_world_shifted() -> void:
	Events.world_shifted.emit(World.Id.COMBAT)
	assert_int(_game.world).is_equal(World.Id.COMBAT)
	Events.world_shifted.emit(World.Id.PEACEFUL)
	assert_int(_game.world).is_equal(World.Id.PEACEFUL)


func test_player_follows_player_spawned() -> void:
	var spawned: Node2D = auto_free(Node2D.new())
	assert_bool(_game.has_player()).is_false()
	Events.player_spawned.emit(spawned)
	assert_object(_game.player).is_same(spawned)
	assert_bool(_game.has_player()).is_true()


func test_registered_content_parent_is_returned() -> void:
	var content: Node2D = auto_free(Node2D.new())
	_game.register_content(World.Id.COMBAT, content)
	assert_object(_game.content_parent(World.Id.COMBAT)).is_same(content)


func test_unregistered_content_parent_errors_and_returns_null() -> void:
	var result: Array[Node2D] = [auto_free(Node2D.new())]
	await assert_error(func() -> void: result[0] = _game.content_parent(World.Id.PEACEFUL)) \
		.is_push_error("Game: no content parent for PEACEFUL")
	assert_object(result[0]).is_null()


func test_run_progress() -> void:
	_game.run_duration = 60.0
	_game.time_left = 60.0
	assert_float(_game.run_progress()).is_equal(0.0)
	_game.time_left = 30.0
	assert_float(_game.run_progress()).is_equal(0.5)
	_game.time_left = 0.0
	assert_float(_game.run_progress()).is_equal(1.0)


func test_run_progress_with_zero_duration_is_zero() -> void:
	_game.run_duration = 0.0
	_game.time_left = 0.0
	assert_float(_game.run_progress()).is_equal(0.0)


func test_is_combat_live_for_each_phase_and_world() -> void:
	for phase: int in _game.Phase.values():
		for world: int in World.Id.values():
			_game.phase = phase
			_game.world = world
			var expected: bool = phase == _game.Phase.RUNNING and world == World.Id.COMBAT
			assert_bool(_game.is_combat_live()).is_equal(expected)
