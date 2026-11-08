# Tuning

All tunable values live in config resources. No tuning value is hard-coded in a script.

## Where configs live

| Config | File | Controls |
|---|---|---|
| Player | `config/player/player_config.tres` | Movement, jump, gravity, body size, animations |
| Camera | `config/camera/camera_config.tres` | Follow smoothing, look-ahead, drag margins |
| Shift | `config/shift/shift_config.tres` | World shift cooldown and screen fade |
| Sound | `config/audio/sound_config.tres` | Sound files, per-sound settings, event bindings, world music |

## Main values

Units are pixels and seconds.

**Player**

| Value | Effect |
|---|---|
| `run_speed` | Top horizontal speed |
| `ground_accel`, `ground_decel` | How fast the player speeds up and stops on the ground |
| `air_accel`, `air_decel` | Same, in the air |
| `analog_run` | Off: a stick past the deadzone runs at full speed. On: speed follows the stick |
| `jump_height` | Height of a full jump |
| `time_to_apex` | Time to reach the top. Shorter feels snappier. Gravity and launch speed come from height and time |
| `jump_cut_multiplier` | Upward speed kept when jump is released early. Lower gives shorter hops |
| `jump_buffer_time` | How long an early jump press is remembered |
| `coyote_time` | How long jumping still works after leaving a ledge |
| `fall_gravity_multiplier` | Extra gravity while falling |
| `max_fall_speed` | Terminal fall speed |
| `apex_threshold`, `apex_gravity_multiplier`, `apex_speed_multiplier` | The floaty band at the top of a jump |
| `body_size` | Collision box size |
| `step_interval` | Time between footstep sounds while running |

**Camera**

| Value | Effect |
|---|---|
| `smoothing_speed` | Follow speed. Higher is snappier |
| `look_ahead_x` | Distance the view leads toward the facing direction |
| `look_ahead_speed` | How fast the look-ahead eases in |
| `drag_margin_h`, `drag_margin_v` | Dead area before the camera moves, as a fraction of the view |

**Shift**

| Value | Effect |
|---|---|
| `start_world` | World the game starts in |
| `cooldown` | Minimum time between shifts. Must not be shorter than the fades |
| `fade_out`, `hold`, `fade_in` | Fade to cover, time covered, fade back |
| `fade_color` | Color of the cover |
| `transition_trans` | Easing curve of the fades |

**Sound**

Drop a file at `audio/sfx/<id>.wav` and it plays when its id is bound to an event. No other setup is needed. A missing file stays silent.

- Variations: add `<id>_2.wav`, `<id>_3.wav`, and so on beside it. One is picked at random each time.
- Per-sound settings are a `SoundDef` in `sounds`. A sound with no def uses the defaults.
- Bindings map an event key to a sound id. The key is an event name from [events.md](events.md). World events also take `.peaceful` or `.combat`, for example `world_shift_started.combat`. The variant wins over the plain name.

| Value | Effect |
|---|---|
| `sfx_dir`, `music_dir` | Folders searched for sounds and music |
| `voices` | Sounds that can play at once across the whole game |
| `music_volume_db` | Music volume |
| `crossfade` | Seconds to fade between world music tracks |
| `sync_music_layers` | On: the new track starts at the old track's position. Use for two layers of the same length |
| `SoundDef.id` | Sound id, also the file name |
| `SoundDef.path` | Overrides the file path. Empty uses `<sfx_dir>/<id>.wav` |
| `SoundDef.volume_db` | Volume of this sound |
| `SoundDef.pitch_min`, `pitch_max` | Random pitch range per play |
| `SoundDef.max_voices` | Copies of this sound that can play at once |
| `SoundDef.cooldown` | Minimum seconds between two starts of this sound |
| `SoundDef.bus` | `SFX` (default), `UI`, or `Music` |

Music files are `audio/music/music_peaceful.ogg` and `audio/music/music_combat.ogg`. Each loops. On a shift the new world's track fades in and the old one fades out over `crossfade`. A missing music file fades the current track out.

## Editing in the inspector

1. Open the `.tres` file in the Godot editor (double-click it in the FileSystem dock).
2. Change values in the Inspector. Each value has a tooltip with its meaning.
3. Save and run the game.

## Live tuning

While the game runs from the editor:

1. Open the **Remote** tab in the Scene dock.
2. Select the node (for example `Player`, `GameCamera`, or `WorldShift`).
3. Edit its `config` in the Inspector. Changes apply at once.

Live edits are lost when the game stops. Copy the values you like into the `.tres` file and save.

## Debug overlay

Press **F1** (or the **Back** button on a gamepad) to show or hide the debug overlay. It shows player state, velocity, floor contact, coyote and buffer timers, the current world, the shift cooldown, and FPS.
