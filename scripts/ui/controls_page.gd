class_name ControlsPage
extends MenuPage
## Rebinds one key and one gamepad button per action. Pressing a cell listens for the next input
## of that cell's device for `LISTEN_TIME` seconds. An input of the other device cancels.

const HEADING := "CONTROLS"
const KEYBOARD := "KEYBOARD"
const GAMEPAD := "GAMEPAD"
const RESET := "RESET CONTROLS"
const BACK := "BACK"
const PRESS_KEY := "PRESS A KEY"
const PRESS_BUTTON := "PRESS A BUTTON"
const WAITING := "..."
const LISTEN_TIME := 5.0
const ACTION_NAMES := {
	Actions.JUMP: "JUMP",
	Actions.ATTACK: "ATTACK",
	Actions.SHIFT: "SHIFT",
	Actions.PAUSE: "PAUSE",
}
const CONFIRM_SOUND := &"ui_confirm"
const BACK_SOUND := &"ui_back"
const NAME_WIDTH := 56.0
const CELL_WIDTH := 72.0
const ROW_SEPARATION := 4

var _buttons: Array[BindingButton] = []
var _listening: BindingButton = null
var _listen_left: float = 0.0

@onready var _heading: Label = %Heading
@onready var _keyboard_header: Label = %KeyboardHeader
@onready var _gamepad_header: Label = %GamepadHeader
@onready var _rows: VBoxContainer = %Rows
@onready var _status: Label = %Status
@onready var _reset: Button = %Reset
@onready var _back: Button = %Back


func _ready() -> void:
	_heading.text = HEADING
	_keyboard_header.text = KEYBOARD
	_gamepad_header.text = GAMEPAD
	_reset.text = RESET
	_back.text = BACK
	for action: StringName in InputRebinder.REBINDABLE:
		_add_row(action)
	first_focus = _buttons[0]
	_reset.pressed.connect(_on_reset)
	_back.pressed.connect(back_requested.emit)
	super._ready()


func opened() -> void:
	_stop_listening()
	_refresh_all()


func _process(delta: float) -> void:
	if _listening == null:
		return
	_listen_left -= delta
	if _listen_left <= 0.0:
		_stop_listening()


func _input(event: InputEvent) -> void:
	if _listening == null:
		return
	if not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if not event.is_pressed() or event.is_echo():
		return
	if InputRebinder.is_device_event(event, _listening.device):
		InputRebinder.rebind(_listening.action, _listening.device, event)
		Settings.save_input_bindings()
		Audio.play(CONFIRM_SOUND)
		_stop_listening()
		_refresh_all()
	else:
		Audio.play(BACK_SOUND)
		_stop_listening()


func _add_row(action: StringName) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", ROW_SEPARATION)
	var label: Label = Label.new()
	label.text = ACTION_NAMES[action]
	label.custom_minimum_size.x = NAME_WIDTH
	row.add_child(label)
	for device: InputRebinder.Device in [InputRebinder.Device.KEYBOARD, InputRebinder.Device.GAMEPAD]:
		var button: BindingButton = BindingButton.new()
		button.action = action
		button.device = device
		button.custom_minimum_size.x = CELL_WIDTH
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(_start_listening.bind(button))
		row.add_child(button)
		_buttons.append(button)
		button.refresh()
	_rows.add_child(row)


func _start_listening(button: BindingButton) -> void:
	_stop_listening()
	_listening = button
	_listen_left = LISTEN_TIME
	button.show_waiting(WAITING)
	_status.text = PRESS_KEY if button.device == InputRebinder.Device.KEYBOARD else PRESS_BUTTON


func _stop_listening() -> void:
	if _listening != null:
		_listening.refresh()
	_listening = null
	_status.text = ""


func _refresh_all() -> void:
	for button: BindingButton in _buttons:
		button.refresh()


func _on_reset() -> void:
	_stop_listening()
	Settings.reset_input_bindings()
	_refresh_all()
