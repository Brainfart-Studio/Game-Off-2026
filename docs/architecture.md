# Architecture

Godot 4.7.2, GDScript, GL Compatibility renderer, web export.

## Folders

```
res://
  scripts/
    core/        shared code: Events, Stats helpers, AssetLoader, Layers, Display, Groups, World
    systems/     one folder per module: player, shift, camera, arena, input, debug
  scenes/        main.tscn and one scene folder per module
  config/        .tres config resources (all tuning)
  art/           Loten
  audio/         sfx: Keltfire, music: Brainfart
  test/          GdUnit4 tests, mirroring scripts/
  tools/         check.sh and test.sh
  docs/          these files
```

## Three layers

1. **Core.** Code every module can use: the `Events` autoload, `GameConfig`, and static helpers.
2. **Systems.** Gameplay modules (player, shift, camera, arena). Each owns its scripts, scenes, and config class.
3. **Content.** `.tres` configs and the scenes built from them.

## Events rule

`Events` is the one global signal hub (`scripts/core/events.gd`). A module emits and listens on `Events`. Modules never call each other directly. See [events.md](events.md).

The debug overlay is the exception: it may read modules, found through groups.

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

## Missing assets

A missing sprite never breaks the game. `AssetLoader` returns a labeled colored box of the right size. A missing sound stays silent. Art and SFX can be added at any time.

## Two worlds

The peaceful and combat worlds share one collision layer. Only the skins and backgrounds differ, so the level shape is identical in both. A shift hides and disables the inactive world (`ArenaWorlds`). Combat content freezes while the peaceful world is active.

Rule: everything that belongs to combat (enemies, projectiles, drops) is spawned under `CombatWorld`, so the freeze applies to it.

## Main scene

```
Main
  Arena
    Collision        TileMapLayer, the shared collision
    PlayerSpawn
    ArenaBounds
    ArenaWorlds
    PeacefulWorld    skin, background
    CombatWorld      skin, background, combat content
  Player
  GameCamera
  WorldShift
  DebugOverlay
```
