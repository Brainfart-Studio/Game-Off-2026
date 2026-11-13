extends GdUnitTestSuite

var _config: SoundConfig


func before_test() -> void:
	_config = auto_free(SoundConfig.new())


func _def(id: StringName) -> SoundDef:
	var def: SoundDef = SoundDef.new()
	def.id = id
	return def


func test_convention_path() -> void:
	assert_str(_config.path_for(&"player_jump")).is_equal("res://audio/sfx/player_jump.wav")


func test_sfx_dir_changes_convention_path() -> void:
	_config.sfx_dir = "res://other"
	assert_str(_config.path_for(&"hit")).is_equal("res://other/hit.wav")


func test_def_path_overrides_convention() -> void:
	var def: SoundDef = _def(&"boom")
	def.path = "res://audio/sfx/special/boom.ogg"
	_config.sounds = [def]
	assert_str(_config.path_for(&"boom")).is_equal("res://audio/sfx/special/boom.ogg")
	assert_str(_config.path_for(&"other")).is_equal("res://audio/sfx/other.wav")


func test_music_paths_for_both_worlds() -> void:
	assert_str(_config.music_path(World.Id.PEACEFUL)).is_equal("res://audio/music/music_peaceful.ogg")
	assert_str(_config.music_path(World.Id.COMBAT)).is_equal("res://audio/music/music_combat.ogg")


func test_title_music_path() -> void:
	assert_str(_config.title_music_path()).is_equal("res://audio/music/music_title.ogg")


func test_unknown_id_gets_a_cached_default_def() -> void:
	var def: SoundDef = _config.def_for(&"unknown")
	assert_str(String(def.id)).is_equal("unknown")
	assert_float(def.volume_db).is_equal(0.0)
	assert_int(def.max_voices).is_equal(4)
	assert_str(String(def.bus)).is_equal("SFX")
	assert_object(_config.def_for(&"unknown")).is_same(def)


func test_configured_def_is_returned() -> void:
	var def: SoundDef = _def(&"boom")
	def.volume_db = -3.0
	_config.sounds = [def]
	assert_object(_config.def_for(&"boom")).is_same(def)


func test_default_config_is_valid() -> void:
	assert_int(_config.validate().size()).is_equal(0)


func test_validate_warns_on_bad_values() -> void:
	_config.voices = 0
	_config.crossfade = -1.0
	var no_id: SoundDef = SoundDef.new()
	var bad: SoundDef = _def(&"bad")
	bad.pitch_min = 1.5
	bad.pitch_max = 1.0
	bad.max_voices = 0
	bad.cooldown = -0.1
	_config.sounds = [no_id, bad]
	_config.bindings = {&"player_jumped": &""}
	var text: String = "\n".join(_config.validate())
	assert_str(text).contains("voices must be at least 1")
	assert_str(text).contains("crossfade must not be negative")
	assert_str(text).contains("a sound def has no id")
	assert_str(text).contains("sound 'bad' has pitch_min above pitch_max")
	assert_str(text).contains("sound 'bad' needs max_voices of at least 1")
	assert_str(text).contains("sound 'bad' has a negative cooldown")
	assert_str(text).contains("binding 'player_jumped' has an empty sound id")
