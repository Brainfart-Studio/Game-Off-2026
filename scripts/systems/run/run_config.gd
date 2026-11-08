class_name RunConfig
extends GameConfig
## Run tunables. Units are seconds unless noted.

## Length of a run (s).
@export var duration: float = 600.0
## Pause before the run starts counting down (s).
@export var start_delay: float = 1.0
## Pause between the player dying and the run ending (s).
@export var death_delay: float = 1.2
## The timer warning fires once per second from this many seconds left down to 1.
@export var warning_time: int = 10


func validate() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if duration <= 0.0:
		warnings.append("duration must be positive")
	if start_delay < 0.0 or death_delay < 0.0:
		warnings.append("delays must not be negative")
	if warning_time < 0:
		warnings.append("warning_time must not be negative")
	return warnings
