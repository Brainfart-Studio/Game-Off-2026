extends GdUnitTestSuite

const CONFIG_PATH: String = "res://config/enemies/spawn_config.tres"
const SPAWNER_SCENE: String = "res://scenes/enemies/spawner.tscn"
const TELEGRAPH_SCENE: String = "res://scenes/enemies/spawn_telegraph.tscn"
const TIMEOUT_FRAMES: int = 240

var _runner: GdUnitSceneRunner
var _root: Node2D
var _content: Node2D
var _player: Node2D
var _spawner: Spawner
var _warned: Array[Vector2] = []


func before_test() -> void:
	Feedback.enabled = false
	_root = auto_free(Node2D.new())
	_root.add_child(_solid(Vector2(300.0, 10.0), Vector2(1600.0, 20.0)))
	_content = Node2D.new()
	_root.add_child(_content)
	_player = Node2D.new()
	_player.position = Vector2(-1000.0, 0.0)
	_root.add_child(_player)
	Game.register_content(World.Id.COMBAT, _content)
	Game.player = _player
	Game.phase = Game.Phase.RUNNING
	Game.world = World.Id.COMBAT
	Game.run_duration = 10.0
	Game.time_left = 10.0
	_warned.clear()
	Events.enemy_spawn_warned.connect(_on_warned)
	_runner = scene_runner(_root)


func after_test() -> void:
	Events.enemy_spawn_warned.disconnect(_on_warned)
	Feedback.enabled = true
	Game.reset()


func _on_warned(at: Vector2) -> void:
	_warned.append(at)


func _solid(at: Vector2, size: Vector2) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.collision_layer = Layers.WORLD
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	body.position = at
	return body


func _add_markers(xs: Array[float]) -> void:
	for x: float in xs:
		var marker: Marker2D = Marker2D.new()
		marker.position = Vector2(x, 0.0)
		marker.add_to_group(Groups.ENEMY_SPAWN)
		_root.add_child(marker)


## A copy of the shipped config that spawns fast. Every spawn waits `interval`, with `cap` alive.
func _config(interval: float, cap: int) -> SpawnConfig:
	var cfg: SpawnConfig = (load(CONFIG_PATH) as SpawnConfig).duplicate() as SpawnConfig
	cfg.first_delay = 0.0
	cfg.start_interval = interval
	cfg.end_interval = interval
	cfg.start_max_alive = cap
	cfg.end_max_alive = cap
	cfg.telegraph_time = 0.1
	cfg.min_player_distance = 80.0
	return cfg


func _start_spawner(cfg: SpawnConfig) -> void:
	_spawner = (load(SPAWNER_SCENE) as PackedScene).instantiate() as Spawner
	_spawner.config = cfg
	_root.add_child(_spawner)


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


## Waits until `done` is true, up to TIMEOUT_FRAMES physics frames.
func _wait_for(done: Callable) -> void:
	var frames: int = 0
	while not done.call() and frames < TIMEOUT_FRAMES:
		await get_tree().physics_frame
		frames += 1


func _enemies() -> int:
	return get_tree().get_nodes_in_group(Groups.ENEMY).size()


func _telegraphs() -> int:
	return get_tree().get_nodes_in_group(Groups.SPAWN_TELEGRAPH).size()


func test_no_spawn_while_peaceful() -> void:
	_add_markers([0.0, 300.0])
	Game.world = World.Id.PEACEFUL
	_start_spawner(_config(0.05, 4))
	await _frames(30)
	assert_int(_content.get_child_count()).is_equal(0)
	assert_int(_warned.size()).is_equal(0)


func test_no_spawn_unless_the_run_is_running() -> void:
	_add_markers([0.0, 300.0])
	Game.phase = Game.Phase.STARTING
	_start_spawner(_config(0.05, 4))
	await _frames(30)
	assert_int(_content.get_child_count()).is_equal(0)
	Game.phase = Game.Phase.ENDED
	await _frames(30)
	assert_int(_content.get_child_count()).is_equal(0)
	assert_int(_warned.size()).is_equal(0)


