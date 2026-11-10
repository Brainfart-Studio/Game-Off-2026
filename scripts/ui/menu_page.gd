class_name MenuPage
extends Control
## One page of a `MenuStack`. A page asks the stack to open another page or go back.

signal push_requested(page_name: StringName)
signal back_requested()

const CONFIRM_SOUND := &"ui_confirm"

## The control that takes focus when the page opens.
@export var first_focus: Control


func _ready() -> void:
	for node: Node in find_children("*", "BaseButton", true, false):
		(node as BaseButton).pressed.connect(_on_button_pressed)


## Called each time the page is shown. Pages refresh their content here.
func opened() -> void:
	pass


func _on_button_pressed() -> void:
	Audio.play(CONFIRM_SOUND)
