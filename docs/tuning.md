# Tuning

All tunable values live in config resources. No tuning value is hard-coded in a script.

## Where configs live

| Config | File | Controls |
|---|---|---|
| Player | `config/player/player_config.tres` | Movement, jump, gravity, body size, combat, animations |
| Moveset | `config/player/moveset.tres` | The player's four attacks and their timing, hitbox, and knockback |
| Walker | `config/enemies/walker.tres` | The walker's health, speeds, senses, contact hit, rewards, body size, animations |
| Spawner | `config/enemies/spawn_config.tres` | Which enemies spawn, how often, how many at once, and the warning before each |
| Economy | `config/economy/economy_config.tres` | Starting currency, how drops split and pop, how pickups wait, fly, blink, and expire |
| Score | `config/scoring/score_config.tres` | Score per hit, combo fill and cap, drain, and what breaks the combo |
| Camera | `config/camera/camera_config.tres` | Follow smoothing, look-ahead, drag margins |
| Shift | `config/shift/shift_config.tres` | World shift cooldown and screen fade |
| Sound | `config/audio/sound_config.tres` | Sound files, per-sound settings, event bindings, world music |
| Feedback | `config/feedback/feedback_config.tres` | Screen shake, hitstop, flashes, haptics, and the events that trigger them |
| UI | `config/ui/ui_config.tres` | Font, text colors, and the panel used by the results screen and later menus |

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

**Player combat**

| Value | Effect |
|---|---|
| `max_health` | Health at the start of a run |
| `hurt_iframes` | Seconds the player cannot be hit after a hit |
| `hurt_stun` | Seconds the player cannot act after a hit |
| `hurt_knockback_multiplier` | Scales the knockback taken |
| `iframe_blink_rate` | Blinks per second while invulnerable. The sprite dims to 35% and back |
| `attack_buffer_time` | How long an early attack press is remembered |
| `attack_speed` | Above 1 shortens every attack. Divides startup, active, and recovery |
| `attack_reach` | Scales every attack's hitbox size and offset |
| `attack_damage` | Scales every attack's damage, rounded, at least 1 |
| `moveset` | The `Moveset` resource the player attacks with |

Upgrades change `attack_speed`, `attack_reach`, `attack_damage`, `max_health`, and the other values through `Stats`, never by editing the config.

**Player economy**

| Value | Effect |
|---|---|
| `magnet_radius` | Radius within which the player pulls in currency pickups (px). Upgrades change it through `Stats` |

**Player moveset**

`moveset.tres` has a slot for each stance and direction. Today it fills `ground_side`, `ground_up`, `ground_neutral`, and `air_down`. Every other slot falls back as described under Attacks below: an empty air slot uses the ground slot of the same direction, and an empty ground slot uses `ground_neutral`. The held direction picks the slot: up or down when the stick points that way at least as much as sideways, side when pushed left or right, neutral when nothing is held. Down on the ground has no slot, so it uses `ground_neutral`.

| Attack | Slot | Notes |
|---|---|---|
| `side` | `ground_side` | Also used in the air. Low `move_control`, so the player keeps most of their run speed |
| `up` | `ground_up` | Also used in the air. Steep upward knockback |
| `neutral` | `ground_neutral` | Wide and slow. Also the fallback for every empty slot |
| `air_down` | `air_down` | `pogo_velocity` 260 bounces the player up on a hit |

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

**Run**

| Value | Effect |
|---|---|
| `duration` | Length of a run. 600 is the default; `run_config.tres` uses 120 while developing |
| `start_delay` | Pause after the run loads before the countdown starts |
| `death_delay` | Pause between the player dying and the run ending. The timer stops during it |
| `warning_time` | The timer warning sound plays once per second for this many last seconds |

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

**Feedback**

Feedback is game feel: shake, hitstop, flashes, rumble, and effect sprites. An entry is a named list of effects. A binding maps an event key to an entry id. The key is an event name from [events.md](events.md). World events also take `.peaceful` or `.combat`, and the variant wins over the plain name. Add an entry in `entries`, then add a row in `bindings`. Gameplay code does not change.

| Value | Effect |
|---|---|
| `shake_max_offset` | Largest camera offset at full trauma (px) |
| `shake_decay` | Trauma lost per second. Higher ends shake sooner |
| `shake_noise_speed` | How fast the shake jitters |
| `bindings` | Event key to entry id |

