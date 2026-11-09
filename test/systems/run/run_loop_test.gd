extends GdUnitTestSuite

const TIMEOUT_MS: int = 5000

var _runner: GdUnitSceneRunner
var _run: Run
var _started: int = 0
var _times: Array[float] = []
var _warnings: Array[int] = []
var _results: Array[RunResult] = []


func before_test() -> void:
	Feedback.enabled = false
	_started = 0
	_times.clear()
	_warnings.clear()
	_results.clear()
	Events.run_started.connect(_on_started)
	Events.time_changed.connect(_on_time_changed)
	Events.time_warning.connect(_on_time_warning)
	Events.run_ended.connect(_on_ended)
	var scene: Run = auto_free((load("res://scenes/main.tscn") as PackedScene).instantiate()) as Run
	var config: RunConfig = scene.config.duplicate() as RunConfig
	config.duration = 0.6
	config.start_delay = 0.05
	config.death_delay = 0.1
	config.warning_time = 1
	scene.config = config
	scene.pause_tree_on_end = false
	_runner = scene_runner(scene)
	_run = scene


func after_test() -> void:
	Events.run_started.disconnect(_on_started)
	Events.time_changed.disconnect(_on_time_changed)
	Events.time_warning.disconnect(_on_time_warning)
	Events.run_ended.disconnect(_on_ended)
	Feedback.enabled = true
	Game.reset()


func _on_started() -> void:
	_started += 1


func _on_time_changed(left: float) -> void:
	_times.append(left)


func _on_time_warning(seconds_left: int) -> void:
	_warnings.append(seconds_left)


func _on_ended(result: RunResult) -> void:
	_results.append(result)


func _wait_for_phase(phase: Game.Phase) -> void:
	var deadline: int = Time.get_ticks_msec() + TIMEOUT_MS
	while Game.phase != phase and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


func test_run_starts_in_starting_then_running() -> void:
	assert_int(Game.phase).is_equal(Game.Phase.STARTING)
	await _wait_for_phase(Game.Phase.RUNNING)
	assert_int(Game.phase).is_equal(Game.Phase.RUNNING)


func test_run_started_fires_once() -> void:
	await _wait_for_phase(Game.Phase.ENDED)
	assert_int(_started).is_equal(1)


func test_time_left_starts_at_the_configured_duration() -> void:
	assert_float(Game.run_duration).is_equal(0.6)
	assert_float(Game.time_left).is_equal(0.6)
	assert_array(_times).is_equal([0.6])


func test_time_changed_values_decrease_to_zero() -> void:
	await _wait_for_phase(Game.Phase.ENDED)
	assert_int(_times.size()).is_greater(1)
	for i: int in range(1, _times.size()):
		assert_float(_times[i]).is_less(_times[i - 1])
	assert_float(_times[_times.size() - 1]).is_equal(0.0)


func test_last_second_warns_once() -> void:
	await _wait_for_phase(Game.Phase.ENDED)
	assert_array(_warnings).is_equal([1])


func test_timer_end_ends_the_run_once() -> void:
	await _wait_for_phase(Game.Phase.ENDED)
	assert_int(Game.phase).is_equal(Game.Phase.ENDED)
	assert_int(_results.size()).is_equal(1)
	assert_bool(_results[0].died).is_false()
	assert_float(_results[0].time_survived).is_equal_approx(0.6, 0.05)


func test_player_death_ends_the_run_after_the_death_delay() -> void:
	await _wait_for_phase(Game.Phase.RUNNING)
	var hit: DamageInfo = DamageInfo.new()
	hit.amount = 999
	_run.player.health.damage(hit)
	var left_at_death: float = Game.time_left
	assert_bool(_run.died).is_true()
	assert_int(Game.phase).is_equal(Game.Phase.RUNNING)
	await _wait_for_phase(Game.Phase.ENDED)
	assert_int(_results.size()).is_equal(1)
	assert_bool(_results[0].died).is_true()
	assert_float(Game.time_left).is_equal(left_at_death)
	assert_float(_results[0].time_survived).is_equal_approx(0.6 - left_at_death, 0.001)


func test_kills_follow_enemy_killed_into_the_result() -> void:
	await _wait_for_phase(Game.Phase.RUNNING)
	var data: EnemyData = EnemyData.new()
	var info: DamageInfo = DamageInfo.new()
	Events.enemy_killed.emit(null, data, info)
	Events.enemy_killed.emit(null, data, info)
	assert_int(_run.kills).is_equal(2)
	assert_int(_run.build_result().kills).is_equal(2)


func test_score_and_best_multiplier_appear_in_the_result() -> void:
	await _wait_for_phase(Game.Phase.RUNNING)
	Events.score_changed.emit(120)
	Events.combo_changed.emit(0.5, 3)
	Events.combo_changed.emit(0.0, 1)
	Events.score_changed.emit(250)
	await _wait_for_phase(Game.Phase.ENDED)
	assert_int(_results.size()).is_equal(1)
	assert_int(_results[0].score).is_equal(250)
	assert_int(_results[0].best_multiplier).is_equal(3)
