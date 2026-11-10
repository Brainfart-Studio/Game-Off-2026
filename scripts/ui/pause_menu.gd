class_name PauseMenu
extends CanvasLayer
## The pause menu: resume, options, controls, restart, and quit to title. Hidden until the run is
## paused. Runs while the tree is paused (R-073). It only requests pausing; `Run` owns the state.

const HEADING := "PAUSED"
const RESUME := "RESUME"
const OPTIONS := "OPTIONS"
const RESTART := "RESTART"
const QUIT := "QUIT TO TITLE"
const PAUSE_SOUND := &"ui_pause"
const OPTIONS_PAGE := &"Options"

@export var config: UiConfig

@onready var _root: Control = %Root
@onready var _menu: MenuStack = %Menu
@onready var _heading: Label = %Heading
@onready var _resume: Button = %Resume
@onready var _options_button: Button = %OptionsButton
@onready var _restart: Button = %Restart
@onready var _quit: Button = %Quit


func _ready() -> void:
	config.check()
	_root.theme = UiTheme.build(config)
	_heading.text = HEADING
	_resume.text = RESUME
	_options_button.text = OPTIONS
	_restart.text = RESTART
	_quit.text = QUIT
	hide()
	_resume.pressed.connect(_request.bind(false))
	_options_button.pressed.connect(_menu.push_named.bind(OPTIONS_PAGE))
	_restart.pressed.connect(Events.run_restart_requested.emit)
	_quit.pressed.connect(Events.title_requested.emit)
	_menu.emptied.connect(_request.bind(false))
	Events.run_paused.connect(_on_run_paused)


## True when the run can be paused now: it is not paused and is starting or running.
func can_pause() -> bool:
	return not Game.paused and (Game.phase == Game.Phase.STARTING or Game.phase == Game.Phase.RUNNING)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(Actions.PAUSE):
		return
	if visible:
		_request(false)
	elif can_pause():
		_request(true)
	else:
		return
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not visible and can_pause():
		_request(true)


func _request(paused: bool) -> void:
	Events.run_pause_requested.emit(paused)


func _on_run_paused(paused: bool) -> void:
	if paused:
		show()
		Audio.play(PAUSE_SOUND)
		_menu.open_root()
	else:
		_menu.close_all()
		hide()
