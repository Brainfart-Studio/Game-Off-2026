class_name SoundDef
extends Resource
## One sound's playback settings. Sounds with no def use these defaults.

## Sound id, also the file name in the sfx folder.
@export var id: StringName = &""
## Resource path of the sound. Empty uses the convention path `<sfx_dir>/<id>.wav`.
@export var path: String = ""
## Volume (dB).
@export var volume_db: float = 0.0
## Lowest random pitch scale.
@export var pitch_min: float = 0.95
## Highest random pitch scale.
@export var pitch_max: float = 1.05
## Most copies of this sound that may play at once.
@export var max_voices: int = 4
## Minimum time between two starts of this sound (s).
@export var cooldown: float = 0.03
## Audio bus the sound plays on.
@export var bus: StringName = &"SFX"
