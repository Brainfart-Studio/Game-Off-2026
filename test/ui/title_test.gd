extends GdUnitTestSuite

const UiLayout = preload("res://test/ui/ui_layout.gd")

const TEST_PATH: String = "user://title_test.cfg"
const DEFAULT_PATH: String = "user://save.cfg"

var _title: Title
var _runner: GdUnitSceneRunner
var _opened: int = 0


func before_test() -> void:
	_remove_file()
	Save.path = TEST_PATH
	Save.load_file()
	Scenes.changes_enabled = false
	Scenes.last_request = ""
	_opened = 0
	Events.title_opened.connect(_on_title_opened)
	_title = auto_free((load("res://scenes/title.tscn") as PackedScene).instantiate()) as Title
	_runner = scene_runner(_title)


func after_test() -> void:
	Events.title_opened.disconnect(_on_title_opened)
	Scenes.changes_enabled = true
	Scenes.last_request = ""
	Save.path = DEFAULT_PATH
	Save.load_file()
	_remove_file()


func _on_title_opened() -> void:
	_opened += 1


func _remove_file() -> void:
	var absolute: String = ProjectSettings.globalize_path(TEST_PATH)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)


func _node(node_name: String) -> Control:
	return _title.get_node("%" + node_name) as Control


func _page(page_name: String) -> Control:
	return _title.get_node("%Menu/" + page_name) as Control


func _settle() -> void:
	await await_idle_frame()
	await await_idle_frame()


func test_focus_starts_on_play() -> void:
	assert_bool(_node("Play").has_focus()).is_true()


func test_down_moves_focus_to_high_scores() -> void:
	var press: InputEventAction = InputEventAction.new()
	press.action = Actions.UI_DOWN
	press.pressed = true
	Input.parse_input_event(press)
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(_node("HighScoresButton").has_focus()).is_true()


func test_play_requests_the_run_scene() -> void:
	(_node("Play") as Button).pressed.emit()
	assert_str(Scenes.last_request).is_equal(Scenes.RUN)


func test_high_scores_lists_saved_scores_and_cancel_returns_to_the_button() -> void:
	Save.add_high_score("AAA", 900)
	Save.add_high_score("BBB", 100)
	_node("HighScoresButton").grab_focus()
	(_node("HighScoresButton") as Button).pressed.emit()
	assert_bool(_page("Main").visible).is_false()
	assert_bool(_page("HighScores").visible).is_true()
	assert_int(_node("HighScoreList").get_child_count()).is_equal(2)
	assert_str((_node("HighScoreList").get_child(0) as Label).text).is_equal(" 1. AAA     900")
	assert_bool(_node("ScoresBack").has_focus()).is_true()
	_runner.simulate_action_pressed("ui_cancel")
	await await_idle_frame()
	assert_bool(_page("Main").visible).is_true()
	assert_bool(_node("HighScoresButton").has_focus()).is_true()


func test_credits_shows_the_credit_lines() -> void:
	(_node("CreditsButton") as Button).pressed.emit()
	assert_bool(_page("Credits").visible).is_true()
	assert_str((_node("CreditsText") as Label).text).is_equal("\n".join(Title.CREDIT_LINES))
	assert_bool(_node("CreditsBack").has_focus()).is_true()


func test_title_opened_fires_once() -> void:
	assert_int(_opened).is_equal(1)


func test_exactly_one_logo_shows_on_main_and_none_on_other_pages() -> void:
	assert_bool(_node("Logo").visible != _node("LogoText").visible).is_true()
	(_node("HighScoresButton") as Button).pressed.emit()
	assert_bool(_node("Logo").visible).is_false()
	assert_bool(_node("LogoText").visible).is_false()


func test_pages_fit_the_view() -> void:
	for i: int in range(10):
		Save.add_high_score("AAA", 100 * (i + 1))
	await _settle()
	assert_array(UiLayout.outside_view(_title)).is_empty()
	(_node("HighScoresButton") as Button).pressed.emit()
	await _settle()
	assert_array(UiLayout.outside_view(_title)).is_empty()
	_runner.simulate_action_pressed("ui_cancel")
	await await_idle_frame()
	(_node("CreditsButton") as Button).pressed.emit()
	await _settle()
	assert_array(UiLayout.outside_view(_title)).is_empty()