func test_a_telegraph_appears_under_content_then_a_walker() -> void:
	_add_markers([300.0])
	_start_spawner(_config(100.0, 4))
	await _wait_for(func() -> bool: return _telegraphs() == 1)
	assert_int(_telegraphs()).is_equal(1)
	var telegraph: Node = get_tree().get_nodes_in_group(Groups.SPAWN_TELEGRAPH)[0]
	assert_object(telegraph.get_parent()).is_same(_content)
	assert_vector(telegraph.global_position).is_equal(Vector2(300.0, 0.0))
	assert_int(_warned.size()).is_equal(1)
	assert_vector(_warned[0]).is_equal(Vector2(300.0, 0.0))
	assert_int(_enemies()).is_equal(0)
	await _wait_for(func() -> bool: return _enemies() == 1)
	assert_int(_enemies()).is_equal(1)
	assert_int(_telegraphs()).is_equal(0)
	var enemy: Enemy = get_tree().get_nodes_in_group(Groups.ENEMY)[0] as Enemy
	assert_object(enemy.get_parent()).is_same(_content)
	assert_str(String(enemy.data.id)).is_equal("walker")
	assert_float(enemy.global_position.x).is_equal_approx(300.0, 1.0)


func test_enemies_plus_telegraphs_never_exceed_the_cap() -> void:
	_add_markers([0.0, 300.0, 600.0])
	_start_spawner(_config(0.02, 2))
	var peak: int = 0
	for i: int in 90:
		await get_tree().physics_frame
		peak = maxi(peak, _enemies() + _telegraphs())
	assert_int(peak).is_equal(2)
	assert_int(_enemies()).is_equal(2)
	assert_int(_telegraphs()).is_equal(0)


func test_markers_near_the_player_are_skipped() -> void:
	_add_markers([0.0, 300.0, 600.0])
	_player.position = Vector2(30.0, 0.0)
	_start_spawner(_config(0.02, 8))
	await _wait_for(func() -> bool: return _warned.size() >= 6)
	assert_bool(_warned.size() >= 6).is_true()
	for at: Vector2 in _warned:
		assert_bool(at.distance_to(_player.position) >= 80.0).is_true()


func test_no_far_enough_marker_skips_the_spawn() -> void:
	_add_markers([0.0, 40.0])
	_player.position = Vector2(20.0, 0.0)
	_start_spawner(_config(0.02, 8))
	await _frames(40)
	assert_int(_warned.size()).is_equal(0)
	assert_int(_content.get_child_count()).is_equal(0)


func test_a_telegraph_under_a_disabled_parent_does_not_spawn() -> void:
	var cfg: SpawnConfig = _config(100.0, 4)
	var telegraph: SpawnTelegraph = (load(TELEGRAPH_SCENE) as PackedScene).instantiate() as SpawnTelegraph
	telegraph.setup(cfg.enemies[0], 0.05, cfg.telegraph_animation)
	_content.process_mode = Node.PROCESS_MODE_DISABLED
	_content.add_child(telegraph)
	await _frames(20)
	assert_int(_enemies()).is_equal(0)
	assert_bool(is_instance_valid(telegraph)).is_true()
	_content.process_mode = Node.PROCESS_MODE_INHERIT
	await _wait_for(func() -> bool: return _enemies() == 1)
	assert_int(_enemies()).is_equal(1)


func test_interval_and_cap_follow_a_linear_ramp() -> void:
	var cfg: SpawnConfig = SpawnConfig.new()
	assert_float(cfg.ramp_at(0.5)).is_equal_approx(0.5, 0.001)
	assert_float(cfg.interval_at(0.0)).is_equal_approx(3.0, 0.001)
	assert_float(cfg.interval_at(0.5)).is_equal_approx(1.9, 0.001)
	assert_float(cfg.interval_at(1.0)).is_equal_approx(0.8, 0.001)
	assert_int(cfg.max_alive_at(0.0)).is_equal(3)
	assert_int(cfg.max_alive_at(0.5)).is_equal(8)
	assert_int(cfg.max_alive_at(1.0)).is_equal(12)


func test_interval_and_cap_follow_a_ramp_curve() -> void:
	var cfg: SpawnConfig = SpawnConfig.new()
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.5, 0.25))
	curve.add_point(Vector2(1.0, 1.0))
	cfg.ramp = curve
	assert_float(cfg.ramp_at(0.5)).is_equal_approx(0.25, 0.001)
	assert_float(cfg.interval_at(0.0)).is_equal_approx(3.0, 0.001)
	assert_float(cfg.interval_at(0.5)).is_equal_approx(2.45, 0.001)
	assert_float(cfg.interval_at(1.0)).is_equal_approx(0.8, 0.001)
	assert_int(cfg.max_alive_at(0.0)).is_equal(3)
	assert_int(cfg.max_alive_at(0.5)).is_equal(5)
	assert_int(cfg.max_alive_at(1.0)).is_equal(12)
