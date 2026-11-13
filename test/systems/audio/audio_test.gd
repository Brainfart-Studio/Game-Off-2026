extends GdUnitTestSuite

const SOUND: StringName = &"test_sound"

var _audio: Node
var _config: SoundConfig


func before_test() -> void:
	var source: SoundConfig = load("res://config/audio/sound_config.tres") as SoundConfig
	_config = source.duplicate() as SoundConfig
	# No bindings: the Audio autoload already reacts to the real events.
	_config.bindings = {}
	_audio = (load("res://scenes/audio/audio.tscn") as PackedScene).instantiate()
	_audio.config = _config
	add_child(_audio)


func after_test() -> void:
	_audio.queue_free()


func _start_voice(index: int, id: StringName) -> AudioStreamPlayer:
	var voice: AudioStreamPlayer = _audio._voices[index]
	voice.stream = AudioStreamGenerator.new()
	voice.play()
	_audio._voice_id[voice] = id
	return voice


func test_pool_is_built_from_config() -> void:
	assert_int(_audio._voices.size()).is_equal(_config.voices)


func test_cooldown_blocks_a_repeat() -> void:
	var def: SoundDef = _config.def_for(SOUND)
	def.cooldown = 0.5
	_audio._last_played[SOUND] = 1000
	assert_bool(_audio._can_play(def, 1100)).is_false()
	assert_bool(_audio._can_play(def, 1600)).is_true()


func test_max_voices_blocks_extra_copies() -> void:
	var def: SoundDef = _config.def_for(SOUND)
	def.cooldown = 0.0
	def.max_voices = 2
	assert_bool(_audio._can_play(def, 5000)).is_true()
	var first: AudioStreamPlayer = _start_voice(0, SOUND)
	_start_voice(1, SOUND)
	assert_bool(_audio._can_play(def, 5000)).is_false()
	first.stop()
	assert_bool(_audio._can_play(def, 5000)).is_true()


func test_other_sounds_do_not_count_toward_max_voices() -> void:
	var def: SoundDef = _config.def_for(SOUND)
	def.cooldown = 0.0
	def.max_voices = 1
	_start_voice(0, &"something_else")
	assert_bool(_audio._can_play(def, 5000)).is_true()


func test_missing_sound_plays_nothing_and_raises_no_error() -> void:
	await assert_error(func() -> void: _audio.play(&"no_such_sound")).is_success()
	for voice: AudioStreamPlayer in _audio._voices:
		assert_bool(voice.playing).is_false()
	assert_bool(_audio._last_played.has(&"no_such_sound")).is_false()


func test_title_opened_selects_the_title_music() -> void:
	Events.title_opened.emit()
	assert_str(_audio._music_path).is_equal(_config.title_music_path())
