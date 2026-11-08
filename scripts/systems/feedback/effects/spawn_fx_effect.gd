class_name SpawnFxEffect
extends FeedbackEffect
## Plays a one-shot effect sprite at the event's position. Does nothing without a position.

## Animation to play.
@export var animation: AnimationDef
## Offset from the event's position (px).
@export var offset: Vector2 = Vector2.ZERO


func play(context: FeedbackContext) -> void:
	if context.has_position:
		Feedback.spawn_fx(animation, context.position + offset)
