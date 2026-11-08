# Events

Every cross-module signal is declared in `scripts/core/events.gd` (autoload `Events`). Modules emit with `Events.x.emit(...)` and listen with `Events.x.connect(...)`. They never connect to each other.

| Signal | Arguments | Emitted by | Listened to by | When it fires |
|---|---|---|---|---|
| `world_shift_started` | `to: World.Id` | `WorldShift` | nobody yet | A shift begins, before the screen fade |
| `world_shifted` | `to: World.Id` | `WorldShift` | `ArenaWorlds`, `Game` | The screen is covered and the world switches. Also once per run, from `WorldShift.start()`, the last step of the run setup order, with the starting world |
| `shift_denied` | none | `WorldShift` | nobody yet | Shift is pressed during the cooldown or an active shift |
| `arena_bounds_changed` | `bounds: Rect2` | `ArenaBounds` | `GameCamera` | `ArenaBounds.setup()` runs, the first step of the run setup order. Fires immediately, in the same frame. Carries the arena rect in global pixels |
| `player_spawned` | `player: Node2D` | `Player` | `GameCamera`, `DebugOverlay`, `Game` | `Player.spawn()` runs, the second step of the run setup order. Fires immediately, in the same frame |
| `stats_changed` | `owner: Node` | `Stats` | nobody yet | A modifier is added or removed. `owner` is the node holding the `Stats` |

When a branch adds a signal, it adds a row here in the same PR.
