class_name Stats
extends Node
## Effective player stats: config value plus additive modifiers, times multiplicative ones.
## The player reads every tunable through `value()`.

@export var config: PlayerConfig

## source -> Array of { "stat": StringName, "add": float, "mult": float }
var _modifiers: Dictionary[StringName, Array] = {}


func value(stat: StringName) -> float:
	var total: float = config.get(stat)
	var mult: float = 1.0
	for entries: Array in _modifiers.values():
		for entry: Dictionary in entries:
			if entry["stat"] == stat:
				total += entry["add"]
				mult *= entry["mult"]
	return total * mult


func add_modifier(source: StringName, stat: StringName, add: float = 0.0, mult: float = 1.0) -> void:
	if not _modifiers.has(source):
		_modifiers[source] = []
	_modifiers[source].append({"stat": stat, "add": add, "mult": mult})
	Events.stats_changed.emit()


func remove_modifiers(source: StringName) -> void:
	if _modifiers.erase(source):
		Events.stats_changed.emit()
