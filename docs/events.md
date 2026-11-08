# Events

Every cross-module signal is declared in `scripts/core/events.gd` (autoload `Events`). Modules emit with `Events.x.emit(...)` and listen with `Events.x.connect(...)`. They never connect to each other.

| Signal | Arguments | Emitted by | Listened to by | When it fires |
|---|---|---|---|---|
| `world_shift_started` | `to: World.Id` | `WorldShift` | `Audio` (bound sounds), `Feedback` (bound entries) | A shift begins, before the screen fade |
| `world_shifted` | `to: World.Id` | `WorldShift` | `ArenaWorlds`, `Game`, `Audio` (music crossfade) | The screen is covered and the world switches. Also once per run, from `WorldShift.start()`, the last step of the run setup order, with the starting world |
| `shift_denied` | none | `WorldShift` | `Audio` (bound sounds), `Feedback` (bound entries) | Shift is pressed during the cooldown or an active shift |
| `arena_bounds_changed` | `bounds: Rect2` | `ArenaBounds` | `GameCamera` | `ArenaBounds.setup()` runs, the first step of the run setup order. Fires immediately, in the same frame. Carries the arena rect in global pixels |
| `player_spawned` | `player: Node2D` | `Player` | `GameCamera`, `DebugOverlay`, `Game` | `Player.spawn()` runs, the second step of the run setup order. Fires immediately, in the same frame |
| `stats_changed` | `owner: Node` | `Stats` | nobody yet | A modifier is added or removed. `owner` is the node holding the `Stats` |
| `player_jumped` | none | `Player` | `Audio` (bound sounds) | `Player.jump()` launches a jump |
| `player_landed` | none | `Player` | `Audio` (bound sounds) | After `move_and_slide()`, the player is on the floor and was not on the previous frame |
| `player_stepped` | none | `Player` | `Audio` (bound sounds) | While running on the floor (speed above 1 px/s), every `step_interval`. The first step fires on the first running frame |
| `player_attacked` | `attack: AttackData` | `PlayerAttack` state | `Audio` (bound sounds) | An attack starts, as the player enters the `Attack` state |
| `player_damaged` | `info: DamageInfo` | `Player` | `Audio`, `Feedback` (bound entries) | The player took a hit that was not blocked by invulnerability. Fires also on the killing hit, after `player_died` |
| `player_health_changed` | `current: int`, `max_health: int` | `Player` | nobody yet | The player's health changed, and once from `Player.spawn()` |
| `player_died` | none | `Player` | `Audio`, `Feedback` (bound entries) | The player's health reached 0. Fires once, before `player_damaged` of the same hit |

`Audio` listens to the signals named in `sound_config.tres` `bindings` (see [tuning.md](tuning.md)), plus `world_shifted` for music. A bound event can also be a world event with a variant key, such as `world_shift_started.combat`.

`Feedback` listens to the signals named in `feedback_config.tres` `bindings`, with the same world variant keys.

When a branch adds a signal, it adds a row here in the same PR.
