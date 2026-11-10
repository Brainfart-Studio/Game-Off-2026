extends GdUnitTestSuite

const UiLayout = preload("res://test/ui/ui_layout.gd")

const TEST_PATH: String = "user://options_page_test.cfg"
const DEFAULT_PATH: String = "user://settings.cfg"

var _page: OptionsPage
var _runner: GdUnitSceneRunner


func before_test() -> void:
	_remove_file()
	Settings.path = TEST_PATH
	Settings.load_file()
	Settings.apply()
	var host: Control = auto_free(Control.new()) as Control
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.theme = UiTheme.build(load("res://config/ui/ui_config.tres") as UiConfig)
	_page = (load("res://scenes/ui/options_page.tscn") as PackedScene).instantiate() as OptionsPage
	host.add_child(_page)
	_runner = scene_runner(host)
	_page.opened()


func after_test() -> void:
	Settings.path = DEFAULT_PATH
	Settings.load_file()
	Settings.apply()
	Events.settings_changed.emit()
	_remove_file()


func _remove_file() -> void:
	var absolute: String = ProjectSettings.globalize_path(TEST_PATH)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)


func _stepper(node_name: String) -> OptionStepper:
	return _page.get_node("%" + node_name) as OptionStepper


func _toggle(node_name: String) -> OptionToggle:
	return _page.get_node("%" + node_name) as OptionToggle


func _button(node_name: String) -> Button:
	return _page.get_node("%" + node_name) as Button


func test_opened_shows_the_settings_values() -> void:
	Settings.master_volume = 4
	Settings.music_volume = 6
	Settings.sfx_volume = 0
	Settings.shake_enabled = false
	Settings.flash_enabled = true
	_page.opened()
	assert_int(_stepper("Master").value).is_equal(4)
	assert_int(_stepper("Music").value).is_equal(6)
	assert_int(_stepper("Sfx").value).is_equal(0)
	assert_bool(_toggle("Shake").button_pressed).is_false()
	assert_bool(_toggle("Flash").button_pressed).is_true()
	assert_str(_toggle("Shake").text).is_equal("SCREEN SHAKE  OFF")
	assert_str(_stepper("Master").text).is_equal("MASTER  < 4 >")


func test_master_step_lowers_the_setting() -> void:
	_stepper("Master").step(-1)
	assert_int(Settings.master_volume).is_equal(Settings.VOLUME_STEPS - 1)


func test_music_and_sfx_steppers_change_their_own_volumes() -> void:
	_stepper("Music").step(-2)
	_stepper("Sfx").step(-3)
	assert_int(Settings.music_volume).is_equal(Settings.VOLUME_STEPS - 2)
	assert_int(Settings.sfx_volume).is_equal(Settings.VOLUME_STEPS - 3)
	assert_int(Settings.master_volume).is_equal(Settings.VOLUME_STEPS)


func test_shake_off_updates_settings_and_feedback() -> void:
	_toggle("Shake").button_pressed = false
	assert_bool(Settings.shake_enabled).is_false()
	assert_bool(Feedback.shake_enabled).is_false()
	assert_bool(Settings.flash_enabled).is_true()


func test_flash_off_updates_settings_and_feedback() -> void:
	_toggle("Flash").button_pressed = false
	assert_bool(Settings.flash_enabled).is_false()
	assert_bool(Feedback.flash_enabled).is_false()


func test_reset_restores_defaults_and_widgets() -> void:
	_stepper("Master").step(-4)
	_toggle("Shake").button_pressed = false
	_button("Reset").pressed.emit()
	assert_int(Settings.master_volume).is_equal(Settings.VOLUME_STEPS)
	assert_bool(Settings.shake_enabled).is_true()
	assert_int(_stepper("Master").value).is_equal(Settings.VOLUME_STEPS)
	assert_bool(_toggle("Shake").button_pressed).is_true()
	assert_str(_toggle("Shake").text).is_equal("SCREEN SHAKE  ON")


func test_controls_requests_the_controls_page() -> void:
	monitor_signals(_page)
	_button("Controls").pressed.emit()
	await assert_signal(_page).is_emitted("push_requested", [&"Controls"])


func test_back_requests_going_back() -> void:
	monitor_signals(_page)
	_button("Back").pressed.emit()
	await assert_signal(_page).is_emitted("back_requested")


func test_first_focus_is_master() -> void:
	assert_object(_page.first_focus).is_same(_stepper("Master"))


func test_page_fits_the_view() -> void:
	await await_idle_frame()
	await await_idle_frame()
	assert_array(UiLayout.outside_view(_page)).is_empty()
