class_name PlayerState
extends State
## Base for player states. `player` is the machine's owner, typed.

var player: Player


func enter(_previous: StringName) -> void:
	player = actor as Player
