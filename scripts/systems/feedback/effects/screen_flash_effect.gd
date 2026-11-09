class_name ScreenFlashEffect
extends FeedbackEffect
## Flashes the whole screen.

## Flash color. Its alpha is the starting strength.
@export var color: Color = Color(1, 1, 1, 0.5)
## Fade-out time (s).
@export var duration: float = 0.1


func play(_context: FeedbackContext) -> void:
	Feedback.screen_flash(color, duration)
