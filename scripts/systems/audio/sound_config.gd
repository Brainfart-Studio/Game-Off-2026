class_name SoundConfig
extends GameConfig
## Audio tunables: folders, per-sound defs, event bindings, and world music. Units are dB and seconds.

## Folder of sound effects. A file named `<id>.wav` here plays with no def.
@export var sfx_dir: String = "res://audio/sfx"
## Folder of world music. Files are named `music_<world>.ogg`.
@export var music_dir: String = "res://audio/music"
## Per-sound overrides. A sound with no entry uses `SoundDef` defaults.
@export var sounds: Array[SoundDef] = []
## Event key to sound id. A key is an `Events` signal name, optionally `.peaceful` or `.combat`.
@export var bindings: Dictionary[StringName, StringName] = {}
## Number of pooled sound players.
@export var voices: int = 16
## Music volume (dB).
@export var music_volume_db: float = -6.0
## Music crossfade time on a shift (s).
@export var crossfade: float = 0.8
## Start the incoming track at the outgoing track's position (for two same-length layers).
@export var sync_music_layers: bool = false

var _defaults: Dictionary[StringName, SoundDef] = {}


## The configured def for `id`, or a cached default def with that id.
func def_for(id: StringName) -> SoundDef:
	for def: SoundDef in sounds:
		if def != null and def.id == id:
			return def
	if not _defaults.has(id):
		var fallback: SoundDef = SoundDef.new()
		fallback.id = id
		_defaults[id] = fallback
	return _defaults[id]


## Resource path of the sound `id`: the def path, else `<sfx_dir>/<id>.wav`.
func path_for(id: StringName) -> String:
	var def: SoundDef = def_for(id)
	if not def.path.is_empty():
		return def.path
	return "%s/%s.wav" % [sfx_dir, id]


## Resource path of the music for `world`: `<music_dir>/music_<world>.ogg`.
func music_path(world: World.Id) -> String:
	return "%s/music_%s.ogg" % [music_dir, String(World.Id.find_key(world)).to_lower()]


func validate() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if voices < 1:
		warnings.append("voices must be at least 1")
	if crossfade < 0.0:
		warnings.append("crossfade must not be negative")
	for def: SoundDef in sounds:
		if def == null:
			warnings.append("sounds has an empty entry")
			continue
		if def.id == &"":
			warnings.append("a sound def has no id")
		if def.pitch_min > def.pitch_max:
			warnings.append("sound '%s' has pitch_min above pitch_max" % def.id)
		if def.max_voices < 1:
			warnings.append("sound '%s' needs max_voices of at least 1" % def.id)
		if def.cooldown < 0.0:
			warnings.append("sound '%s' has a negative cooldown" % def.id)
	for key: StringName in bindings:
		if bindings[key] == &"":
			warnings.append("binding '%s' has an empty sound id" % key)
	return warnings


## Resource path of the title screen music: `<music_dir>/music_title.ogg`.
func title_music_path() -> String:
	return "%s/music_title.ogg" % music_dir
