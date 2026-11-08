class_name DebugOverlay
extends CanvasLayer
## Toggleable player debug readout. Hidden by default.

@onready var _label: Label = $Label

var _player: Player
var _shift: WorldShift


func _ready() -> void:
	visible = false
	Events.player_spawned.connect(_on_player_spawned)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(Actions.DEBUG_OVERLAY):
		visible = not visible


func _process(_delta: float) -> void:
	if _shift == null:
		_shift = get_tree().get_first_node_in_group(Groups.WORLD_SHIFT) as WorldShift
	if not visible:
		return
	var lines := PackedStringArray()
	if _player != null and is_instance_valid(_player):
		var state: String = String(_player.machine.current.name) if _player.machine.current != null else "-"
		lines.append("state: %s" % state)
		lines.append("velocity: (%.0f, %.0f)" % [_player.velocity.x, _player.velocity.y])
		lines.append("on floor: %s" % _player.is_on_floor())
		lines.append("coyote: %.2f" % _player.coyote_left)
		lines.append("buffer: %.2f" % _player.buffer_left)
	else:
		lines.append("no player")
	lines.append("world: %s" % World.Id.keys()[Game.world])
	if _shift != null:
		lines.append("shift cooldown: %.2f" % _shift.cooldown_left)
	lines.append("fps: %d" % Engine.get_frames_per_second())
	_label.text = "\n".join(lines)


func _on_player_spawned(player: Node2D) -> void:
	_player = player as Player
