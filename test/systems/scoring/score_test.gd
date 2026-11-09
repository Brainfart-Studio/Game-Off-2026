extends GdUnitTestSuite

const SCORE_SCENE: String = "res://scenes/scoring/score.tscn"
const WALKER_DATA: String = "res://config/enemies/walker.tres"

var _runner: GdUnitSceneRunner
var _root: Node2D
var _score: Score
var _scores: Array[int] = []
var _raised: Array[int] = []
var _broken: int = 0
var _combo: Array[Vector2] = []


func before_test() -> void:
	Feedback.enabled = false
	_scores.clear()
	_raised.clear()
	_broken = 0
	_combo.clear()
	Events.score_changed.connect(_on_score_changed)
	Events.combo_raised.connect(_on_combo_raised)
	Events.combo_broken.connect(_on_combo_broken)
	Events.combo_changed.connect(_on_combo_changed)
	Game.phase = Game.Phase.RUNNING
	Game.world = World.Id.COMBAT
	_root = auto_free(Node2D.new())
	_runner = scene_runner(_root)
	_score = (load(SCORE_SCENE) as PackedScene).instantiate() as Score
	_score.config = _score.config.duplicate() as ScoreConfig
	_score.config.drain_delay = 0.05
	_score.config.drain_rate = 20.0
	_root.add_child(_score)


func after_test() -> void:
	Events.score_changed.disconnect(_on_score_changed)
	Events.combo_raised.disconnect(_on_combo_raised)
	Events.combo_broken.disconnect(_on_combo_broken)
	Events.combo_changed.disconnect(_on_combo_changed)
	Feedback.enabled = true
	Game.reset()


func _on_score_changed(value: int) -> void:
	_scores.append(value)


func _on_combo_raised(multiplier: int) -> void:
	_raised.append(multiplier)


func _on_combo_broken() -> void:
	_broken += 1


func _on_combo_changed(fill: float, multiplier: int) -> void:
	_combo.append(Vector2(fill, float(multiplier)))


func _hit(count: int = 1) -> void:
	for i: int in count:
		Events.hit_landed.emit(DamageInfo.new())


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _kill() -> void:
	var enemy: Node2D = Node2D.new()
	_root.add_child(enemy)
	Events.enemy_killed.emit(enemy, load(WALKER_DATA) as EnemyData, DamageInfo.new())
	enemy.queue_free()


func test_a_hit_scores_per_hit_at_multiplier_one() -> void:
	_hit()
	assert_int(_score.score).is_equal(_score.config.score_per_hit)
	assert_array(_scores).is_equal([_score.config.score_per_hit])


func test_hit_score_scales_with_the_multiplier() -> void:
	_hit(4)
	assert_int(_score.multiplier).is_equal(2)
	var before: int = _score.score
	_hit()
	assert_int(_score.score - before).is_equal(_score.config.score_per_hit * 2)


func test_four_hits_raise_the_multiplier_once() -> void:
	_hit(3)
	assert_int(_score.multiplier).is_equal(1)
	assert_float(_score.fill).is_equal_approx(0.75, 0.001)
	_hit()
	assert_int(_score.multiplier).is_equal(2)
	assert_float(_score.fill).is_equal_approx(0.0, 0.001)
	assert_array(_raised).is_equal([2])


func test_the_multiplier_holds_at_the_cap() -> void:
	_hit(4 * _score.config.max_multiplier + 8)
	assert_int(_score.multiplier).is_equal(_score.config.max_multiplier)
	assert_float(_score.fill).is_equal(1.0)
	assert_int(_raised.size()).is_equal(_score.config.max_multiplier - 1)


func test_a_kill_scores_the_enemys_score_value() -> void:
	var data: EnemyData = load(WALKER_DATA) as EnemyData
	_kill()
	assert_int(_score.score).is_equal(data.score_value)
	_hit(4)
	var before: int = _score.score
	_kill()
	assert_int(_score.score - before).is_equal(data.score_value * 2)


func test_peaceful_hits_and_kills_score_nothing() -> void:
	Game.world = World.Id.PEACEFUL
	_hit(4)
	_kill()
	assert_int(_score.score).is_equal(0)
	assert_int(_score.multiplier).is_equal(1)
	assert_float(_score.fill).is_equal(0.0)
	assert_array(_scores).is_empty()


func test_the_bar_drains_after_the_delay() -> void:
	_hit(2)
	assert_float(_score.fill).is_equal_approx(0.5, 0.001)
	await _frames(2)
	assert_float(_score.fill).is_equal_approx(0.5, 0.001)
	await get_tree().create_timer(0.3).timeout
	assert_float(_score.fill).is_less(0.5)


func test_draining_to_zero_breaks_a_raised_combo() -> void:
	_hit(4)
	assert_int(_score.multiplier).is_equal(2)
	_hit()
	await get_tree().create_timer(0.5).timeout
	assert_int(_score.multiplier).is_equal(1)
	assert_float(_score.fill).is_equal(0.0)
	assert_int(_broken).is_equal(1)


func test_draining_at_multiplier_one_does_not_break() -> void:
	_hit()
	await get_tree().create_timer(0.5).timeout
	assert_float(_score.fill).is_equal(0.0)
	assert_int(_broken).is_equal(0)


func test_a_hit_restarts_the_drain_delay() -> void:
	_score.config.drain_delay = 0.4
	_hit()
	await get_tree().create_timer(0.25).timeout
	_hit()
	await get_tree().create_timer(0.25).timeout
	assert_float(_score.fill).is_equal_approx(0.5, 0.001)


func test_damage_breaks_the_combo() -> void:
	_hit(4)
	Events.player_damaged.emit(DamageInfo.new())
	assert_int(_score.multiplier).is_equal(1)
	assert_float(_score.fill).is_equal(0.0)
	assert_int(_broken).is_equal(1)
	assert_vector(_combo[_combo.size() - 1]).is_equal(Vector2(0.0, 1.0))


func test_damage_without_a_raised_multiplier_resets_the_bar_silently() -> void:
	_hit(2)
	Events.player_damaged.emit(DamageInfo.new())
	assert_float(_score.fill).is_equal(0.0)
	assert_int(_broken).is_equal(0)


func test_damage_keeps_the_combo_when_configured() -> void:
	_score.config.damage_breaks_combo = false
	_hit(4)
	Events.player_damaged.emit(DamageInfo.new())
	assert_int(_score.multiplier).is_equal(2)
	assert_int(_broken).is_equal(0)


func test_no_drain_in_peaceful_by_default() -> void:
	_hit(2)
	Game.world = World.Id.PEACEFUL
	await get_tree().create_timer(0.3).timeout
	assert_float(_score.fill).is_equal_approx(0.5, 0.001)


func test_drain_in_peaceful_when_configured() -> void:
	_score.config.drain_in_peaceful = true
	_hit(2)
	Game.world = World.Id.PEACEFUL
	await get_tree().create_timer(0.3).timeout
	assert_float(_score.fill).is_less(0.5)


func test_no_drain_unless_the_run_is_running() -> void:
	_hit(2)
	Game.phase = Game.Phase.ENDED
	await get_tree().create_timer(0.3).timeout
	assert_float(_score.fill).is_equal_approx(0.5, 0.001)


func test_run_started_announces_the_starting_values() -> void:
	Events.run_started.emit()
	assert_array(_scores).is_equal([0])
	assert_vector(_combo[_combo.size() - 1]).is_equal(Vector2(0.0, 1.0))
