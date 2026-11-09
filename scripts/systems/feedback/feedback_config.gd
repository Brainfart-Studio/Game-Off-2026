class_name FeedbackConfig
extends GameConfig
## Feedback tunables: entries, event bindings, and camera shake. Units are px and seconds.

## Named effect lists.
@export var entries: Array[FeedbackEntry] = []
## Event key to entry id. A key is an `Events` signal name, optionally `.peaceful` or `.combat`.
@export var bindings: Dictionary[StringName, StringName] = {}
## Largest camera shake offset at full trauma (px).
@export var shake_max_offset: Vector2 = Vector2(6, 4)
## Trauma lost per second (1/s).
@export var shake_decay: float = 2.0
## Speed of the shake noise.
@export var shake_noise_speed: float = 40.0


## The entry with `id`, or null if there is none.
func entry(id: StringName) -> FeedbackEntry:
	for candidate: FeedbackEntry in entries:
		if candidate != null and candidate.id == id:
			return candidate
	return null


func validate() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	var seen: Dictionary[StringName, bool] = {}
	for candidate: FeedbackEntry in entries:
		if candidate == null:
			warnings.append("entries has an empty entry")
			continue
		if candidate.id == &"":
			warnings.append("a feedback entry has no id")
			continue
		if seen.has(candidate.id):
			warnings.append("duplicate feedback entry id '%s'" % candidate.id)
		seen[candidate.id] = true
	for key: StringName in bindings:
		if not seen.has(bindings[key]):
			warnings.append("binding '%s' names missing entry '%s'" % [key, bindings[key]])
	return warnings