Shake strength follows trauma squared, so small hits stay subtle and big ones kick hard. Hitstop and flashes run on real time, so a hitstop never stretches itself.

| Effect | Value | Effect |
|---|---|---|
| `ShakeEffect` | `trauma` | Trauma added, 0 to 1 |
| `HitstopEffect` | `duration` | Real seconds of slowdown |
| `HitstopEffect` | `time_scale` | Game speed during the slowdown. 0 is frozen |
| `ScreenFlashEffect` | `color` | Flash color. Alpha is the starting strength |
| `ScreenFlashEffect` | `duration` | Fade-out seconds |
| `SpriteFlashEffect` | `color`, `duration` | Flash of the event's target sprite. The target needs a `flash` method |
| `HapticsEffect` | `weak`, `strong` | Motor strength, 0 to 1 |
| `HapticsEffect` | `duration` | Rumble seconds |
| `SpawnFxEffect` | `animation` | One-shot sprite. Plays at the event's position and frees itself |
| `SpawnFxEffect` | `offset` | Shift from that position (px) |

Entries now: `shift` (small shake and rumble, on `world_shift_started`), `shift_denied` (light rumble, on `shift_denied`), `player_hurt` (shake, hitstop, red screen flash, red sprite flash, rumble, on `player_damaged`), and `player_death` (large shake, white screen flash, strong rumble, on `player_died`). `player_attacked`, `player_damaged`, and `player_died` also have sound bindings, and `attack_swing` has a `SoundDef` for pitch variation and 3 voices.

**Attacks**

An `AttackData` config describes one attack. A `Moveset` config holds up to eight of them: ground and air, each neutral, side, up, and down. A missing air slot uses the ground slot of the same direction, then `ground_neutral`. `ground_neutral` must be set.

| Value | Effect |
|---|---|
| `id`, `animation` | Name of the attack and the animation played |
| `hitbox_size`, `hitbox_offset` | Hitbox size and center from the feet, facing right (px) |
| `startup`, `active`, `recovery` | Seconds before the hit, during it, and after it. Divided by the attacker's attack speed |
| `damage` | Health removed |
| `knockback_angle` | Degrees. 0 forward, -90 up, 90 down |
| `knockback_force` | Knockback speed (px/s) |
| `move_control` | Share of normal acceleration kept during the attack, 0 to 1 |
| `pogo_velocity` | Upward speed the attacker gets on a hit (px/s) |
| `hit_feedback`, `hit_sound` | Feedback entry id and sound id played on a hit |
| `tags` | Labels passed to the damage info |

**Enemies**

An `EnemyData` config describes one enemy type. `config/enemies/walker.tres` is the walker. The spawner sets `data` on the enemy before it enters the tree.

| Value | Effect |
|---|---|
| `id`, `scene` | Enemy id (also the animation prefix: `<id>_idle`, `<id>_run`, `<id>_hurt`, `<id>_death`) and the scene the spawner makes |
| `max_health` | Hit points |
| `knockback_resistance` | Share of knockback ignored, 0 to 1 |
| `hurt_stun` | Seconds the enemy cannot act after a hit |
| `death_time` | Seconds from death until it is removed |
| `move_speed`, `chase_speed` | Patrol and chase speed (px/s) |
| `accel` | Acceleration toward the target speed (px/s^2) |
| `gravity`, `max_fall_speed` | Gravity (px/s^2) and terminal fall speed (px/s) |
| `detect_range` | Horizontal and vertical distance at which it spots the player (px) |
| `lose_range` | Distance beyond which a chasing enemy gives up (px) |
| `contact_damage` | Health the player loses on touching it |
| `contact_knockback_force`, `contact_knockback_angle` | Knockback on the player (px/s) and its angle (degrees, 0 away from the enemy, -90 up) |
| `currency_drop`, `score_value` | Currency dropped and score given on a kill. Used by later branches |
| `body_size` | Collision and hurt box size, feet at the origin (px). The contact box is 80% of it |
| `animations` | Animation strips the sprite builds |

**Spawning**

A `SpawnConfig` config drives the spawner. Run progress (time elapsed over the run length) goes through `ramp` to a value from 0 to 1, and that value blends each start value into its end value. The spawner only counts down while the run is live and the combat world is shown.

