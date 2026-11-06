class_name State
extends Node
## Base class for a state in a StateMachine. Override the virtuals as needed.

var machine: StateMachine
var actor: Node


func enter(_previous: StringName) -> void:
	pass


func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass
