class_name EventRouter
extends RefCounted
## Static helpers that connect config-driven event keys to one handler (R-034).
## A key is an `Events` signal name, optionally followed by a variant after a dot,
## for example `world_shift_started.combat`.

## Events whose first argument is a world id. Their keys may carry a world variant.
const WORLD_EVENTS: Array[StringName] = [&"world_shift_started", &"world_shifted"]
## Most signal arguments a routed event can carry.
const MAX_ARGS: int = 3


## The text of `key` before the first `.`.
static func base_name(key: StringName) -> StringName:
	var text: String = String(key)
	var dot: int = text.find(".")
	if dot < 0:
		return key
	return StringName(text.substr(0, dot))


## Connects `handler` to the signal named by each distinct base name in `keys`.
## The handler is called as `handler(event: StringName, args: Array)`.
static func connect_keys(source: Object, keys: Array, handler: Callable) -> void:
	var counts: Dictionary[StringName, int] = {}
	for signal_info: Dictionary in source.get_signal_list():
		var args: Array = signal_info["args"]
		counts[signal_info["name"]] = args.size()
	var seen: Dictionary[StringName, bool] = {}
	for key: Variant in keys:
		var event: StringName = base_name(StringName(key))
		if seen.has(event):
			continue
		seen[event] = true
		if not counts.has(event):
			push_error("EventRouter: no signal '%s'" % event)
			continue
		var count: int = counts[event]
		if count > MAX_ARGS:
			push_error("EventRouter: signal '%s' has more than %d arguments" % [event, MAX_ARGS])
			continue
		source.connect(event, _callable_for(event, count, handler))


## Binding keys to try for an emitted event, most specific first.
## World events with a world id give `<event>.<world>` before `<event>`.
static func lookup_keys(event: StringName, args: Array) -> Array[StringName]:
	var keys: Array[StringName] = []
	if WORLD_EVENTS.has(event) and not args.is_empty() and args[0] is int:
		var world_key: Variant = World.Id.find_key(args[0])
		if world_key != null:
			keys.append(StringName("%s.%s" % [event, String(world_key).to_lower()]))
	keys.append(event)
	return keys


static func _callable_for(event: StringName, count: int, handler: Callable) -> Callable:
	match count:
		0:
			return func() -> void: handler.call(event, [])
		1:
			return func(a: Variant) -> void: handler.call(event, [a])
		2:
			return func(a: Variant, b: Variant) -> void: handler.call(event, [a, b])
		_:
			return func(a: Variant, b: Variant, c: Variant) -> void: handler.call(event, [a, b, c])
