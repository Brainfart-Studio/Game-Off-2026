extends GdUnitTestSuite

const UiLayout = preload("res://test/ui/ui_layout.gd")

var _pause: PauseMenu
var _runner: GdUnitSceneRunner
var _requests: Array[bool] = []
var _restarts: int = 0
var _title_requests: int = 0


func before_test() -> void:
	_requests.clear()
	_restarts = 0
	_title_requests = 0
	Game.phase = Game.Phase.RUNNING
	Events.run_pause_requested.connect(_on_pause_requested)
	Events.run_restart_requested.connect(_on_restart_requested)
	Events.title_requested.connect(_on_title_requested)
	_pause = auto_free((load("res://scenes/ui/pause_menu.tscn") as PackedScene).instantiate()) as PauseMenu
	_runner = scene_runner(_pause)


func after_test() -> void:
	Events.run_pause_requested.disconnect(_on_pause_requested)
	Events.run_restart_requested.disconnect(_on_restart_requested)
	Events.title_requested.disconnect(_on_title_requested)
	InputMap.load_from_project_settings()
	Game.reset()


func _on_pause_requested(paused: bool) -> void:
	_requests.append(paused)


func _on_restart_requested() -> void:
	_restarts += 1


func _on_title_requested() -> void:
	_title_requests += 1


func _button(button_name: String) -> Button:
	return _pause.find_child(button_name, true, false) as Button


func _show_menu() -> void:
	Events.run_paused.emit(true)
	await await_idle_frame()


func _menu() -> MenuStack:
	return _pause.get_node("%Menu") as MenuStack


func _press_action(action: StringName) -> void:
	_runner.simulate_action_pressed(action)
	await await_idle_frame()


func test_it_starts_hidden() -> void:
	assert_bool(_pause.visible).is_false()


func test_the_pause_action_in_running_requests_a_pause() -> void:
	await _press_action(Actions.PAUSE)
	assert_array(_requests).is_equal([true])


func test_the_pause_action_in_starting_requests_a_pause() -> void:
	Game.phase = Game.Phase.STARTING
	await _press_action(Actions.PAUSE)
	assert_array(_requests).is_equal([true])


func test_the_pause_action_after_the_run_ended_requests_nothing() -> void:
	Game.phase = Game.Phase.ENDED
	await _press_action(Actions.PAUSE)
	assert_array(_requests).is_empty()


func test_the_pause_action_while_shown_requests_a_resume() -> void:
	await _show_menu()
	await _press_action(Actions.PAUSE)
	assert_array(_requests).is_equal([false])


func test_run_paused_shows_the_menu_with_focus_on_resume() -> void:
	await _show_menu()
	assert_bool(_pause.visible).is_true()
	assert_object(_pause.get_viewport().gui_get_focus_owner()).is_same(_button("Resume"))
	Events.run_paused.emit(false)
	assert_bool(_pause.visible).is_false()


func test_resume_requests_a_resume() -> void:
	await _show_menu()
	_button("Resume").pressed.emit()
	assert_array(_requests).is_equal([false])


func test_cancel_at_the_root_requests_a_resume() -> void:
	await _show_menu()
	await _press_action(Actions.UI_CANCEL)
	assert_array(_requests).is_equal([false])


func test_options_then_controls_then_cancel_goes_back_to_pause() -> void:
	await _show_menu()
	_button("OptionsButton").pressed.emit()
	assert_str(_menu().current().name).is_equal("Options")
	_button("Controls").pressed.emit()
	assert_str(_menu().current().name).is_equal("Controls")
	await _press_action(Actions.UI_CANCEL)
	assert_str(_menu().current().name).is_equal("Options")
	await _press_action(Actions.UI_CANCEL)
	assert_str(_menu().current().name).is_equal("Pause")
	assert_array(_requests).is_empty()


func test_restart_requests_a_restart() -> void:
	await _show_menu()
	_button("Restart").pressed.emit()
	assert_int(_restarts).is_equal(1)


func test_quit_requests_the_title() -> void:
	await _show_menu()
	_button("Quit").pressed.emit()
	assert_int(_title_requests).is_equal(1)


func test_losing_focus_while_hidden_in_running_requests_a_pause() -> void:
	_pause.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_array(_requests).is_equal([true])


func test_losing_focus_after_the_run_ended_requests_nothing() -> void:
	Game.phase = Game.Phase.ENDED
	_pause.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_array(_requests).is_empty()


func test_every_page_fits_the_view() -> void:
	await _show_menu()
	await await_idle_frame()
	assert_array(UiLayout.outside_view(_pause.get_node("%Root"))).is_empty()
	_button("OptionsButton").pressed.emit()
	await await_idle_frame()
	await await_idle_frame()
	assert_array(UiLayout.outside_view(_pause.get_node("%Root"))).is_empty()
	_button("Controls").pressed.emit()
	await await_idle_frame()
	await await_idle_frame()
	assert_array(UiLayout.outside_view(_pause.get_node("%Root"))).is_empty()
