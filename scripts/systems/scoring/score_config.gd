class_name ScoreConfig
extends GameConfig
## Score and combo tunables. Times are in seconds.

@export_group("Score")
## Score for a landed hit, before the multiplier.
@export var score_per_hit: int = 10

@export_group("Combo")
## Combo bar fill added by a landed hit (the bar is 0 to 1).
@export var fill_per_hit: float = 0.25
## Highest multiplier.
@export var max_multiplier: int = 8
## Time without a hit before the bar starts to drain (s).
@export var drain_delay: float = 1.5
## Bar fill lost per second while draining.
@export var drain_rate: float = 0.5
## True: taking damage resets the combo.
@export var damage_breaks_combo: bool = true
## True: the bar also drains while the world is peaceful.
@export var drain_in_peaceful: bool = false


func validate() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if score_per_hit < 0:
		warnings.append("score_per_hit must not be negative")
	if fill_per_hit <= 0.0 or fill_per_hit > 1.0:
		warnings.append("fill_per_hit must be above 0 and at most 1")
	if max_multiplier < 1:
		warnings.append("max_multiplier must be at least 1")
	if drain_delay < 0.0:
		warnings.append("drain_delay must not be negative")
	if drain_rate <= 0.0:
		warnings.append("drain_rate must be positive")
	return warnings
