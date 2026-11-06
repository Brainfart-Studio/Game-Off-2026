class_name PlayerInput
extends Node
## Player input snapshot. `read()` is called first in each physics frame.

var move: Vector2 = Vector2.ZERO
var move_x: float = 0.0
var jump_pressed: bool = false
var jump_held: bool = false
var jump_released: bool = false


func read(analog_run: bool) -> void:
	move = Input.get_vector(Actions.MOVE_LEFT, Actions.MOVE_RIGHT, Actions.MOVE_UP, Actions.MOVE_DOWN)
	move_x = move.x if analog_run else signf(move.x)
	jump_pressed = Input.is_action_just_pressed(Actions.JUMP)
	jump_held = Input.is_action_pressed(Actions.JUMP)
	jump_released = Input.is_action_just_released(Actions.JUMP)
