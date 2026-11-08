class_name SpawnConfig
extends GameConfig
## Spawner tunables. Units are seconds and pixels. The ramp follows run progress (0 to 1), so
## the interval shrinks and the cap grows over the run.

@export_group("Enemies")
## Enemy types the spawner picks from at random.
@export var enemies: Array[EnemyData] = []

@export_group("Timing")
## Delay after the run starts before the first spawn (s).
@export var first_delay: float = 2.0
## Time between spawns at the start of the run (s).
@export var start_interval: float = 3.0
## Time between spawns at the end of the run (s).
@export var end_interval: float = 0.8
## Enemies and telegraphs alive at once at the start of the run.
@export var start_max_alive: int = 3
## Enemies and telegraphs alive at once at the end of the run.
@export var end_max_alive: int = 12
## Shape of the ramp over run progress. Empty means linear.
@export var ramp: Curve

@export_group("Telegraph")
## Time the warning shows before the enemy appears (s).
@export var telegraph_time: float = 0.8
## Markers closer to the player than this are skipped (px).
@export var min_player_distance: float = 80.0
## Animation of the warning.
@export var telegraph_animation: AnimationDef


## Ramp value for run `progress`, 0 to 1.
func ramp_at(progress: float) -> float:
	var t: float = clampf(progress, 0.0, 1.0)
	if ramp == null:
		return t
	return clampf(ramp.sample(t), 0.0, 1.0)


## Seconds between spawns at run `progress`.
func interval_at(progress: float) -> float:
	return lerpf(start_interval, end_interval, ramp_at(progress))


## Enemies and telegraphs allowed at once at run `progress`.
func max_alive_at(progress: float) -> int:
	return roundi(lerpf(float(start_max_alive), float(end_max_alive), ramp_at(progress)))


func validate() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if enemies.is_empty():
		warnings.append("enemies must have at least one entry")
	for data: EnemyData in enemies:
		if data == null:
			warnings.append("enemies has an empty entry")
	if start_interval <= 0.0 or end_interval <= 0.0:
		warnings.append("intervals must be positive")
	if start_max_alive < 1 or end_max_alive < 1:
		warnings.append("max alive must be at least 1")
	if first_delay < 0.0 or telegraph_time < 0.0 or min_player_distance < 0.0:
		warnings.append("times and distances must not be negative")
	if telegraph_animation == null:
		warnings.append("telegraph_animation must be set")
	return warnings
