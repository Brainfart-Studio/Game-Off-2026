class_name ShiftConfig
extends GameConfig
## World shift tunables. Units are seconds.

## World the game starts in.
@export var start_world: World.Id = World.Id.PEACEFUL
## Minimum time between shift presses (s), counted from the press.
@export var cooldown: float = 0.6
## Fade to cover duration (s).
@export var fade_out: float = 0.12
## Time the screen stays covered (s).
@export var hold: float = 0.04
## Fade back to clear duration (s).
@export var fade_in: float = 0.16
## Cover color.
@export var fade_color: Color = Color.BLACK
## Easing curve of the fades.
@export var transition_trans: Tween.TransitionType = Tween.TRANS_SINE


func validate() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if cooldown < 0.0:
		warnings.append("cooldown must not be negative")
	if fade_out < 0.0 or hold < 0.0 or fade_in < 0.0:
		warnings.append("fade times must not be negative")
	if cooldown < fade_out + hold + fade_in:
		warnings.append("cooldown is shorter than the shift transition")
	return warnings
