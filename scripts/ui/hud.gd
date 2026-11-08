class_name HUD
extends CanvasLayer
## The in-run HUD. Built once from events (health, timer, world), never polled.

const WORLD_NAMES := {World.Id.PEACEFUL: "PEACEFUL", World.Id.COMBAT: "COMBAT"}
const HEALTH_FULL_PATH := "res://art/ui/ui_health_full.png"
const HEALTH_EMPTY_PATH := "res://art/ui/ui_health_empty.png"
const PIP_SIZE := Vector2i(12, 12)
const SECONDS_PER_MINUTE := 60
const TIME_FORMAT := "%d:%02d"

@export var config: UiConfig

var _pip_full: Texture2D
var _pip_empty: Texture2D

@onready var _root: Control = %Root
@onready var _health: HBoxContainer = %Health
@onready var _timer: Label = %Timer
@onready var _world: Label = %World


## Formats `seconds` as `m:ss`, counting a started second as a whole one.
static func format_time(seconds: float) -> String:
	var total: int = maxi(ceili(seconds), 0)
	return TIME_FORMAT % [total / SECONDS_PER_MINUTE, total % SECONDS_PER_MINUTE]


func _ready() -> void:
	config.check()
	_root.theme = UiTheme.build(config)
	_pip_full = AssetLoader.texture(HEALTH_FULL_PATH, PIP_SIZE, "ui_health_full")
	_pip_empty = AssetLoader.texture(HEALTH_EMPTY_PATH, PIP_SIZE, "ui_health_empty")
	_timer.text = format_time(0.0)
	_on_world_shifted(Game.world)
	Events.player_health_changed.connect(_on_player_health_changed)
	Events.time_changed.connect(_on_time_changed)
	Events.world_shifted.connect(_on_world_shifted)


func _on_player_health_changed(current: int, max_health: int) -> void:
	while _health.get_child_count() > max_health:
		var extra: Node = _health.get_child(_health.get_child_count() - 1)
		_health.remove_child(extra)
		extra.queue_free()
	while _health.get_child_count() < max_health:
		_health.add_child(_new_pip())
	for i: int in _health.get_child_count():
		(_health.get_child(i) as TextureRect).texture = _pip_full if i < current else _pip_empty


func _on_time_changed(left: float) -> void:
	_timer.text = format_time(left)


func _on_world_shifted(to: World.Id) -> void:
	var world_name: String = WORLD_NAMES.get(to, "")
	_world.text = world_name


func _new_pip() -> TextureRect:
	var pip: TextureRect = TextureRect.new()
	pip.custom_minimum_size = Vector2(PIP_SIZE)
	pip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pip.stretch_mode = TextureRect.STRETCH_SCALE
	return pip
