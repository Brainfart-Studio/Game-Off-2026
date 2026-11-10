class_name OptionStepper
extends Button
## A button that shows `LABEL  < value >` and changes the value with `ui_left` and `ui_right`.
## Focus stays on it while stepping.

signal value_changed(value: int)

const FORMAT := "%s  < %d >"
const MOVE_SOUND := &"ui_move"

@export var label_text: String = "":
	set(new_text):
		label_text = new_text
		_refresh()
@export var max_value: int = 10

## The current step. Setting it clamps to 0 to `max_value` and does not emit.
var value: int = 0:
	set(new_value):
		value = clampi(new_value, 0, max_value)
		_refresh()


## Moves the value by `delta`, clamped. At a limit nothing happens. Plays a sound and emits
## `value_changed` on a real change.
func step(delta: int) -> void:
	var target: int = clampi(value + delta, 0, max_value)
	if target == value:
		return
	value = target
	Audio.play(MOVE_SOUND)
	value_changed.emit(value)


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed(Actions.UI_LEFT, true):
		step(-1)
		accept_event()
	elif event.is_action_pressed(Actions.UI_RIGHT, true):
		step(1)
		accept_event()


func _refresh() -> void:
	text = FORMAT % [label_text, value]
