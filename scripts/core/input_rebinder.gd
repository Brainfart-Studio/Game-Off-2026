## Rebinds one key and one gamepad button per action (R-082).
##
## Static only. Rebinding an input that another rebindable action already uses on the same
## device moves that action to the old input of the rebound action when it would be left with
## none. Events of other types (joypad motion) are never touched.
class_name InputRebinder
extends RefCounted

enum Device { KEYBOARD, GAMEPAD }

const REBINDABLE: Array[StringName] = [Actions.JUMP, Actions.ATTACK, Actions.SHIFT, Actions.PAUSE]
const DEVICE_KEYS := {Device.KEYBOARD: "keyboard", Device.GAMEPAD: "gamepad"}
const BUTTON_NAMES := {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "BACK",
	JOY_BUTTON_GUIDE: "GUIDE",
	JOY_BUTTON_START: "START",
	JOY_BUTTON_LEFT_STICK: "LS",
	JOY_BUTTON_RIGHT_STICK: "RS",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "UP",
	JOY_BUTTON_DPAD_DOWN: "DOWN",
	JOY_BUTTON_DPAD_LEFT: "LEFT",
	JOY_BUTTON_DPAD_RIGHT: "RIGHT",
}
const GLYPH_IDS := {
	JOY_BUTTON_A: "a",
	JOY_BUTTON_B: "b",
	JOY_BUTTON_X: "x",
	JOY_BUTTON_Y: "y",
	JOY_BUTTON_BACK: "back",
	JOY_BUTTON_START: "start",
	JOY_BUTTON_LEFT_STICK: "ls",
	JOY_BUTTON_RIGHT_STICK: "rs",
	JOY_BUTTON_LEFT_SHOULDER: "lb",
	JOY_BUTTON_RIGHT_SHOULDER: "rb",
	JOY_BUTTON_DPAD_UP: "dpad_up",
	JOY_BUTTON_DPAD_DOWN: "dpad_down",
	JOY_BUTTON_DPAD_LEFT: "dpad_left",
	JOY_BUTTON_DPAD_RIGHT: "dpad_right",
}
const GLYPH_PATH := "res://art/ui/glyphs/glyph_pad_%s.png"
const UNKNOWN_BUTTON := "BUTTON %d"
const NONE := "-"
const SEPARATOR := "/"
## The headless display server cannot map physical keys to layout keys, so labels use the physical key.
const HEADLESS_DISPLAY := "headless"


## True when `event` belongs to `device`: a key for the keyboard, a button for the gamepad.
static func is_device_event(event: InputEvent, device: Device) -> bool:
	match device:
		Device.KEYBOARD:
			return event is InputEventKey
		Device.GAMEPAD:
			return event is InputEventJoypadButton
	return false


## The key or button code of `event`, or -1 for any other event.
static func code(event: InputEvent) -> int:
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		return int(key.physical_keycode) if key.physical_keycode != KEY_NONE else int(key.keycode)
	if event is InputEventJoypadButton:
		return int((event as InputEventJoypadButton).button_index)
	return -1


## A new event for `device` with `event_code`, bound to all devices and with no modifiers.
static func make_event(device: Device, event_code: int) -> InputEvent:
	if device == Device.KEYBOARD:
		var key: InputEventKey = InputEventKey.new()
		key.physical_keycode = event_code as Key
		return key
	var button: InputEventJoypadButton = InputEventJoypadButton.new()
	button.button_index = event_code as JoyButton
	return button


## The events of `action` that belong to `device`, in InputMap order.
static func events_for(action: StringName, device: Device) -> Array[InputEvent]:
	var found: Array[InputEvent] = []
	if not InputMap.has_action(action):
		return found
	for event: InputEvent in InputMap.action_get_events(action):
		if is_device_event(event, device):
			found.append(event)
	return found


## The first event of `action` on `device`, or null.
static func primary(action: StringName, device: Device) -> InputEvent:
	var found: Array[InputEvent] = events_for(action, device)
	return null if found.is_empty() else found[0]


## Binds `action` on the device of `event` to the code of `event` and moves any conflict away.
static func rebind(action: StringName, device: Device, event: InputEvent) -> void:
	if not REBINDABLE.has(action):
		push_error("InputRebinder: %s is not rebindable" % action)
		return
	if not is_device_event(event, device):
		push_error("InputRebinder: wrong device for %s" % action)
		return
	var new_code: int = code(event)
	var old: InputEvent = primary(action, device)
	for other: StringName in REBINDABLE:
		if other == action:
			continue
		var erased: bool = false
		for existing: InputEvent in events_for(other, device):
			if code(existing) == new_code:
				InputMap.action_erase_event(other, existing)
				erased = true
		if erased and old != null and events_for(other, device).is_empty():
			InputMap.action_add_event(other, make_event(device, code(old)))
	_erase_device(action, device)
	InputMap.action_add_event(action, make_event(device, new_code))


## The rebindable bindings as `"<action>.<device>"` to an Array of codes.
static func snapshot() -> Dictionary:
	var data: Dictionary = {}
	for action: StringName in REBINDABLE:
		for device: Device in DEVICE_KEYS:
			var codes: Array = []
			for event: InputEvent in events_for(action, device):
				codes.append(code(event))
			data["%s.%s" % [action, DEVICE_KEYS[device]]] = codes
	return data


## Restores bindings from `snapshot()` output. Unknown actions, devices, or values are skipped.
static func apply_snapshot(data: Dictionary) -> void:
	for key: Variant in data:
		var parts: PackedStringArray = str(key).split(".")
		if parts.size() != 2 or not data[key] is Array:
			continue
		var action := StringName(parts[0])
		if not REBINDABLE.has(action):
			continue
		var device: int = DEVICE_KEYS.values().find(parts[1])
		if device < 0:
			continue
		_erase_device(action, device as Device)
		for value: Variant in data[key] as Array:
			if value is int:
				InputMap.action_add_event(action, make_event(device as Device, value as int))


## Restores every action to the bindings in `project.godot`.
static func reset_to_defaults() -> void:
	InputMap.load_from_project_settings()


## A display name for `event`: the key name, the button name, or `NONE`.
static func label(event: InputEvent) -> String:
	if event == null:
		return NONE
	if event is InputEventJoypadButton:
		var index: int = code(event)
		return BUTTON_NAMES.get(index, UNKNOWN_BUTTON % index)
	if event is InputEventKey:
		var keycode: Key = code(event) as Key
		if DisplayServer.get_name() != HEADLESS_DISPLAY:
			keycode = DisplayServer.keyboard_get_keycode_from_physical(keycode)
		return OS.get_keycode_string(keycode).to_upper()
	return NONE


## Display names of every binding of `action` on `device`, joined by `SEPARATOR`.
static func binding_label(action: StringName, device: Device) -> String:
	var names: PackedStringArray = []
	for event: InputEvent in events_for(action, device):
		names.append(label(event))
	return NONE if names.is_empty() else SEPARATOR.join(names)


## The glyph image path for a gamepad button, or "" when it has none.
static func glyph_path(event: InputEvent) -> String:
	if event is InputEventJoypadButton and GLYPH_IDS.has(code(event)):
		return GLYPH_PATH % GLYPH_IDS[code(event)]
	return ""


static func _erase_device(action: StringName, device: Device) -> void:
	for event: InputEvent in events_for(action, device):
		InputMap.action_erase_event(action, event)
