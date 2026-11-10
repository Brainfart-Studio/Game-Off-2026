extends Node
## Run state (autoload `Game`).
##
## Run is the only writer of `phase`, `paused`, `run_duration`, and `time_left`. `world` and `player`
## follow events. Everything else only reads.

enum Phase { NONE, STARTING, RUNNING, ENDED }

var phase: Phase = Phase.NONE
## True while the run is paused. Run writes it on `run_pause_requested`.
var paused: bool = false
var world: World.Id = World.Id.PEACEFUL
var player: Node2D
var run_duration: float = 0.0
var time_left: float = 0.0

var _content: Dictionary[int, Node2D] = {}


func _ready() -> void:
	Events.world_shifted.connect(_on_world_shifted)
	Events.player_spawned.connect(_on_player_spawned)


## Puts every field back to its default. Run calls this first when the run scene loads.
func reset() -> void:
	phase = Phase.NONE
	paused = false
	world = World.Id.PEACEFUL
	player = null
	run_duration = 0.0
	time_left = 0.0
	_content.clear()


## Registers the node that holds a world's combat or peaceful content.
func register_content(id: World.Id, parent: Node2D) -> void:
	_content[id] = parent


## The registered content parent for a world, or null (with an error) if missing.
func content_parent(id: World.Id) -> Node2D:
	var parent: Node2D = _content.get(id) as Node2D
	if parent == null or not is_instance_valid(parent):
		push_error("Game: no content parent for %s" % World.Id.keys()[id])
		return null
	return parent


func has_player() -> bool:
	return player != null and is_instance_valid(player)


## Fraction of the run elapsed, 0 to 1. 0 when no duration is set.
func run_progress() -> float:
	if run_duration <= 0.0:
		return 0.0
	return clampf(1.0 - time_left / run_duration, 0.0, 1.0)


## True while the run is live, not paused, and the combat world is shown.
func is_combat_live() -> bool:
	return phase == Phase.RUNNING and not paused and world == World.Id.COMBAT


func _on_world_shifted(to: World.Id) -> void:
	world = to


func _on_player_spawned(spawned: Node2D) -> void:
	player = spawned
