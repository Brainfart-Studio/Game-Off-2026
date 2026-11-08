class_name HapticsEffect
extends FeedbackEffect
## Rumbles connected gamepads.

## Weak motor strength (0 to 1).
@export var weak: float = 0.3
## Strong motor strength (0 to 1).
@export var strong: float = 0.0
## Rumble time (s).
@export var duration: float = 0.1


func play(_context: FeedbackContext) -> void:
	Feedback.vibrate(weak, strong, duration)
