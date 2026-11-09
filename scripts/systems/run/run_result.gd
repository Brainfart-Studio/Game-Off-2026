class_name RunResult
extends RefCounted
## What a finished run reports. Built by `Run.build_result()` and carried by `run_ended`.

var score: int = 0
var kills: int = 0
var best_multiplier: int = 1
var time_survived: float = 0.0
var died: bool = false
