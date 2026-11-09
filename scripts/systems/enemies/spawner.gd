class_name Spawner
extends Node
## Spawns enemies in the combat world, ramping with run progress. It only counts down while the
## run is live and the combat world is shown. Each spawn is a telegraph that places the enemy.

const TELEGRAPH_SCENE: PackedScene = preload("res://scenes/enemies/spawn_telegraph.tscn")

@export var config: SpawnConfig

var _countdown: float = 0.0


func _ready() -> void:
	config.check()
	_countdown = config.first_delay
	Events.run_started.connect(_on_run_started)


func _physics_process(delta: float) -> void:
	if not Game.is_combat_live():
		return
	_countdown -= delta
	if _countdown > 0.0:
		return
	var progress: float = Game.run_progress()
	if _alive_count() < config.max_alive_at(progress):
		_spawn_telegraph()
	_countdown = config.interval_at(progress)


func _on_run_started() -> void:
	_countdown = config.first_delay


## Enemies plus telegraphs that have not yet become enemies.
func _alive_count() -> int:
	return (
		get_tree().get_nodes_in_group(Groups.ENEMY).size()
		+ get_tree().get_nodes_in_group(Groups.SPAWN_TELEGRAPH).size()
	)


## A random spawn marker far enough from the player, or null.
func _pick_marker() -> Node2D:
	var options: Array[Node2D] = []
	for node: Node in get_tree().get_nodes_in_group(Groups.ENEMY_SPAWN):
		var marker: Node2D = node as Node2D
		if marker == null:
			continue
		if Game.has_player():
			var distance: float = marker.global_position.distance_to(Game.player.global_position)
			if distance < config.min_player_distance:
				continue
		options.append(marker)
	if options.is_empty():
		return null
	return options.pick_random()


func _spawn_telegraph() -> void:
	var parent: Node2D = Game.content_parent(World.Id.COMBAT)
	var marker: Node2D = _pick_marker()
	if parent == null or marker == null or config.enemies.is_empty():
		return
	var data: EnemyData = config.enemies.pick_random()
	var telegraph: SpawnTelegraph = TELEGRAPH_SCENE.instantiate() as SpawnTelegraph
	telegraph.setup(data, config.telegraph_time, config.telegraph_animation)
	telegraph.position = parent.to_local(marker.global_position)
	parent.add_child(telegraph)
