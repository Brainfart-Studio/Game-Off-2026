extends GdUnitTestSuite

const UiLayout = preload("res://test/ui/ui_layout.gd")

const TEST_PATH: String = "user://controls_page_test.cfg"
const DEFAULT_PATH: String = "user://settings.cfg"
const KEYBOARD := InputRebinder.Device.KEYBOARD
const GAMEPAD := InputRebinder.Device.GAMEPAD

var _page: ControlsPage
var _runner: GdUnitSceneRunner


func before_test() -> void:
	_remove_file()
	Settings.path = TEST_PATH
	Settings.load_file()
	InputMap.load_from_project_settings()
	var host: Control = auto_free(Control.new()) as Control
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.theme = UiTheme.build(load("res://config/ui/ui_config.tres") as UiConfig)
	_page = (load("res://scenes/ui/controls_page.tscn") as PackedScene).instantiate() as ControlsPage
	host.add_child(_page)
	_runner = scene_runner(host)
	_page.opened()


func after_test() -> void:
	InputMap.load_from_project_settings()
	Settings.path = DEFAULT_PATH
	Settings.load_file()
	Settings.apply()
	Events.settings_changed.emit()
	_remove_file()


func _remove_file() -> void:
	var absolute: String = ProjectSettings.globalize_path(TEST_PATH)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)


func _cell(action: StringName, device: InputRebinder.Device) -> BindingButton:
	for node: Node in _page.find_children("*", "BindingButton", true, false):
		var button: BindingButton = node as BindingButton
		if button.action == action and button.device == device:
			return button
	return null


func _status() -> String:
	return (_page.get_node("%Status") as Label).text


func _key_codes(action: StringName) -> Array:
	var codes: Array = []
	for event: InputEvent in InputRebinder.events_for(action, KEYBOARD):
		codes.append(InputRebinder.code(event))
	return codes


func _send_key(keycode: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await await_idle_frame()
	var release: InputEventKey = event.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()


func _send_button(index: JoyButton) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await await_idle_frame()
	var release: InputEventJoypadButton = event.duplicate() as InputEventJoypadButton
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()


func test_rows_show_the_current_bindings() -> void:
	assert_str(_cell(Actions.JUMP, KEYBOARD).text).is_equal("SPACE/Z")
	var pad: BindingButton = _cell(Actions.JUMP, GAMEPAD)
	assert_bool(pad.icon != null or pad.text == "A").is_true()


func test_there_is_a_row_for_every_rebindable_action() -> void:
	for action: StringName in InputRebinder.REBINDABLE:
		assert_object(_cell(action, KEYBOARD)).is_not_null()
		assert_object(_cell(action, GAMEPAD)).is_not_null()


func test_first_focus_is_the_first_keyboard_cell() -> void:
	assert_object(_page.first_focus).is_same(_cell(InputRebinder.REBINDABLE[0], KEYBOARD))


func test_pressing_a_cell_waits_for_input() -> void:
	_cell(Actions.JUMP, KEYBOARD).pressed.emit()
	assert_str(_cell(Actions.JUMP, KEYBOARD).text).is_equal(ControlsPage.WAITING)
	assert_str(_status()).is_equal(ControlsPage.PRESS_KEY)
	_page.opened()
	_cell(Actions.JUMP, GAMEPAD).pressed.emit()
	assert_str(_status()).is_equal(ControlsPage.PRESS_BUTTON)


func test_a_key_press_rebinds_saves_and_clears_the_status() -> void:
	_cell(Actions.JUMP, KEYBOARD).pressed.emit()
	await _send_key(KEY_Q)
	assert_array(_key_codes(Actions.JUMP)).is_equal([KEY_Q])
	assert_str(_status()).is_equal("")
	assert_str(_cell(Actions.JUMP, KEYBOARD).text).is_equal("Q")
	var file: ConfigFile = ConfigFile.new()
	assert_int(file.load(TEST_PATH)).is_equal(OK)
	assert_bool(file.has_section(Settings.SECTION_INPUT)).is_true()
	var saved: Array = file.get_value(Settings.SECTION_INPUT, "%s.keyboard" % Actions.JUMP)
	assert_array(saved).is_equal([KEY_Q])


func test_a_button_press_while_listening_for_a_key_cancels() -> void:
	_cell(Actions.JUMP, KEYBOARD).pressed.emit()
	await _send_button(JOY_BUTTON_X)
	assert_array(_key_codes(Actions.JUMP)).is_equal([KEY_SPACE, KEY_Z])
	assert_str(_status()).is_equal("")
	assert_str(_cell(Actions.JUMP, KEYBOARD).text).is_equal("SPACE/Z")


func test_listening_times_out() -> void:
	_cell(Actions.JUMP, KEYBOARD).pressed.emit()
	_page._process(ControlsPage.LISTEN_TIME)
	assert_str(_status()).is_equal("")
	assert_str(_cell(Actions.JUMP, KEYBOARD).text).is_equal("SPACE/Z")
	await _send_key(KEY_Q)
	assert_array(_key_codes(Actions.JUMP)).is_equal([KEY_SPACE, KEY_Z])


func test_reset_restores_the_defaults() -> void:
	_cell(Actions.JUMP, KEYBOARD).pressed.emit()
	await _send_key(KEY_Q)
	(_page.get_node("%Reset") as Button).pressed.emit()
	assert_array(_key_codes(Actions.JUMP)).is_equal([KEY_SPACE, KEY_Z])
	assert_str(_cell(Actions.JUMP, KEYBOARD).text).is_equal("SPACE/Z")


func test_back_requests_going_back() -> void:
	monitor_signals(_page)
	(_page.get_node("%Back") as Button).pressed.emit()
	await assert_signal(_page).is_emitted("back_requested")


func test_page_fits_the_view() -> void:
	await await_idle_frame()
	await await_idle_frame()
	assert_array(UiLayout.outside_view(_page)).is_empty()
