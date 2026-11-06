class_name WorldShift
extends Node
## Handles the shift input: cooldown, fade, and the world swap events.

@export var config: ShiftConfig

## World currently shown.
var current: World.Id = World.Id.PEACEFUL
## Seconds of cooldown left (0 when ready).
var cooldown_left: float = 0.0

var _busy: bool = false

@onready var _transition: ShiftTransition = $ShiftTransition


func _ready() -> void:
	config.check()
	current = config.start_world
	_announce_start.call_deferred()


func _process(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(Actions.SHIFT):
		shift()


## Starts a shift to the other world, or emits `shift_denied`.
func shift() -> void:
	if _busy or cooldown_left > 0.0:
		Events.shift_denied.emit()
		return
	_busy = true
	cooldown_left = config.cooldown
	var to: World.Id = World.Id.COMBAT if current == World.Id.PEACEFUL else World.Id.PEACEFUL
	Events.world_shift_started.emit(to)
	await _transition.cover(config)
	current = to
	Events.world_shifted.emit(to)
	await _transition.reveal(config)
	_busy = false


func _announce_start() -> void:
	Events.world_shifted.emit(current)
