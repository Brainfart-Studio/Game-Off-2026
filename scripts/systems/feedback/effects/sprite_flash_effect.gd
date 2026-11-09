class_name SpriteFlashEffect
extends FeedbackEffect
## Flashes the sprite of the event's target. The target needs a `flash(color, duration)` method.

## Flash color.
@export var color: Color = Color.WHITE
## Flash time (s).
@export var duration: float = 0.08


func play(context: FeedbackContext) -> void:
	if context.target != null and is_instance_valid(context.target) and context.target.has_method(&"flash"):
		context.target.call(&"flash", color, duration)
