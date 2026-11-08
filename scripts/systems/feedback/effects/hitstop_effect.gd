class_name HitstopEffect
extends FeedbackEffect
## Briefly slows time.

## Real time the slowdown lasts (s).
@export var duration: float = 0.06
## Time scale during the slowdown.
@export var time_scale: float = 0.05


func play(_context: FeedbackContext) -> void:
	Feedback.hitstop(duration, time_scale)
