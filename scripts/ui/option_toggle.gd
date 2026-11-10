class_name OptionToggle
extends Button
## A toggle button that shows `LABEL  ON` or `LABEL  OFF`.

const FORMAT := "%s  %s"
const ON := "ON"
const OFF := "OFF"

@export var label_text: String = "":
	set(new_text):
		label_text = new_text
		_refresh()


func _init() -> void:
	toggle_mode = true


func _ready() -> void:
	toggled.connect(_on_toggled)
	_refresh()


## Sets the state without emitting `toggled`.
func set_on(on: bool) -> void:
	set_pressed_no_signal(on)
	_refresh()


func _on_toggled(_on: bool) -> void:
	_refresh()


func _refresh() -> void:
	text = FORMAT % [label_text, ON if button_pressed else OFF]
