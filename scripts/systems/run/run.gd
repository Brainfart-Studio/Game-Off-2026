class_name Run
extends Node2D
## Composition root of the run scene. Its `_ready` runs after every child is ready, and it is
## the only script that calls setup methods on the modules it composes (R-059).

@export var config: RunConfig
## Pauses the tree when the run ends. Tests turn it off.
@export var pause_tree_on_end: bool = true

@onready var arena: Arena = $Arena
@onready var player: Player = $Player
@onready var world_shift: WorldShift = $WorldShift
@onready var machine: StateMachine = $StateMachine


func _ready() -> void:
	Game.reset()
	arena.setup()
	player.spawn(arena.player_spawn_position())
	world_shift.start()
	config.check()
	Game.run_duration = config.duration
	Game.time_left = config.duration
	machine.transition_to(&"Starting")
