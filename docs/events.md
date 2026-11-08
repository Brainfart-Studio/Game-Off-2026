# Events

Every cross-module signal is declared in `scripts/core/events.gd` (autoload `Events`). Modules emit with `Events.x.emit(...)` and listen with `Events.x.connect(...)`. They never connect to each other.

| Signal | Arguments | Emitted by | Listened to by | When it fires |
|---|---|---|---|---|
| `world_shift_started` | `to: World.Id` | `WorldShift` | `Audio` (bound sounds) | A shift begins, before the screen fade |
| `world_shifted` | `to: World.Id` | `WorldShift` | `ArenaWorlds`, `Game`, `Audio` (music crossfade) | The screen is covered and the world switches. Also once per run, from `WorldShift.start()`, the last step of the run setup order, with the starting world |
| `shift_denied` | none | `WorldShift` | `Audio` (bound sounds) | Shift is pressed during the cooldown or an active shift |
| `arena_bounds_changed` | `bounds: Rect2` | `ArenaBounds` | `GameCamera` | `ArenaBounds.setup()` runs, the first step of the run setup order. Fires immediately, in the same frame. Carries the arena rect in global pixels |
| `player_spawned` | `player: Node2D` | `Player` | `GameCamera`, `DebugOverlay`, `Game` | `Player.spawn()` runs, the second step of the run setup order. Fires immediately, in the same frame |
| `stats_changed` | `owner: Node` | `Stats` | nobody yet | A modifier is added or removed. `owner` is the node holding the `Stats` |
| `player_jumped` | none | `Player` | `Audio` (bound sounds) | `Player.jump()` launches a jump |
| `player_landed` | none | `Player` | `Audio` (bound sounds) | After `move_and_slide()`, the player is on the floor and was not on the previous frame |
| `player_stepped` | none | `Player` | `Audio` (bound sounds) | While running on the floor (speed above 1 px/s), every `step_interval`. The first step fires on the first running frame |

`Audio` listens to the signals named in `sound_config.tres` `bindings` (see [tuning.md](tuning.md)), plus `world_shifted` for music. A bound event can also be a world event with a variant key, such as `world_shift_started.combat`.

When a branch adds a signal, it adds a row here in the same PR.