| Value | Effect |
|---|---|
| `enemies` | Enemy types the spawner picks from at random |
| `first_delay` | Seconds after the run starts before the first spawn |
| `start_interval`, `end_interval` | Seconds between spawns at the start and at the end of the run |
| `start_max_alive`, `end_max_alive` | Enemies plus warnings alive at once at the start and at the end of the run |
| `ramp` | Curve from run progress to ramp value. Empty means linear |
| `telegraph_time` | Seconds the warning shows before the enemy appears |
| `min_player_distance` | Spawn markers closer to the player than this are skipped (px). With none left, that spawn is skipped |
| `telegraph_animation` | Animation of the warning |

Spawn points are `Marker2D` nodes in the `enemy_spawn` group, under `CombatWorld/SpawnPoints` in the arena.

**Economy**

An `EconomyConfig` config drives currency. A killed enemy drops its `currency_drop` split into at most `max_pickups_per_drop` pickups, each worth a share of the total. A pickup pops out, waits `pickup_delay`, then flies to the player's magnet or is collected by touching the player.

| Value | Effect |
|---|---|
| `start_currency` | Currency at the start of a run |
| `max_pickups_per_drop` | A drop never splits into more pickups than this. The total stays the same |
| `pop_speed` | Pop range when a pickup drops: x is the sideways range, y the upward range (px/s) |
| `pop_damping` | How fast the pop slows down (1/s) |
| `pickup_delay` | Seconds after dropping before a pickup can be attracted or collected |
| `fly_accel`, `max_fly_speed` | Acceleration and top speed toward the magnet (px/s^2, px/s) |
| `collect_distance` | Distance to the magnet at which a pickup is collected (px) |
| `lifetime` | Seconds before an uncollected pickup disappears |
| `blink_time`, `blink_rate` | Seconds at the end of the lifetime during which a pickup blinks, and blinks per second |
| `pickup_animation` | Animation of a pickup |

Uncollected pickups are cleared when the world shifts.

**Score**

A `ScoreConfig` config drives score and the combo. A landed hit in the combat world adds `score_per_hit` times the multiplier and fills the combo bar; a kill adds the enemy's `score_value` times the multiplier. A full bar raises the multiplier one step and keeps the overflow. After `drain_delay` without a hit the bar drains, and reaching 0 with a multiplier above 1 breaks the combo. Taking damage breaks it at once.

| Value | Effect |
|---|---|
| `score_per_hit` | Score for a landed hit, before the multiplier |
| `fill_per_hit` | Bar fill added by a hit (the bar is 0 to 1) |
| `max_multiplier` | Highest multiplier. At the cap the bar stays full |
| `drain_delay` | Seconds without a hit before the bar drains |
| `drain_rate` | Bar fill lost per second while draining |
| `damage_breaks_combo` | Taking damage resets the bar and the multiplier |
| `drain_in_peaceful` | The bar also drains while the world is peaceful. Off by default, so the delay and the drain pause there |

Enemy `score_value` is set per enemy (see Walker). The combo sounds bind `combo_raised` to `combo_up` and `combo_broken` to `combo_break` in `sound_config.tres`; `combo_up` is also a `feedback_config.tres` entry bound to `combo_raised`.

**UI**

| Value | Effect |
|---|---|
| `font_path` | Resource path of the UI font. A missing file uses the engine default font |
| `font_size` | Font size (px) |
| `text_color` | Normal text |
| `highlight_color` | The selected letter, the focused button, and the new high score row |
| `dim_color` | Empty list rows and disabled buttons |
| `panel_path` | Resource path of the 9-slice panel texture |
| `panel_margin` | Width of the panel border and the space inside it (px) |
| `panel_size` | Size of the fallback panel box when the art is missing (px). Must be larger than twice `panel_margin` |

The high score table keeps the best 10 scores and the last initials typed, in `user://save.cfg`. The table size is fixed in `Save` (`MAX_SCORES`), not a config.

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

Press **F1** (or the **Back** button on a gamepad) to show or hide the debug overlay. It shows player state, velocity, floor contact, coyote and buffer timers, the current world, the run phase, the time left, the shift cooldown, and FPS.
