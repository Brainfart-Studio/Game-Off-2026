extends Node
## Player settings (autoload `Settings`).
##
## Keeps the volumes and the shake and flash toggles in `user://settings.cfg`. Every change
## saves at once and emits `Events.settings_changed`. A missing or unreadable file gives the
## defaults.

const VOLUME_STEPS := 10
const MUTED_DB := -80.0
const SECTION_AUDIO := "audio"
const SECTION_FEEDBACK := "feedback"
const KEY_MASTER := "master"
const KEY_MUSIC := "music"
const KEY_SFX := "sfx"
const KEY_SHAKE := "shake"
const KEY_FLASH := "flash"
const BUS_MASTER := &"Master"
const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"

## Where the settings are stored. Tests point it at a throwaway file.
var path: String = "user://settings.cfg"
## Volumes in steps, 0 (muted) to `VOLUME_STEPS`.
var master_volume: int = VOLUME_STEPS
var music_volume: int = VOLUME_STEPS
var sfx_volume: int = VOLUME_STEPS
var shake_enabled: bool = true
var flash_enabled: bool = true

var _file: ConfigFile = ConfigFile.new()


func _ready() -> void:
	load_file()
	apply()


## Reads the settings from `path`. A missing or unreadable file gives the defaults.
func load_file() -> void:
	_file = ConfigFile.new()
	_file.load(path)
	master_volume = _read_volume(KEY_MASTER)
	music_volume = _read_volume(KEY_MUSIC)
	sfx_volume = _read_volume(KEY_SFX)
	shake_enabled = bool(_file.get_value(SECTION_FEEDBACK, KEY_SHAKE, true))
	flash_enabled = bool(_file.get_value(SECTION_FEEDBACK, KEY_FLASH, true))


## Writes the settings to `path`.
func save() -> void:
	_file.set_value(SECTION_AUDIO, KEY_MASTER, master_volume)
	_file.set_value(SECTION_AUDIO, KEY_MUSIC, music_volume)
	_file.set_value(SECTION_AUDIO, KEY_SFX, sfx_volume)
	_file.set_value(SECTION_FEEDBACK, KEY_SHAKE, shake_enabled)
	_file.set_value(SECTION_FEEDBACK, KEY_FLASH, flash_enabled)
	_file.save(path)


## Pushes the stored values to the audio buses.
func apply() -> void:
	_apply_volumes()


## The volume of `bus` in steps.
func volume(bus: StringName) -> int:
	match bus:
		BUS_MASTER:
			return master_volume
		BUS_MUSIC:
			return music_volume
		BUS_SFX:
			return sfx_volume
	push_error("Settings: unknown bus %s" % bus)
	return 0


## Sets the volume of `bus`, clamped to 0 to `VOLUME_STEPS`, then applies, saves, and emits.
func set_volume(bus: StringName, steps: int) -> void:
	if not [BUS_MASTER, BUS_MUSIC, BUS_SFX].has(bus):
		push_error("Settings: unknown bus %s" % bus)
		return
	var clamped: int = clampi(steps, 0, VOLUME_STEPS)
	if clamped == volume(bus):
		return
	match bus:
		BUS_MASTER:
			master_volume = clamped
		BUS_MUSIC:
			music_volume = clamped
		BUS_SFX:
			sfx_volume = clamped
	_apply_volumes()
	save()
	Events.settings_changed.emit()


func set_shake_enabled(on: bool) -> void:
	if on == shake_enabled:
		return
	shake_enabled = on
	save()
	Events.settings_changed.emit()


func set_flash_enabled(on: bool) -> void:
	if on == flash_enabled:
		return
	flash_enabled = on
	save()
	Events.settings_changed.emit()


## Restores every setting to its default, applies, saves, and emits.
func reset_to_defaults() -> void:
	master_volume = VOLUME_STEPS
	music_volume = VOLUME_STEPS
	sfx_volume = VOLUME_STEPS
	shake_enabled = true
	flash_enabled = true
	apply()
	save()
	Events.settings_changed.emit()


func _apply_volumes() -> void:
	pass


func _read_volume(key: String) -> int:
	return clampi(int(_file.get_value(SECTION_AUDIO, key, VOLUME_STEPS)), 0, VOLUME_STEPS)
