class_name Run
extends Node2D
## Composition root of the run scene. Its `_ready` runs after every child is ready, and it is
## the only script that calls setup methods on the modules it composes (R-059).

@export var config: RunConfig
## Pauses the tree when the run ends. Tests turn it off.
@export var pause_tree_on_end: bool = true

## True once the player has died this run.
var died: bool = false
## Tallies for the results. `kills` follows `enemy_killed`; `score` follows `score_changed` and `best_multiplier` is the highest multiplier from `combo_changed`.
var score: int = 0
var kills: int = 0
var best_multiplier: int = 1

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
	Events.player_died.connect(_on_player_died)
	Events.enemy_killed.connect(_on_enemy_killed)
	Events.score_changed.connect(_on_score_changed)
	Events.combo_changed.connect(_on_combo_changed)
	Events.run_restart_requested.connect(restart)
	machine.transition_to(&"Starting")


## The result of the run as it stands.
func build_result() -> RunResult:
	var result: RunResult = RunResult.new()
	result.score = score
	result.kills = kills
	result.best_multiplier = best_multiplier
	result.time_survived = Game.run_duration - Game.time_left
	result.died = died
	return result


## Unpauses and reloads the run scene. Every module starts fresh.
func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_player_died() -> void:
	died = true


func _on_enemy_killed(_enemy: Node2D, _data: EnemyData, _info: DamageInfo) -> void:
	kills += 1


func _on_score_changed(value: int) -> void:
	score = value


func _on_combo_changed(_fill: float, multiplier: int) -> void:
	best_multiplier = maxi(best_multiplier, multiplier)
