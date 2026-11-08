extends GdUnitTestSuite

const FLOOR_Y: float = 0.0
# The apex band lowers gravity near the peak, so the real peak sits a few px above
# jump_height. Measured 4.6 px at defaults; allow up to 6.
const PEAK_OVERSHOOT: float = 6.0

var _runner: GdUnitSceneRunner
var _player: Player


func before_test() -> void:
	var root: Node2D = auto_free(Node2D.new())
	var floor_body: StaticBody2D = StaticBody2D.new()
	floor_body.collision_layer = Layers.WORLD
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(600.0, 20.0)
	shape.shape = rect
	floor_body.add_child(shape)
	# Floor spans x -600..0 with its top at y 0. Right of x 0 is a gap.
	floor_body.position = Vector2(-300.0, FLOOR_Y + 10.0)
	root.add_child(floor_body)
	_player = (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	_player.position = Vector2(-100.0, -2.0)
	root.add_child(_player)
	_runner = scene_runner(root)


func after_test() -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _settle() -> void:
	await _frames(30)


func _state() -> StringName:
	return _player.machine.current.name


func _walk_off_edge() -> void:
	_player.position = Vector2(-10.0, -2.0)
	_player.velocity = Vector2.ZERO
	await _settle()
	Input.action_press(Actions.MOVE_RIGHT)
	for i: int in 120:
		await get_tree().physics_frame
		if not _player.is_on_floor():
			return
	fail("player never left the floor edge")


func test_lands_and_reaches_idle() -> void:
	await _settle()
	assert_bool(_player.is_on_floor()).is_true()
	assert_str(String(_state())).is_equal("Idle")


func test_jump_peaks_at_jump_height() -> void:
	await _settle()
	var start_y: float = _player.global_position.y
	var top_y: float = start_y
	Input.action_press(Actions.JUMP)
	for i: int in 45:
		await get_tree().physics_frame
		top_y = minf(top_y, _player.global_position.y)
	Input.action_release(Actions.JUMP)
	assert_float(start_y - top_y).is_between(
		_player.config.jump_height,
		_player.config.jump_height + PEAK_OVERSHOOT
	)


func test_coyote_jump_within_window() -> void:
	await _walk_off_edge()
	Input.action_press(Actions.JUMP)
	await _frames(2)
	assert_float(_player.velocity.y).is_less(0.0)


func test_no_coyote_jump_after_window() -> void:
	await _walk_off_edge()
	await _frames(int(_player.config.coyote_time * 60.0) + 8)
	Input.action_press(Actions.JUMP)
	await _frames(2)
	assert_float(_player.velocity.y).is_greater(0.0)


func test_buffered_jump_fires_on_landing() -> void:
	await _settle()
	_player.position = Vector2(-100.0, -20.0)
	_player.velocity = Vector2.ZERO
	await _frames(5)
	Input.action_press(Actions.JUMP)
	await _frames(1)
	Input.action_release(Actions.JUMP)
	var top_y: float = _player.global_position.y
	for i: int in 40:
		await get_tree().physics_frame
		top_y = minf(top_y, _player.global_position.y)
	assert_float(top_y).is_less(-20.0)


func test_too_early_press_is_not_buffered() -> void:
	await _settle()
	_player.position = Vector2(-100.0, -90.0)
	_player.velocity = Vector2.ZERO
	await _frames(1)
	Input.action_press(Actions.JUMP)
	await _frames(1)
	Input.action_release(Actions.JUMP)
	var top_y: float = _player.global_position.y
	for i: int in 60:
		await get_tree().physics_frame
		top_y = minf(top_y, _player.global_position.y)
	assert_float(_player.global_position.y).is_equal_approx(FLOOR_Y, 1.0)
	assert_str(String(_state())).is_equal("Idle")
