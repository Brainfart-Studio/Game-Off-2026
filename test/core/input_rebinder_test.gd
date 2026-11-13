extends GdUnitTestSuite

const KEYBOARD := InputRebinder.Device.KEYBOARD
const GAMEPAD := InputRebinder.Device.GAMEPAD


func after_test() -> void:
	InputMap.load_from_project_settings()


func _key(keycode: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode
	return event


func _button(index: JoyButton) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = index
	return event


func _codes(action: StringName, device: InputRebinder.Device) -> Array:
	var codes: Array = []
	for event: InputEvent in InputRebinder.events_for(action, device):
		codes.append(InputRebinder.code(event))
	return codes


func test_defaults() -> void:
	assert_str(InputRebinder.binding_label(Actions.JUMP, KEYBOARD)).is_equal("SPACE/Z")
	assert_int(InputRebinder.code(InputRebinder.primary(Actions.SHIFT, GAMEPAD))).is_equal(10)
	assert_str(InputRebinder.label(InputRebinder.primary(Actions.SHIFT, GAMEPAD))).is_equal("RB")


func test_rebind_keyboard_leaves_gamepad() -> void:
	InputRebinder.rebind(Actions.JUMP, KEYBOARD, _key(KEY_Q))
	assert_array(_codes(Actions.JUMP, KEYBOARD)).is_equal([KEY_Q])
	assert_array(_codes(Actions.JUMP, GAMEPAD)).is_equal([0])


func test_keyboard_conflict_keeps_other_binding() -> void:
	InputRebinder.rebind(Actions.JUMP, KEYBOARD, _key(KEY_X))
	assert_array(_codes(Actions.JUMP, KEYBOARD)).is_equal([KEY_X])
	assert_array(_codes(Actions.ATTACK, KEYBOARD)).is_equal([KEY_J])


func test_keyboard_conflict_swaps_when_left_empty() -> void:
	InputRebinder.rebind(Actions.PAUSE, KEYBOARD, _key(KEY_SPACE))
	assert_array(_codes(Actions.PAUSE, KEYBOARD)).is_equal([KEY_SPACE])
	assert_array(_codes(Actions.JUMP, KEYBOARD)).is_equal([KEY_Z])


func test_gamepad_conflict_swaps() -> void:
	InputRebinder.rebind(Actions.JUMP, GAMEPAD, _button(JOY_BUTTON_RIGHT_SHOULDER))
	assert_array(_codes(Actions.JUMP, GAMEPAD)).is_equal([10])
	assert_array(_codes(Actions.SHIFT, GAMEPAD)).is_equal([0])


func test_movement_is_not_rebindable() -> void:
	var before: int = InputMap.action_get_events(Actions.MOVE_LEFT).size()
	assert_error(func() -> void: InputRebinder.rebind(Actions.MOVE_LEFT, KEYBOARD, _key(KEY_Q))) \
		.is_push_error("InputRebinder: move_left is not rebindable")
	assert_int(InputMap.action_get_events(Actions.MOVE_LEFT).size()).is_equal(before)
	var has_motion: bool = false
	for event: InputEvent in InputMap.action_get_events(Actions.MOVE_LEFT):
		has_motion = has_motion or event is InputEventJoypadMotion
	assert_bool(has_motion).is_true()


func test_wrong_device_is_an_error() -> void:
	assert_error(func() -> void: InputRebinder.rebind(Actions.JUMP, KEYBOARD, _button(JOY_BUTTON_A))) \
		.is_push_error("InputRebinder: wrong device for jump")
	assert_array(_codes(Actions.JUMP, KEYBOARD)).is_equal([KEY_SPACE, KEY_Z])


func test_snapshot_reset_and_apply() -> void:
	InputRebinder.rebind(Actions.JUMP, KEYBOARD, _key(KEY_Q))
	InputRebinder.rebind(Actions.SHIFT, GAMEPAD, _button(JOY_BUTTON_Y))
	var data: Dictionary = InputRebinder.snapshot()
	InputRebinder.reset_to_defaults()
	assert_array(_codes(Actions.JUMP, KEYBOARD)).is_equal([KEY_SPACE, KEY_Z])
	InputRebinder.apply_snapshot(data)
	assert_array(_codes(Actions.JUMP, KEYBOARD)).is_equal([KEY_Q])
	assert_array(_codes(Actions.SHIFT, GAMEPAD)).is_equal([3])
	assert_dict(InputRebinder.snapshot()).is_equal(data)


func test_apply_snapshot_skips_bad_entries() -> void:
	InputRebinder.apply_snapshot({
		"move_left.keyboard": [KEY_Q],
		"jump.mouse": [1],
		"jump.keyboard": "nope",
		"jump": [1],
	})
	assert_array(_codes(Actions.JUMP, KEYBOARD)).is_equal([KEY_SPACE, KEY_Z])
	assert_int(InputMap.action_get_events(Actions.MOVE_LEFT).size()).is_equal(4)


func test_labels() -> void:
	assert_str(InputRebinder.label(_button(17 as JoyButton))).is_equal("BUTTON 17")
	assert_str(InputRebinder.label(null)).is_equal("-")
	assert_str(InputRebinder.label(_key(KEY_ESCAPE))).is_equal("ESCAPE")


func test_glyph_path() -> void:
	assert_str(InputRebinder.glyph_path(_button(JOY_BUTTON_A))) \
		.is_equal("res://art/ui/glyphs/glyph_pad_a.png")
	assert_str(InputRebinder.glyph_path(_key(KEY_A))).is_empty()
	assert_str(InputRebinder.glyph_path(_button(JOY_BUTTON_GUIDE))).is_empty()


func test_gamepad_accept_and_cancel() -> void:
	assert_bool(InputMap.event_is_action(_button(JOY_BUTTON_A), Actions.UI_ACCEPT)).is_true()
	assert_bool(InputMap.event_is_action(_button(JOY_BUTTON_B), Actions.UI_CANCEL)).is_true()
