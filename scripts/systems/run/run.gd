class_name Run
extends Node2D
## Composition root of the run scene. Its `_ready` runs after every child is ready, and it is
## the only script that calls setup methods on the modules it composes (R-059).

@onready var arena: Arena = $Arena
@onready var player: Player = $Player
@onready var world_shift: WorldShift = $WorldShift


func _ready() -> void:
	Game.reset()
