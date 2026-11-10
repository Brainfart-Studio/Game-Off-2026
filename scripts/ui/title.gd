class_name Title
extends Control
## The title screen: Play, the high score table, and credits. Pages live in a `MenuStack`.

const GAME_TITLE := "GAME OFF 2026"
const PLAY := "PLAY"
const HIGH_SCORES := "HIGH SCORES"
const CREDITS := "CREDITS"
const BACK := "BACK"
const LOGO_PATH := "res://art/ui/ui_title_logo.png"
const LOGO_SIZE := Vector2i(192, 64)
const BACKGROUND_PATH := "res://art/backgrounds/bg_title.png"
const CREDIT_LINES: Array[String] = [
	"CODE AND MUSIC  BRAINFART",
	"ART  LOTEN",
	"SOUND  KELTFIRE",
	"",
	"MADE WITH GODOT ENGINE",
	"GODOTENGINE.ORG/LICENSE",
]

@export var config: UiConfig

var _logo_is_text: bool = false

@onready var _background: TextureRect = %Background
@onready var _logo: TextureRect = %Logo
@onready var _logo_text: Label = %LogoText
@onready var _menu: MenuStack = %Menu
@onready var _play: Button = %Play
@onready var _high_scores_button: Button = %HighScoresButton
@onready var _credits_button: Button = %CreditsButton
@onready var _high_score_list: HighScoreList = %HighScoreList
@onready var _credits_text: Label = %CreditsText
@onready var _scores_back: Button = %ScoresBack
@onready var _credits_back: Button = %CreditsBack
@onready var _scores_heading: Label = %ScoresHeading
@onready var _credits_heading: Label = %CreditsHeading


func _ready() -> void:
	config.check()
	theme = UiTheme.build(config)
	_background.texture = AssetLoader.texture(BACKGROUND_PATH, Display.view_size(), "bg_title")
	var logo: Texture2D = AssetLoader.texture(LOGO_PATH, LOGO_SIZE, "ui_title_logo")
	if AssetLoader.is_fallback(logo):
		_logo_is_text = true
		_logo_text.text = GAME_TITLE
	else:
		_logo.texture = logo
	_play.text = PLAY
	_high_scores_button.text = HIGH_SCORES
	_credits_button.text = CREDITS
	_scores_heading.text = HIGH_SCORES
	_credits_heading.text = CREDITS
	_scores_back.text = BACK
	_credits_back.text = BACK
	_high_score_list.config = config
	_credits_text.text = "\n".join(CREDIT_LINES)
	_play.pressed.connect(play)
	_high_scores_button.pressed.connect(_on_high_scores_pressed)
	_credits_button.pressed.connect(_menu.push_named.bind(&"Credits"))
	_scores_back.pressed.connect(_menu.back)
	_credits_back.pressed.connect(_menu.back)
	_menu.page_changed.connect(_on_page_changed)
	Events.title_opened.emit()
	_menu.open_root()


func play() -> void:
	Scenes.change(get_tree(), Scenes.RUN)


func _on_high_scores_pressed() -> void:
	_high_score_list.show_scores(Save.high_scores())
	_menu.push_named(&"HighScores")


func _on_page_changed(page: MenuPage) -> void:
	var on_root: bool = page == _menu.root_page
	_logo_text.visible = on_root and _logo_is_text
	_logo.visible = on_root and not _logo_is_text
