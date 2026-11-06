class_name PlayerAnimator
extends Node
## Plays player animations by id in response to StateMachine.state_changed.

## State node name -> animation id. A new state adds one entry.
const STATE_ANIMATIONS: Dictionary[StringName, StringName] = {
	&"Idle": &"player_idle",
	&"Run": &"player_run",
	&"Jump": &"player_jump",
	&"Fall": &"player_fall",
}

@onready var _player: Player = owner as Player


func _ready() -> void:
	_player.machine.state_changed.connect(_on_state_changed)


func _on_state_changed(_from: StringName, to: StringName) -> void:
	if STATE_ANIMATIONS.has(to):
		_play(STATE_ANIMATIONS[to])


func _play(id: StringName) -> void:
	var frames: SpriteFrames = _player.sprite.sprite_frames
	if not frames.has_animation(id):
		push_warning("PlayerAnimator: no animation '%s'" % id)
		return
	_player.sprite.play(id)
	_player.asset_label.show_if_fallback(frames.get_frame_texture(id, 0), String(id))
