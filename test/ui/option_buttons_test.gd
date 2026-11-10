extends GdUnitTestSuite

var _stepper: OptionStepper
var _toggle: OptionToggle
var _neighbor: Button
var _changes: Array[int] = []
var _toggles: int = 0


func before_test() -> void:
	_changes.clear()
	_toggles = 0
	_stepper = auto_free(OptionStepper.new()) as OptionStepper
	_stepper.label_text = "VOL"
	_stepper.max_value = 10
	_stepper.value = 5
	_stepper.value_changed.connect(_on_value_changed)
	_toggle = auto_free(OptionToggle.new()) as OptionToggle
	_toggle.label_text = "SHAKE"
	_toggle.toggled.connect(_on_toggled)
	_neighbor = auto_free(Button.new()) as Button


func after_test() -> void:
	InputMap.load_from_project_settings()


func _on_value_changed(value: int) -> void:
	_changes.append(value)


func _on_toggled(_on: bool) -> void:
	_toggles += 1


func test_stepper_shows_label_and_value() -> void:
	assert_str(_stepper.text).is_equal("VOL  < 5 >")


func test_value_setter_clamps_without_emitting() -> void:
	_stepper.value = 15
	assert_int(_stepper.value).is_equal(10)
	_stepper.value = -3
	assert_int(_stepper.value).is_equal(0)
	assert_array(_changes).is_empty()


func test_step_emits_once_per_change() -> void:
	_stepper.step(1)
	_stepper.step(-2)
	assert_array(_changes).is_equal([6, 4])
	assert_str(_stepper.text).is_equal("VOL  < 4 >")


func test_step_at_a_limit_does_nothing() -> void:
	_stepper.value = 10
	_stepper.step(1)
	_stepper.value = 0
	_stepper.step(-1)
	assert_array(_changes).is_empty()
	assert_int(_stepper.value).is_equal(0)


func test_focused_stepper_takes_right_and_keeps_focus() -> void:
	var box: VBoxContainer = auto_free(VBoxContainer.new()) as VBoxContainer
	box.add_child(_neighbor)
	box.add_child(_stepper)
	scene_runner(box)
	_stepper.grab_focus()
	await await_idle_frame()
	_press(Actions.UI_RIGHT)
	await await_idle_frame()
	assert_array(_changes).is_equal([6])
	assert_bool(_stepper.has_focus()).is_true()
	_press(Actions.UI_LEFT)
	await await_idle_frame()
	assert_array(_changes).is_equal([6, 5])
	assert_bool(_stepper.has_focus()).is_true()


func test_toggle_text_follows_toggled() -> void:
	add_child(_toggle)
	assert_str(_toggle.text).is_equal("SHAKE  OFF")
	_toggle.button_pressed = true
	assert_str(_toggle.text).is_equal("SHAKE  ON")
	_toggle.button_pressed = false
	assert_str(_toggle.text).is_equal("SHAKE  OFF")
	assert_int(_toggles).is_equal(2)


func test_set_on_does_not_emit() -> void:
	add_child(_toggle)
	_toggle.set_on(true)
	assert_bool(_toggle.button_pressed).is_true()
	assert_str(_toggle.text).is_equal("SHAKE  ON")
	assert_int(_toggles).is_equal(0)


func _press(action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	var release: InputEventAction = InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
