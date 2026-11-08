extends Node
## Audio service (autoload `Audio`).
##
## Plays sounds from a pool of players. Sounds are found by naming convention (see `SoundConfig`),
## bound to `Events` signals by key, and a missing file plays nothing and raises no error (R-026).

@export var config: SoundConfig

var _voices: Array[AudioStreamPlayer] = []
## Voice -> id of the sound it last started.
var _voice_id: Dictionary[AudioStreamPlayer, StringName] = {}
## Voice -> tick (ms) at which it last started.
var _voice_start: Dictionary[AudioStreamPlayer, int] = {}
## Sound id -> tick (ms) at which it last started.
var _last_played: Dictionary[StringName, int] = {}


func _ready() -> void:
	config.check()
	for i: int in maxi(config.voices, 1):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.name = "Voice%d" % i
		add_child(voice)
		_voices.append(voice)
	EventRouter.connect_keys(Events, config.bindings.keys(), _on_event)


## Plays the sound `id`, unless it is cooling down or has too many copies playing.
func play(id: StringName) -> void:
	var def: SoundDef = config.def_for(id)
	var now: int = Time.get_ticks_msec()
	if not _can_play(def, now):
		return
	var stream: AudioStream = AssetLoader.sound(config.path_for(id))
	if stream == null:
		return
	var voice: AudioStreamPlayer = _pick_voice()
	voice.stream = stream
	voice.bus = def.bus
	voice.volume_db = def.volume_db
	voice.pitch_scale = randf_range(def.pitch_min, def.pitch_max)
	voice.play()
	_voice_id[voice] = id
	_voice_start[voice] = now
	_last_played[id] = now


func _can_play(def: SoundDef, now_ms: int) -> bool:
	if _last_played.has(def.id) and now_ms - _last_played[def.id] < int(def.cooldown * 1000.0):
		return false
	var active: int = 0
	for voice: AudioStreamPlayer in _voices:
		if voice.playing and _voice_id.get(voice) == def.id:
			active += 1
	return active < def.max_voices


## A voice that is not playing, else the one that started longest ago.
func _pick_voice() -> AudioStreamPlayer:
	var oldest: AudioStreamPlayer = _voices[0]
	for voice: AudioStreamPlayer in _voices:
		if not voice.playing:
			return voice
		if _voice_start.get(voice, 0) < _voice_start.get(oldest, 0):
			oldest = voice
	return oldest


func _on_event(event: StringName, args: Array) -> void:
	for key: StringName in EventRouter.lookup_keys(event, args):
		if config.bindings.has(key):
			play(config.bindings[key])
			return
