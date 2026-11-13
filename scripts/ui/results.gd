class_name Results
extends CanvasLayer
## The end-of-run screen: the run's numbers, initials entry for a new high score, the high score
## list, Restart and Title. Hidden until `run_ended`. Runs while the tree is paused (R-073).

const TIME_UP := "TIME UP"
const DEFEATED := "DEFEATED"
const NEW_HIGH_SCORE := "NEW HIGH SCORE"
const RESTART := "RESTART"
const TO_TITLE := "TITLE"
const SCORE_LINE := "SCORE  %d"
const KILLS_LINE := "KILLS  %d"
const MULTIPLIER_LINE := "BEST COMBO  x%d"
const TIME_LINE := "TIME  %d:%02d"
const HIGH_SCORE_SOUND := &"high_score"
const CONFIRM_SOUND := &"ui_confirm"
const SECONDS_PER_MINUTE := 60

@export var config: UiConfig

var _score: int = 0

@onready var _root: Control = %Root
@onready var _title: Label = %Title
@onready var _score_label: Label = %Score
@onready var _kills: Label = %Kills
@onready var _multiplier: Label = %Multiplier
@onready var _time: Label = %Time
@onready var _new_high_score: Label = %NewHighScore
@onready var _initials: InitialsEntry = %Initials
@onready var _high_scores: HighScoreList = %HighScores
@onready var _restart: Button = %Restart
@onready var _to_title: Button = %ToTitle


func _ready() -> void:
	config.check()
	_root.theme = UiTheme.build(config)
	_initials.config = config
	_high_scores.config = config
	_new_high_score.text = NEW_HIGH_SCORE
	_new_high_score.add_theme_color_override(&"font_color", config.highlight_color)
	_restart.text = RESTART
	_to_title.text = TO_TITLE
	_initials.confirmed.connect(_on_initials_confirmed)
	_restart.pressed.connect(_on_restart_pressed)
	_to_title.pressed.connect(_on_to_title_pressed)
	_reset_view()
	hide()
	Events.run_ended.connect(_on_run_ended)


func _reset_view() -> void:
	_new_high_score.hide()
	_initials.hide()
	_initials.active = false
	_high_scores.hide()
	_restart.hide()
	_to_title.hide()


func _on_run_ended(result: RunResult) -> void:
	_reset_view()
	_score = result.score
	_title.text = DEFEATED if result.died else TIME_UP
	_score_label.text = SCORE_LINE % result.score
	_kills.text = KILLS_LINE % result.kills
	_multiplier.text = MULTIPLIER_LINE % result.best_multiplier
	var seconds: int = int(result.time_survived)
	_time.text = TIME_LINE % [seconds / SECONDS_PER_MINUTE, seconds % SECONDS_PER_MINUTE]
	show()
	if Save.qualifies(result.score):
		_new_high_score.show()
		_initials.setup(Save.last_initials())
		_initials.show()
		_initials.active = true
	else:
		_show_list(-1)


func _on_initials_confirmed(initials: String) -> void:
	var rank: int = Save.add_high_score(initials, _score)
	Audio.play(HIGH_SCORE_SOUND)
	_initials.active = false
	_initials.hide()
	_show_list(rank)


func _on_restart_pressed() -> void:
	Audio.play(CONFIRM_SOUND)
	Events.run_restart_requested.emit()


func _on_to_title_pressed() -> void:
	Audio.play(CONFIRM_SOUND)
	Events.title_requested.emit()


## Shows the list and Restart, and puts focus on Restart.
func _show_list(highlight: int) -> void:
	_high_scores.show_scores(Save.high_scores(), highlight)
	_high_scores.show()
	_restart.show()
	_to_title.show()
	_restart.grab_focus()
