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

const LAND_ANIMATION: StringName = &"player_land"
const APEX_ANIMATION: StringName = &"player_apex"
const AIR_STATES: Array[StringName] = [&"Jump", &"Fall"]
const GROUND_STATES: Array[StringName] = [&"Idle", &"Run"]

@onready var _player: Player = owner as Player
# Children _ready before their parent, so the Player's own @onready refs are not set yet.
@onready var _machine: StateMachine = _player.get_node("StateMachine")
@onready var _sprite: AnimatedSprite2D = _player.get_node("Visual/Sprite")
@onready var _label: AssetLabel = _player.get_node("Visual/AssetLabel")

var _landing: bool = false
var _in_apex: bool = false
var _state_animation: StringName = &""


func _ready() -> void:
	_machine.state_changed.connect(_on_state_changed)
	_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(_delta: float) -> void:
	var current: State = _machine.current
	if current == null or _landing or not AIR_STATES.has(current.name):
		return
	var apex: bool = _player.is_apex()
	if apex == _in_apex:
		return
	_in_apex = apex
	_play(APEX_ANIMATION if apex else _state_animation)


func _on_state_changed(from: StringName, to: StringName) -> void:
	_in_apex = false
	_landing = false
	if STATE_ANIMATIONS.has(to):
		_state_animation = STATE_ANIMATIONS[to]
	if from == &"Fall" and GROUND_STATES.has(to):
		_landing = true
		_play(LAND_ANIMATION)
	elif STATE_ANIMATIONS.has(to):
		_play(_state_animation)


func _on_animation_finished() -> void:
	if _landing:
		_landing = false
		_play(_state_animation)


func _play(id: StringName) -> void:
	var frames: SpriteFrames = _sprite.sprite_frames
	if not frames.has_animation(id):
		push_warning("PlayerAnimator: no animation '%s'" % id)
		return
	_sprite.play(id)
	_label.show_if_fallback(frames.get_frame_texture(id, 0), String(id))
