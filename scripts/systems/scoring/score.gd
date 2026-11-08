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

var _since_hit: float = 0.0


func _ready() -> void:
	config.check()
	Events.hit_landed.connect(_on_hit_landed)
	Events.enemy_killed.connect(_on_enemy_killed)
	Events.player_damaged.connect(_on_player_damaged)
	Events.run_started.connect(_on_run_started)


func _physics_process(delta: float) -> void:
	if Game.phase != Game.Phase.RUNNING:
		return
	if Game.world != World.Id.COMBAT and not config.drain_in_peaceful:
		return
	if fill <= 0.0 and multiplier <= 1:
		return
	_since_hit += delta
	if _since_hit < config.drain_delay:
		return
	fill = maxf(fill - config.drain_rate * delta, 0.0)
	if fill <= 0.0 and multiplier > 1:
		_break_combo()
		return
	Events.combo_changed.emit(fill, multiplier)


func _on_hit_landed(_info: DamageInfo) -> void:
	if Game.world != World.Id.COMBAT:
		return
	_since_hit = 0.0
	_add_score(config.score_per_hit * multiplier)
	_add_fill(config.fill_per_hit)


func _on_enemy_killed(_enemy: Node2D, data: EnemyData, _info: DamageInfo) -> void:
	if Game.world != World.Id.COMBAT or data == null:
		return
	_add_score(data.score_value * multiplier)


func _on_player_damaged(_info: DamageInfo) -> void:
	if not config.damage_breaks_combo or (fill <= 0.0 and multiplier <= 1):
		return
	_break_combo()


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


func _break_combo() -> void:
	var was_raised: bool = multiplier > 1
	fill = 0.0
	multiplier = 1
	_since_hit = 0.0
	if was_raised:
		Events.combo_broken.emit()
	Events.combo_changed.emit(fill, multiplier)
