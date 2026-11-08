class_name ShakeEffect
extends FeedbackEffect
## Adds camera shake trauma.

## Trauma added (0 to 1).
@export var trauma: float = 0.3


func play(_context: FeedbackContext) -> void:
	Feedback.add_trauma(trauma)
