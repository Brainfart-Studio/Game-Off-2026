class_name FeedbackContext
extends RefCounted
## What a feedback effect needs to know about the event that triggered it.

## The event that triggered the effect.
var event: StringName = &""
## The first `Node2D` argument of the event, or null.
var target: Node2D = null
## World position of the event: the target's, else the first `Vector2` argument.
var position: Vector2 = Vector2.ZERO
## True when `position` holds a real position.
var has_position: bool = false


## Builds a context from an event's arguments. The first `Node2D` gives `target` and `position`;
## without one, the first `Vector2` gives `position`.
static func from_args(event: StringName, args: Array) -> FeedbackContext:
	var context: FeedbackContext = FeedbackContext.new()
	context.event = event
	for arg: Variant in args:
		if arg is Node2D and is_instance_valid(arg):
			context.target = arg as Node2D
			context.position = context.target.global_position
			context.has_position = true
			return context
	for arg: Variant in args:
		if arg is Vector2:
			context.position = arg
			context.has_position = true
			return context
	return context
