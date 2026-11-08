class_name FeedbackEntry
extends Resource
## A named list of effects that play together.

## Id that bindings refer to.
@export var id: StringName
## Effects played, in order, when the entry plays.
@export var effects: Array[FeedbackEffect] = []
