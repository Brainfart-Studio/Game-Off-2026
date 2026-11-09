extends GdUnitTestSuite

var _runner: GdUnitSceneRunner
var _run: Run
var _seen: Array[String] = []


func before_test() -> void:
	_seen.clear()
	Events.arena_bounds_changed.connect(_on_bounds)
	Events.player_spawned.connect(_on_spawned)
	Events.world_shifted.connect(_on_shifted)
	_runner = scene_runner("res://scenes/main.tscn")
	_run = _runner.scene() as Run
	await await_idle_frame()


func after_test() -> void:
	Events.arena_bounds_changed.disconnect(_on_bounds)
	Events.player_spawned.disconnect(_on_spawned)
	Events.world_shifted.disconnect(_on_shifted)
	Game.reset()


func _on_bounds(_bounds: Rect2) -> void:
	_seen.append("arena_bounds_changed")


func _on_spawned(_player: Node2D) -> void:
	_seen.append("player_spawned")


func _on_shifted(_to: World.Id) -> void:
	_seen.append("world_shifted")


func test_setup_events_fire_in_order() -> void:
	assert_array(_seen).is_equal(["arena_bounds_changed", "player_spawned", "world_shifted"])


func test_game_player_is_the_player() -> void:
	assert_bool(Game.has_player()).is_true()
	assert_object(Game.player).is_instanceof(Player)
	assert_object(Game.player).is_same(_run.player)


func test_combat_content_parent_is_registered() -> void:
	var expected: Node2D = _run.get_node("Arena/CombatWorld/Content") as Node2D
	assert_object(Game.content_parent(World.Id.COMBAT)).is_same(expected)


func test_player_starts_at_player_spawn() -> void:
	var spawn: Marker2D = _run.get_node("Arena/PlayerSpawn") as Marker2D
	assert_vector(Game.player.global_position).is_equal_approx(spawn.global_position, Vector2(1.0, 1.0))


func test_world_is_the_configured_start_world() -> void:
	assert_int(Game.world).is_equal(_run.world_shift.config.start_world)
