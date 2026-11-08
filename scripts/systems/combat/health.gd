class_name Health
extends Node
## Hit points with optional invulnerability after a hit. The owner calls `setup()` once its stats exist.

## A hit that lowered `current`. Emitted after `changed`.
signal damaged(info: DamageInfo)
signal healed(amount: int)
## `current` or `max_value` changed.
signal changed(current: int, max_value: int)
## `current` reached 0. Emitted once.
signal died(info: DamageInfo)

## Stats that hold the max health and the invulnerability time.
@export var stats: Stats
## Stat holding the max health.
@export var max_stat: StringName = &"max_health"
## Stat holding the invulnerability time after a hit (s). Empty means no invulnerability.
@export var iframes_stat: StringName = &""

var current: int = 0
var max_value: int = 1
## Seconds of invulnerability left.
var invulnerable_left: float = 0.0


func _ready() -> void:
	Events.stats_changed.connect(_on_stats_changed)


func _physics_process(delta: float) -> void:
	if invulnerable_left > 0.0:
		invulnerable_left = maxf(invulnerable_left - delta, 0.0)


## Reads the max health from the stats and fills health.
func setup() -> void:
	max_value = maxi(roundi(stats.value(max_stat)), 1)
	current = max_value
	invulnerable_left = 0.0
	changed.emit(current, max_value)


## Takes the hit. False when dead, invulnerable, or the amount is 0 or less.
func damage(info: DamageInfo) -> bool:
	if is_dead() or is_invulnerable() or info.amount <= 0:
		return false
	current = maxi(current - info.amount, 0)
	changed.emit(current, max_value)
	damaged.emit(info)
	if iframes_stat != &"":
		invulnerable_left = stats.value(iframes_stat)
	if current == 0:
		died.emit(info)
	return true


## Adds health up to the max. Does nothing when dead.
func heal(amount: int) -> void:
	if is_dead() or amount <= 0:
		return
	var gained: int = mini(amount, max_value - current)
	if gained <= 0:
		return
	current += gained
	healed.emit(gained)
	changed.emit(current, max_value)


func is_dead() -> bool:
	return current <= 0


func is_invulnerable() -> bool:
	return invulnerable_left > 0.0


func _on_stats_changed(changed_owner: Node) -> void:
	if changed_owner != get_parent() or stats == null:
		return
	var previous: int = max_value
	max_value = maxi(roundi(stats.value(max_stat)), 1)
	if max_value == previous:
		return
	if not is_dead():
		current = clampi(current + maxi(max_value - previous, 0), 1, max_value)
	changed.emit(current, max_value)
