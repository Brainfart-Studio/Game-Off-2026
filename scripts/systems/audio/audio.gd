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

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
## Music player holding the current track, or null when no track plays.
var _music_current: AudioStreamPlayer
## Path of the track the last shift asked for, even if the file is missing.
var _music_path: String = ""
## Music player -> its running volume tween.
var _fades: Dictionary[AudioStreamPlayer, Tween] = {}


func _ready() -> void:
	config.check()
	for i: int in maxi(config.voices, 1):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.name = "Voice%d" % i
		add_child(voice)
		_voices.append(voice)
	_music_a = _make_music_player(&"MusicA")
	_music_b = _make_music_player(&"MusicB")
	EventRouter.connect_keys(Events, config.bindings.keys(), _on_event)
	Events.world_shifted.connect(_on_world_shifted)


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
	if not args.is_empty() and args[0] is DamageInfo:
		var info: DamageInfo = args[0] as DamageInfo
		if info.sound != &"":
			play(info.sound)
			return
	for key: StringName in EventRouter.lookup_keys(event, args):
		if config.bindings.has(key):
			play(config.bindings[key])
			return


func _make_music_player(player_name: StringName) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = player_name
	player.bus = &"Music"
	add_child(player)
	return player


## Crossfades to the music of the world just shown. A missing file fades the music out.
func _on_world_shifted(to: World.Id) -> void:
	var path: String = config.music_path(to)
	if path == _music_path:
		return
	_music_path = path
	var outgoing: AudioStreamPlayer = _music_current
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	if stream == null:
		_fade_out(outgoing)
		_music_current = null
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	var incoming: AudioStreamPlayer = _music_a if outgoing != _music_a else _music_b
	_kill_fade(incoming)
	incoming.stream = stream
	incoming.volume_db = -80.0
	var start: float = 0.0
	if config.sync_music_layers and outgoing != null and outgoing.playing:
		start = outgoing.get_playback_position()
	incoming.play(start)
	_start_fade(incoming, config.music_volume_db, false)
	_fade_out(outgoing)
	_music_current = incoming


func _fade_out(player: AudioStreamPlayer) -> void:
	if player != null:
		_start_fade(player, -80.0, true)


func _start_fade(player: AudioStreamPlayer, to_db: float, stop_after: bool) -> void:
	_kill_fade(player)
	var tween: Tween = create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(player, "volume_db", to_db, config.crossfade)
	if stop_after:
		tween.tween_callback(player.stop)
	_fades[player] = tween


func _kill_fade(player: AudioStreamPlayer) -> void:
	var tween: Tween = _fades.get(player)
	if tween != null and tween.is_valid():
		tween.kill()
	_fades.erase(player)
