extends GdUnitTestSuite

const SETTINGS_SCRIPT: String = "res://scripts/core/settings.gd"
const TEST_PATH: String = "user://settings_test.cfg"

var _changes: int = 0


func before_test() -> void:
	_remove_file()
	_changes = 0
	Events.settings_changed.connect(_count_change)


func after_test() -> void:
	Events.settings_changed.disconnect(_count_change)
	_remove_file()
	Settings.apply()


func _count_change() -> void:
	_changes += 1


func _make_settings() -> Node:
	var settings: Node = auto_free((load(SETTINGS_SCRIPT) as GDScript).new()) as Node
	settings.path = TEST_PATH
	settings.load_file()
	return settings


func _remove_file() -> void:
	var absolute: String = ProjectSettings.globalize_path(TEST_PATH)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)


func test_missing_file_gives_defaults() -> void:
	var settings: Node = _make_settings()
	assert_int(settings.master_volume).is_equal(10)
	assert_int(settings.music_volume).is_equal(10)
	assert_int(settings.sfx_volume).is_equal(10)
	assert_bool(settings.shake_enabled).is_true()
	assert_bool(settings.flash_enabled).is_true()


func test_volume_saves_and_loads() -> void:
	var settings: Node = _make_settings()
	settings.set_volume(&"Music", 4)
	var reloaded: Node = _make_settings()
	assert_int(reloaded.volume(&"Music")).is_equal(4)
	assert_int(reloaded.volume(&"Master")).is_equal(10)


func test_volume_clamps() -> void:
	var settings: Node = _make_settings()
	settings.set_volume(&"SFX", -3)
	assert_int(settings.volume(&"SFX")).is_equal(0)
	settings.set_volume(&"SFX", 14)
	assert_int(settings.volume(&"SFX")).is_equal(10)


func test_unknown_bus_is_an_error_and_changes_nothing() -> void:
	var settings: Node = _make_settings()
	await assert_error(func() -> void: settings.set_volume(&"Nope", 3)) \
		.is_push_error("Settings: unknown bus Nope")
	assert_int(settings.master_volume).is_equal(10)
	assert_int(settings.music_volume).is_equal(10)
	assert_int(settings.sfx_volume).is_equal(10)
	assert_int(_changes).is_equal(0)


func test_toggles_save_and_load() -> void:
	var settings: Node = _make_settings()
	settings.set_shake_enabled(false)
	settings.set_flash_enabled(false)
	var reloaded: Node = _make_settings()
	assert_bool(reloaded.shake_enabled).is_false()
	assert_bool(reloaded.flash_enabled).is_false()


func test_changed_signal_fires_once_per_real_change() -> void:
	var settings: Node = _make_settings()
	settings.set_volume(&"Master", 7)
	assert_int(_changes).is_equal(1)
	settings.set_volume(&"Master", 7)
	assert_int(_changes).is_equal(1)
	settings.set_shake_enabled(false)
	assert_int(_changes).is_equal(2)
	settings.set_shake_enabled(false)
	assert_int(_changes).is_equal(2)
	settings.set_flash_enabled(false)
	assert_int(_changes).is_equal(3)
	settings.set_flash_enabled(false)
	assert_int(_changes).is_equal(3)


func test_reset_to_defaults_restores_and_saves() -> void:
	var settings: Node = _make_settings()
	settings.set_volume(&"Master", 2)
	settings.set_shake_enabled(false)
	settings.reset_to_defaults()
	assert_int(settings.master_volume).is_equal(10)
	assert_bool(settings.shake_enabled).is_true()
	var reloaded: Node = _make_settings()
	assert_int(reloaded.master_volume).is_equal(10)
	assert_bool(reloaded.shake_enabled).is_true()


func test_volume_db() -> void:
	var settings_class: GDScript = load(SETTINGS_SCRIPT) as GDScript
	assert_float(settings_class.volume_db(10)).is_equal_approx(0.0, 0.001)
	assert_float(settings_class.volume_db(5)).is_equal_approx(-6.02, 0.01)
	assert_float(settings_class.volume_db(0)).is_equal(-80.0)


func test_volumes_apply_to_the_buses() -> void:
	var settings: Node = _make_settings()
	settings.set_volume(&"SFX", 0)
	settings.set_volume(&"Music", 5)
	var sfx: int = AudioServer.get_bus_index(&"SFX")
	var music: int = AudioServer.get_bus_index(&"Music")
	assert_bool(AudioServer.is_bus_mute(sfx)).is_true()
	assert_bool(AudioServer.is_bus_mute(music)).is_false()
	assert_float(AudioServer.get_bus_volume_db(music)).is_equal_approx(-6.02, 0.01)
