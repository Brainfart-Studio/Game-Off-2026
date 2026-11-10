# Events

Every cross-module signal is declared in `scripts/core/events.gd` (autoload `Events`). Modules emit with `Events.x.emit(...)` and listen with `Events.x.connect(...)`. They never connect to each other.

| Signal | Arguments | Emitted by | Listened to by | When it fires |
|---|---|---|---|---|
| `world_shift_started` | `to: World.Id` | `WorldShift` | `Audio` (bound sounds), `Feedback` (bound entries), `Economy` (clears pickups) | A shift begins, before the screen fade |
| `world_shifted` | `to: World.Id` | `WorldShift` | `ArenaWorlds`, `Game`, `Audio` (music crossfade), `HUD` | The screen is covered and the world switches. Also once per run, from `WorldShift.start()`, the last step of the run setup order, with the starting world |
| `shift_denied` | none | `WorldShift` | `Audio` (bound sounds), `Feedback` (bound entries) | Shift is pressed during the cooldown or an active shift |
| `arena_bounds_changed` | `bounds: Rect2` | `ArenaBounds` | `GameCamera` | `ArenaBounds.setup()` runs, the first step of the run setup order. Fires immediately, in the same frame. Carries the arena rect in global pixels |
| `player_spawned` | `player: Node2D` | `Player` | `GameCamera`, `DebugOverlay`, `Game` | `Player.spawn()` runs, the second step of the run setup order. Fires immediately, in the same frame |
| `stats_changed` | `owner: Node` | `Stats` | nobody yet | A modifier is added or removed. `owner` is the node holding the `Stats` |
| `player_jumped` | none | `Player` | `Audio` (bound sounds) | `Player.jump()` launches a jump |
| `player_landed` | none | `Player` | `Audio` (bound sounds) | After `move_and_slide()`, the player is on the floor and was not on the previous frame |
| `player_stepped` | none | `Player` | `Audio` (bound sounds) | While running on the floor (speed above 1 px/s), every `step_interval`. The first step fires on the first running frame |
| `player_attacked` | `attack: AttackData` | `PlayerAttack` state | `Audio` (bound sounds) | An attack starts, as the player enters the `Attack` state |
| `player_damaged` | `info: DamageInfo` | `Player` | `Audio`, `Feedback` (bound entries), `Score` (breaks the combo) | The player took a hit that was not blocked by invulnerability. Fires also on the killing hit, after `player_died` |
| `player_health_changed` | `current: int`, `max_health: int` | `Player` | `HUD` | The player's health changed, and once from `Player.spawn()` |
| `player_died` | none | `Player` | `Audio`, `Feedback` (bound entries) | The player's health reached 0. Fires once, before `player_damaged` of the same hit |
| `hit_landed` | `info: DamageInfo` | `Enemy` | `Audio`, `Feedback` (bound entries), `Score` | An enemy took a hit. Fires also on the killing hit, after `enemy_killed` |
| `enemy_spawned` | `enemy: Node2D` | `Enemy` | `Audio` (bound sounds) | An enemy finishes `_ready`, with its data set |
| `enemy_spawn_warned` | `position: Vector2` | `SpawnTelegraph` | `Audio` (bound sounds) | A spawn telegraph appears, before the enemy does. `position` is where the enemy will stand |
| `enemy_killed` | `enemy: Node2D`, `data: EnemyData`, `info: DamageInfo` | `EnemyDie` state | `Run` (kill count), `Economy` (drops), `Score`, `Audio`, `Feedback` (bound entries) | An enemy enters `Die`. Fires once, before `hit_landed` of the same hit |
| `currency_collected` | `amount: int` | `Pickup` | `Economy`, `Audio` (bound sounds) | A pickup is collected, by the magnet or by touching the player. Fires once per pickup |
| `wallet_changed` | `currency: int` | `Economy` | `HUD` | The wallet changed, and once when the run starts |
| `score_changed` | `score: int` | `Score` | `Run` (result score), `HUD` | The score changed, and once when the run starts |
| `combo_changed` | `fill: float`, `multiplier: int` | `Score` | `Run` (best multiplier), `HUD` | The combo bar or multiplier changed, including each frame the bar drains, and once when the run starts |
| `combo_raised` | `multiplier: int` | `Score` | `Audio`, `Feedback` (bound entries) | The bar filled and the multiplier went up one step. Not fired at the cap |
| `combo_broken` | none | `Score` | `Audio` (bound sounds) | A multiplier above 1 was lost, by draining to 0 or by the player taking damage |
| `settings_changed` | none | `Settings` | `Feedback` (copies the toggles) | A volume or a toggle changed to a new value, or the settings were reset to defaults |
| `run_started` | none | `RunStarting` state | `Feedback` (reset), `Economy`, `Score`, `HUD` (timer color) | The run enters `Starting`, right after the run setup order. Modules announce their starting values on it |
| `time_changed` | `left: float` | `RunStarting`, `RunRunning` | `HUD` | Once when the run starts, then each time the whole seconds left change, and at 0 |
| `time_warning` | `seconds_left: int` | `RunRunning` | `Audio` (bound sounds), `HUD` (timer color) | Once per second from `warning_time` seconds left down to 1, when that second begins |
| `run_ended` | `result: RunResult` | `RunEnded` state | `Audio` (bound sounds), `Feedback` (reset), `Results` | The timer reaches 0, or `death_delay` runs out after the player died. The tree is paused first |
| `run_restart_requested` | none | `Results` | `Run` | A restart is requested. `Run` unpauses and reloads the scene |
| `run_pause_requested` | `paused: bool` | `PauseMenu` | `Run` | The player asks to pause or resume. `Run` ignores a request that matches the current state, or a pause outside Starting and Running |
| `run_paused` | `paused: bool` | `Run` | `PauseMenu` | The run was paused or resumed. `Game.paused` already holds the new value |
| `title_requested` | none | `Results` | `Run` | The Title button was pressed. `Run` resets `Game`, unpauses, and changes to the title scene |
| `title_opened` | none | `Title` | `Audio` | The title screen is ready. `Audio` plays the title music |

`Audio` listens to the signals named in `sound_config.tres` `bindings` (see [tuning.md](tuning.md)), plus `world_shifted` for music. A bound event can also be a world event with a variant key, such as `world_shift_started.combat`.

`Feedback` listens to the signals named in `feedback_config.tres` `bindings`, with the same world variant keys.

When a branch adds a signal, it adds a row here in the same PR.
