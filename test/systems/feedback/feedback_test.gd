extends GdUnitTestSuite

var _scene: Node2D
var _previous_scene: Node


func before_test() -> void:
	_previous_scene = get_tree().current_scene
	_scene = Node2D.new()
	get_tree().root.add_child(_scene)
	get_tree().current_scene = _scene


func after_test() -> void:
	Feedback.reset()
	Feedback.enabled = true
	Settings.shake_enabled = true
	Settings.flash_enabled = true
	Events.settings_changed.emit()
	Feedback.shake_enabled = true
	Feedback.flash_enabled = true
	get_tree().current_scene = _previous_scene
	_scene.queue_free()


func _wait_for_normal_time(timeout_ms: int) -> void:
	var deadline: int = Time.get_ticks_msec() + timeout_ms
	while Engine.time_scale < 1.0 and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


func _fx_def() -> AnimationDef:
	var def: AnimationDef = AnimationDef.new()
	def.id = &"test_fx"
	def.path = "res://art/none.png"
	def.frames = 4
	def.fps = 8.0
	return def


func test_play_shift_raises_trauma() -> void:
	Feedback.play(&"shift")
	assert_float(Feedback.trauma).is_greater(0.0)


func test_play_unknown_entry_does_nothing() -> void:
	Feedback.play(&"no_such_entry")
	assert_float(Feedback.trauma).is_equal(0.0)


func test_hitstop_lowers_time_scale_and_restores_it() -> void:
	Feedback.hitstop(0.05, 0.5)
	assert_float(Engine.time_scale).is_equal(0.5)
	await _wait_for_normal_time(2000)
	assert_float(Engine.time_scale).is_equal(1.0)


func test_overlapping_hitstops_keep_the_lowest_scale() -> void:
	Feedback.hitstop(0.05, 0.5)
	Feedback.hitstop(0.05, 0.2)
	Feedback.hitstop(0.05, 0.8)
	assert_float(Engine.time_scale).is_equal(0.2)


func test_disabled_blocks_effects() -> void:
	Feedback.enabled = false
	Feedback.play(&"shift")
	Feedback.hitstop(0.05, 0.5)
	assert_float(Feedback.trauma).is_equal(0.0)
	assert_float(Engine.time_scale).is_equal(1.0)


func test_shake_disabled_blocks_trauma() -> void:
	Feedback.shake_enabled = false
	Feedback.add_trauma(0.5)
	Feedback.play(&"shift")
	assert_float(Feedback.trauma).is_equal(0.0)


func test_trauma_is_clamped() -> void:
	Feedback.add_trauma(0.8)
	Feedback.add_trauma(0.8)
	assert_float(Feedback.trauma).is_equal(1.0)


func test_world_shift_started_raises_trauma() -> void:
	Events.world_shift_started.emit(World.Id.COMBAT)
	assert_float(Feedback.trauma).is_greater(0.0)


func test_reset_clears_trauma_and_time_scale() -> void:
	Feedback.add_trauma(0.5)
	Feedback.hitstop(1.0, 0.1)
	Feedback.reset()
	assert_float(Feedback.trauma).is_equal(0.0)
	assert_float(Engine.time_scale).is_equal(1.0)


func test_run_ended_restores_time_scale_during_a_hitstop() -> void:
	Feedback.hitstop(1.0, 0.1)
	assert_float(Engine.time_scale).is_less(1.0)
	Events.run_ended.emit(RunResult.new())
	assert_float(Engine.time_scale).is_equal(1.0)


func test_spawn_fx_effect_without_a_position_adds_nothing() -> void:
	var effect: SpawnFxEffect = SpawnFxEffect.new()
	effect.animation = _fx_def()
	effect.play(FeedbackContext.new())
	assert_int(_scene.get_child_count()).is_equal(0)


func test_spawn_fx_effect_with_a_position_adds_a_sprite() -> void:
	var effect: SpawnFxEffect = SpawnFxEffect.new()
	effect.animation = _fx_def()
	effect.offset = Vector2(1, 2)
	effect.play(FeedbackContext.from_args(&"hit", [Vector2(10, 20)]))
	assert_int(_scene.get_child_count()).is_equal(1)
	var sprite: FxSprite = _scene.get_child(0) as FxSprite
	assert_vector(sprite.global_position).is_equal(Vector2(11, 22))


func test_toggles_follow_settings() -> void:
	Settings.shake_enabled = false
	Settings.flash_enabled = false
	Events.settings_changed.emit()
	assert_bool(Feedback.shake_enabled).is_false()
	assert_bool(Feedback.flash_enabled).is_false()
