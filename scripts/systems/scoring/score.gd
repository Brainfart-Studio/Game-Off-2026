class_name Score
extends Node
## The run's score. Landed hits and kills in the combat world add to it.

@export var config: ScoreConfig

## Score so far this run.
var score: int = 0
## Combo bar fill, 0 to 1.
var fill: float = 0.0
## Current multiplier, 1 or more.
var multiplier: int = 1


func _ready() -> void:
	config.check()
	Events.hit_landed.connect(_on_hit_landed)
	Events.enemy_killed.connect(_on_enemy_killed)
	Events.run_started.connect(_on_run_started)


func _on_hit_landed(_info: DamageInfo) -> void:
	if Game.world != World.Id.COMBAT:
		return
	_add_score(config.score_per_hit * multiplier)
	_add_fill(config.fill_per_hit)


func _on_enemy_killed(_enemy: Node2D, data: EnemyData, _info: DamageInfo) -> void:
	if Game.world != World.Id.COMBAT or data == null:
		return
	_add_score(data.score_value * multiplier)


func _on_run_started() -> void:
	Events.score_changed.emit(score)
	Events.combo_changed.emit(fill, multiplier)


func _add_score(amount: int) -> void:
	score += amount
	Events.score_changed.emit(score)


func _add_fill(amount: float) -> void:
	fill += amount
	if fill >= 1.0:
		if multiplier < config.max_multiplier:
			multiplier += 1
			fill -= 1.0
			Events.combo_raised.emit(multiplier)
		else:
			fill = 1.0
	Events.combo_changed.emit(fill, multiplier)
