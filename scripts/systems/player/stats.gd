class_name Stats
extends Node
## Effective player stats: config value plus additive modifiers, times multiplicative ones.
## Works over any GameConfig; numeric properties only.

@export var config: GameConfig

## source -> Array of { "stat": StringName, "add": float, "mult": float }
var _modifiers: Dictionary[StringName, Array] = {}


func value(stat: StringName) -> float:
	var base: Variant = config.get(stat)
	if typeof(base) != TYPE_FLOAT and typeof(base) != TYPE_INT:
		push_error("Stats: '%s' is not a number on %s" % [stat, config.resource_path])
		return 0.0
	var total: float = base
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
