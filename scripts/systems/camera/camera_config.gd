class_name CameraConfig
extends GameConfig
## Camera tunables. Units are pixels and seconds.

## Position smoothing speed (higher is snappier).
@export var smoothing_speed: float = 8.0
## Look-ahead distance toward the facing direction (px).
@export var look_ahead_x: float = 24.0
## How fast the look-ahead offset eases toward its target (higher is snappier).
@export var look_ahead_speed: float = 4.0
## Horizontal drag margin (fraction of the view, 0 to 1).
@export_range(0.0, 1.0) var drag_margin_h: float = 0.1
## Vertical drag margin (fraction of the view, 0 to 1).
@export_range(0.0, 1.0) var drag_margin_v: float = 0.2


func validate() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if smoothing_speed <= 0.0:
		warnings.append("smoothing_speed must be above 0")
	if look_ahead_speed <= 0.0:
		warnings.append("look_ahead_speed must be above 0")
	if look_ahead_x < 0.0:
		warnings.append("look_ahead_x must not be negative")
	return warnings
