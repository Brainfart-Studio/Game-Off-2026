extends GdUnitTestSuite


class DummyConfig:
	extends GameConfig
	@export var max_health: int = 99


var _runner: GdUnitSceneRunner
var _root: Node2D
var _player: Player
var _dummy: Node2D
var _dummy_health: Health
var _landed: int = 0


func before_test() -> void:
	Feedback.enabled = false
	_root = auto_free(Node2D.new())
	var floor_body: StaticBody2D = StaticBody2D.new()
	floor_body.collision_layer = Layers.WORLD
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(1200.0, 20.0)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(0.0, 10.0)
	_root.add_child(floor_body)
	_player = (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	_player.position = Vector2(0.0, -2.0)
	_root.add_child(_player)
	_landed = 0
	_runner = scene_runner(_root)
	_player.attack_hitbox.landed.connect(func(_info: DamageInfo) -> void: _landed += 1)


func after_test() -> void:
	Feedback.enabled = true
	Game.reset()
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)


## Adds an enemy hurtbox with plenty of health at `at`.
func _spawn_dummy(at: Vector2) -> void:
	_dummy = Node2D.new()
	_dummy.position = at
	var stats: Stats = Stats.new()
	stats.config = DummyConfig.new()
	_dummy.add_child(stats)
	_dummy_health = Health.new()
	_dummy_health.stats = stats
	_dummy.add_child(_dummy_health)
	var hurtbox: Hurtbox = Hurtbox.new()
	hurtbox.team = Team.Id.ENEMY
	hurtbox.health = _dummy_health
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(16.0, 24.0)
	shape.shape = rect
	shape.position = Vector2(0.0, -12.0)
	hurtbox.add_child(shape)
	_dummy.add_child(hurtbox)
	_root.add_child(_dummy)
	_dummy_health.setup()


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _settle() -> void:
	await _frames(30)


func _state() -> StringName:
	return _player.machine.current.name


func _press_attack() -> void:
	Input.action_press(Actions.ATTACK)
	await _frames(1)
	Input.action_release(Actions.ATTACK)


func test_attack_press_enters_attack_and_returns_to_idle() -> void:
	await _settle()
	await _press_attack()
	await _frames(2)
	assert_str(String(_state())).is_equal("Attack")
	await _frames(40)
	assert_str(String(_state())).is_equal("Idle")


func test_hitbox_is_off_before_startup_on_in_the_window_and_off_after() -> void:
	await _settle()
	await _press_attack()
	await _frames(1)
	assert_bool(_player.attack_hitbox.is_active()).is_false()
	await _frames(8)
	assert_bool(_player.attack_hitbox.is_active()).is_true()
	await _frames(8)
	assert_bool(_player.attack_hitbox.is_active()).is_false()
	assert_str(String(_state())).is_equal("Attack")


func test_one_hit_per_attack() -> void:
	_spawn_dummy(Vector2(22.0, 0.0))
	await _settle()
	await _press_attack()
	await _frames(40)
	assert_int(_landed).is_equal(1)
	assert_int(_dummy_health.current).is_equal(98)


func test_held_right_gives_the_side_attack() -> void:
	await _settle()
	Input.action_press(Actions.MOVE_RIGHT)
	await _frames(2)
	await _press_attack()
	await _frames(2)
	assert_str(String(_player.current_attack.id)).is_equal("side")
	assert_int(_player.facing).is_equal(1)


func test_held_up_gives_the_up_attack() -> void:
	await _settle()
	Input.action_press(Actions.MOVE_UP)
	await _frames(2)
	await _press_attack()
	await _frames(2)
	assert_str(String(_player.current_attack.id)).is_equal("up")


func test_no_direction_gives_the_neutral_attack() -> void:
	await _settle()
	await _press_attack()
	await _frames(2)
	assert_str(String(_player.current_attack.id)).is_equal("neutral")


func test_airborne_with_down_gives_the_air_down_attack() -> void:
	await _settle()
	_player.position = Vector2(0.0, -60.0)
	_player.velocity = Vector2.ZERO
	await _frames(3)
	Input.action_press(Actions.MOVE_DOWN)
	await _frames(1)
	await _press_attack()
	await _frames(2)
	assert_str(String(_player.current_attack.id)).is_equal("air_down")


func test_air_down_hit_on_a_dummy_below_sends_the_player_up() -> void:
	_spawn_dummy(Vector2(0.0, 0.0))
	await _settle()
	_dummy.position = Vector2(0.0, 0.0)
	_player.position = Vector2(0.0, -30.0)
	_player.velocity = Vector2.ZERO
	await _frames(3)
	var start_y: float = _player.global_position.y
	Input.action_press(Actions.MOVE_DOWN)
	await _frames(1)
	await _press_attack()
	var top_y: float = start_y
	for i: int in 20:
		await _frames(1)
		top_y = minf(top_y, _player.global_position.y)
	assert_int(_landed).is_equal(1)
	assert_float(top_y).is_less(start_y - 10.0)
