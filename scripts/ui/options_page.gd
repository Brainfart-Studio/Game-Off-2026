class_name OptionsPage
extends MenuPage
## Volumes, screen shake, screen flash, and reset. Every change is saved by `Settings` at once.

const HEADING := "OPTIONS"
const MASTER := "MASTER"
const MUSIC := "MUSIC"
const SFX := "SFX"
const SHAKE := "SCREEN SHAKE"
const FLASH := "SCREEN FLASH"
const CONTROLS := "CONTROLS"
const RESET := "RESET TO DEFAULTS"
const BACK := "BACK"
const CONTROLS_PAGE := &"Controls"

@onready var _heading: Label = %Heading
@onready var _master: OptionStepper = %Master
@onready var _music: OptionStepper = %Music
@onready var _sfx: OptionStepper = %Sfx
@onready var _shake: OptionToggle = %Shake
@onready var _flash: OptionToggle = %Flash
@onready var _controls: Button = %Controls
@onready var _reset: Button = %Reset
@onready var _back: Button = %Back


func _ready() -> void:
	_heading.text = HEADING
	_master.label_text = MASTER
	_music.label_text = MUSIC
	_sfx.label_text = SFX
	_shake.label_text = SHAKE
	_flash.label_text = FLASH
	_controls.text = CONTROLS
	_reset.text = RESET
	_back.text = BACK
	for stepper: OptionStepper in [_master, _music, _sfx]:
		stepper.max_value = Settings.VOLUME_STEPS
	_master.value_changed.connect(_set_volume.bind(Settings.BUS_MASTER))
	_music.value_changed.connect(_set_volume.bind(Settings.BUS_MUSIC))
	_sfx.value_changed.connect(_set_volume.bind(Settings.BUS_SFX))
	_shake.toggled.connect(Settings.set_shake_enabled)
	_flash.toggled.connect(Settings.set_flash_enabled)
	_controls.pressed.connect(push_requested.emit.bind(CONTROLS_PAGE))
	_reset.pressed.connect(_on_reset_pressed)
	_back.pressed.connect(back_requested.emit)
	super._ready()


func opened() -> void:
	_master.value = Settings.master_volume
	_music.value = Settings.music_volume
	_sfx.value = Settings.sfx_volume
	_shake.set_on(Settings.shake_enabled)
	_flash.set_on(Settings.flash_enabled)


func _set_volume(steps: int, bus: StringName) -> void:
	Settings.set_volume(bus, steps)


func _on_reset_pressed() -> void:
	Settings.reset_to_defaults()
	opened()
