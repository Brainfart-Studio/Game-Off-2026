class_name InitialsEntry
extends HBoxContainer
## Three letters picked with the menu actions. Up and down change the letter, left and right
## move the slot, accept confirms. Only reacts to input while `active`.

signal confirmed(initials: String)

const SLOTS := 3
const FIRST_LETTER := 65
const LETTER_COUNT := 26
const MOVE_SOUND := &"ui_move"
const CONFIRM_SOUND := &"ui_confirm"

@export var config: UiConfig

## True while the entry listens for input.
var active: bool = false:
	set(value):
		active = value
		set_process_unhandled_input(value)
		_refresh()

var _letters: Array[int] = []
var _labels: Array[Label] = []
var _slot: int = 0


func _init() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	set_process_unhandled_input(false)
	for i: int in SLOTS:
		_letters.append(0)
		var label: Label = Label.new()
		add_child(label)
		_labels.append(label)
	_refresh()


## Shows `initials` (letters only, padded with A) and selects the first slot.
func setup(initials: String) -> void:
	var text: String = initials.to_upper()
	for i: int in SLOTS:
		var index: int = 0
		if i < text.length():
			index = text.unicode_at(i) - FIRST_LETTER
		_letters[i] = index if index >= 0 and index < LETTER_COUNT else 0
	_slot = 0
	_refresh()


## The letters as shown.
func text() -> String:
	var result: String = ""
	for index: int in _letters:
		result += char(FIRST_LETTER + index)
	return result


## Steps the selected letter, wrapping from Z to A and from A to Z.
func change_letter(step: int) -> void:
	_letters[_slot] = posmod(_letters[_slot] + step, LETTER_COUNT)
	Audio.play(MOVE_SOUND)
	_refresh()


## Moves the selected slot, stopping at the first and last.
func move(step: int) -> void:
	var target: int = clampi(_slot + step, 0, SLOTS - 1)
	if target == _slot:
		return
	_slot = target
	Audio.play(MOVE_SOUND)
	_refresh()


func confirm() -> void:
	Audio.play(CONFIRM_SOUND)
	confirmed.emit(text())


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed(Actions.UI_UP, true):
		change_letter(1)
	elif event.is_action_pressed(Actions.UI_DOWN, true):
		change_letter(-1)
	elif event.is_action_pressed(Actions.UI_LEFT, true):
		move(-1)
	elif event.is_action_pressed(Actions.UI_RIGHT, true):
		move(1)
	elif event.is_action_pressed(Actions.UI_ACCEPT):
		confirm()
	else:
		return
	get_viewport().set_input_as_handled()


func _refresh() -> void:
	if config == null:
		config = UiConfig.new()
	for i: int in SLOTS:
		_labels[i].text = char(FIRST_LETTER + _letters[i])
		var color: Color = config.text_color
		if active and i == _slot:
			color = config.highlight_color
		_labels[i].add_theme_color_override(&"font_color", color)
