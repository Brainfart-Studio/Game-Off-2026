# Architecture

Godot 4.7.2, GDScript, GL Compatibility renderer, web export.

## Folders

```
res://
  scripts/
    core/        shared code: Events, Stats helpers, AssetLoader, Layers, Display, Groups, World
    systems/     one folder per module: player, shift, camera, arena, input, debug, run, audio
  scenes/        main.tscn and one scene folder per module
  config/        .tres config resources (all tuning)
  art/           Loten
  audio/         sfx: Keltfire, music: Brainfart
  test/          GdUnit4 tests, mirroring scripts/
  tools/         check.sh and test.sh
  docs/          these files
```

## Three layers

1. **Core.** Code every module can use: the `Events` and `Game` autoloads, `GameConfig`, and static helpers.
2. **Systems.** Gameplay modules (player, shift, camera, arena). Each owns its scripts, scenes, and config class.
3. **Content.** `.tres` configs and the scenes built from them.

## Events rule

`Events` is the one global signal hub (`scripts/core/events.gd`). A module emits and listens on `Events`. Modules never call each other directly. See [events.md](events.md).

The debug overlay is the exception: it may read modules, found through groups.

## Game

`Game` (`scripts/core/game.gd`, autoload right after `Events`) holds the state of the current run: `phase`, `world`, `player`, `run_duration`, `time_left`, and the content parents. `Run` is the only writer of `phase`, `run_duration`, and `time_left`. `world` and `player` follow `Events.world_shifted` and `Events.player_spawned`. Everything else only reads. `Game.reset()` puts every field back to its default.

Each world has a `Content` node. `Arena` registers both with `Game.register_content`, and anything spawned for a world is added under `Game.content_parent(world)`. Combat content stays under `CombatWorld/Content`, so the freeze applies to it.

## Audio

`Audio` (`scenes/audio/audio.tscn`, autoload after `Game`) plays every sound. It keeps a pool of players, finds files by naming convention (`audio/sfx/<id>.wav`, see [tuning.md](tuning.md)), and runs two music players that crossfade on `world_shifted`. The buses are `Master`, `Music`, `SFX`, `UI` (`default_bus_layout.tres`).

Gameplay code never calls `Audio`. It emits on `Events`, and `Audio` plays the sound bound to that event in `sound_config.tres`. `EventRouter` connects the bound events and looks up the binding, trying the world variant first. Modules that need sound add a binding, not a call.

## Configs

Every tunable lives in a `GameConfig` resource under `config/`, edited in the inspector. Scripts read the values and hold no magic numbers. A config can override `validate()` to return warnings. See [tuning.md](tuning.md).

`Stats` is a node that wraps any `GameConfig`. It returns the base value plus additive modifiers, times multiplicative ones, and emits `stats_changed(owner)` when modifiers change. Gameplay reads values through `Stats`, so upgrades never edit the config.

## Static helpers

These are classes with static functions, not autoloads.

| Helper | Use |
|---|---|
| `AssetLoader` | Loads textures and sprite strips, with a fallback |
| `Layers` | Physics layer bit values and names. Scripts never use layer numbers |
| `Display` | View size from project settings. Scripts never hard-code the resolution |
| `Groups` | Node group names, used for lookups |
| `Actions` | Input action names. Scripts never use action strings or raw keys |
| `EventRouter` | Connects config-driven event keys to one handler and finds the binding for an emitted event |

## Missing assets

A missing sprite never breaks the game. `AssetLoader` returns a labeled colored box of the right size. A missing sound stays silent. Art and SFX can be added at any time.

## Two worlds

The peaceful and combat worlds share one collision layer. Only the skins and backgrounds differ, so the level shape is identical in both. A shift hides and disables the inactive world (`ArenaWorlds`). Combat content freezes while the peaceful world is active.

Rule: everything that belongs to combat (enemies, projectiles, drops) is spawned under `CombatWorld`, so the freeze applies to it.

## Run setup order

`Run` (`scripts/systems/run/run.gd`) is the root of `main.tscn` and the composition root of the run scene. Its `_ready` runs after every child is ready. It is the only script that calls setup methods on the modules it composes. Modules do their own work in `_ready` but never depend on a sibling being set up.

1. `Game.reset()`
2. `Arena.setup()`: fills the default floor, hides `Collision`, builds both skins, builds the walls and emits `arena_bounds_changed`, registers both `Content` nodes with `Game`
3. `Player.spawn(Arena.player_spawn_position())`: emits `player_spawned`
4. `WorldShift.start()`: emits `world_shifted` with the start world

Listeners are connected in `_ready`, so they all exist before the first signal fires. No setup signal is deferred.

## Main scene

```
Run                  composition root, script run.gd
  Arena
    Collision        TileMapLayer, the shared collision
    PlayerSpawn
    ArenaBounds
    ArenaWorlds
    PeacefulWorld    skin, background, Content
    CombatWorld      skin, background, Content (combat content)
  Player
  GameCamera
  WorldShift
  DebugOverlay
```
