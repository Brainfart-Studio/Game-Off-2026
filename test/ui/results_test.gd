extends GdUnitTestSuite

const TEST_PATH: String = "user://results_test.cfg"
const DEFAULT_PATH: String = "user://save.cfg"

var _results: Results
var _restarts: int = 0


func before_test() -> void:
	_remove_file()
	Save.path = TEST_PATH
	Save.load_file()
	_restarts = 0
	Events.run_restart_requested.connect(_on_restart_requested)
	_results = auto_free((load("res://scenes/ui/results.tscn") as PackedScene).instantiate()) as Results
	scene_runner(_results)


func after_test() -> void:
	Events.run_restart_requested.disconnect(_on_restart_requested)
	Save.path = DEFAULT_PATH
	Save.load_file()
	_remove_file()


func _on_restart_requested() -> void:
	_restarts += 1


func _remove_file() -> void:
	var absolute: String = ProjectSettings.globalize_path(TEST_PATH)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)


func _node(node_name: String) -> Control:
	return _results.get_node("%" + node_name) as Control


func _end_run(score: int, died: bool = false) -> void:
	var result: RunResult = RunResult.new()
	result.score = score
	result.kills = 7
	result.best_multiplier = 3
	result.time_survived = 65.0
	result.died = died
	Events.run_ended.emit(result)


func test_results_are_hidden_until_the_run_ends() -> void:
	assert_bool(_results.visible).is_false()


func test_run_end_fills_the_lines() -> void:
	_end_run(500, true)
	assert_bool(_results.visible).is_true()
	assert_str((_node("Title") as Label).text).is_equal(Results.DEFEATED)
	assert_str((_node("Score") as Label).text).is_equal("SCORE  500")
	assert_str((_node("Kills") as Label).text).is_equal("KILLS  7")
	assert_str((_node("Multiplier") as Label).text).is_equal("BEST COMBO  x3")
	assert_str((_node("Time") as Label).text).is_equal("TIME  1:05")


func test_time_up_title_when_the_player_lived() -> void:
	_end_run(500)
	assert_str((_node("Title") as Label).text).is_equal(Results.TIME_UP)


func test_qualifying_score_shows_the_entry_then_the_list_with_its_rank() -> void:
	Save.add_high_score("AAA", 900)
	Save.add_high_score("BBB", 100)
	_end_run(500)
	var initials: InitialsEntry = _node("Initials") as InitialsEntry
	assert_bool(_node("NewHighScore").visible).is_true()
	assert_bool(initials.visible).is_true()
	assert_bool(initials.active).is_true()
	assert_bool(_node("HighScores").visible).is_false()
	assert_bool(_node("Restart").visible).is_false()
	initials.confirm()
	assert_bool(initials.visible).is_false()
	assert_bool(initials.active).is_false()
	var list: HighScoreList = _node("HighScores") as HighScoreList
	assert_bool(list.visible).is_true()
	assert_int(list.get_child_count()).is_equal(3)
	var row: Label = list.get_child(1) as Label
	assert_str(row.text).is_equal(" 2. BBB     500")
	assert_object(row.get_theme_color(&"font_color")).is_equal(_results.config.highlight_color)
	assert_object((list.get_child(0) as Label).get_theme_color(&"font_color")).is_equal(
		_results.config.text_color
	)
	assert_int(Save.high_scores().size()).is_equal(3)


func test_zero_score_shows_the_list_and_focuses_restart() -> void:
	_end_run(0)
	assert_bool(_node("NewHighScore").visible).is_false()
	assert_bool(_node("Initials").visible).is_false()
	assert_bool(_node("HighScores").visible).is_true()
	assert_bool(_node("Restart").visible).is_true()
	assert_bool(_node("Restart").has_focus()).is_true()
	assert_array(Save.high_scores()).is_empty()


func test_restart_emits_the_restart_request() -> void:
	_end_run(0)
	(_node("Restart") as Button).pressed.emit()
	assert_int(_restarts).is_equal(1)
