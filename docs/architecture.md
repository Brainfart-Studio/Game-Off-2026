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

## Feedback

`Feedback` (`scenes/feedback/feedback.tscn`, autoload after `Audio`) plays game feel: camera shake, hitstop, screen flash, sprite flash, gamepad rumble, and one-shot effect sprites. An effect is a `FeedbackEffect` resource, a `FeedbackEntry` is a named list of effects, and `feedback_config.tres` binds events to entries. New effects are new resource classes, not new code paths.

Gameplay code never calls `Feedback`. It emits on `Events`, and `Feedback` plays the entry bound to that event, using the same `EventRouter` keys as `Audio`. The event's first `Node2D` or `Vector2` argument becomes the effect position (`FeedbackContext`).

Toggles: `enabled` blocks everything, `shake_enabled` blocks shake, `flash_enabled` blocks screen flashes. Tests that run combat physics turn `enabled` off and restore it. Hitstop changes `Engine.time_scale` and restores it on real time. `Feedback.reset()` puts time, shake, and flash back to normal.

## Combat

Combat pieces live in `scripts/systems/combat/` and know nothing about the player or enemies. An owner builds them from a `Team.Id` (`PLAYER` or `ENEMY`), a `Health`, a `Hurtbox`, and a `Hitbox`.

**Teams and layers.** A hitbox sits on its team's hitbox layer and looks for the other team's hurtbox layer. A hurtbox sits on its team's hurtbox layer and looks for nothing, so a hit can never land on its own team. Layer bits come from `Layers`, never numbers.

**Hitbox rules.** `activate(data, facing, damage, reach)` starts an attack: each hurtbox is hit once per activation, and a new activation hits again. `set_contact(...)` starts a contact box that tries every overlapping hurtbox each physics frame; the target's invulnerability stops repeats. Knockback x follows the attacker's facing, or the side the target is on for contact. A hit builds a `DamageInfo` and gives it to the hurtbox; `landed` fires only when the health took it.

**Health.** `Health` holds `current` and `max_value`, read from `Stats` by stat name. `damage(info)` refuses when dead, invulnerable, or the amount is 0. `iframes_stat` names the stat for invulnerability after a hit; empty means none. `died` fires once. A change to the owner's stats recomputes the max and raises `current` by any gain.

**Hurt side emits events.** `Hurtbox` and `Health` signals stay local. The owner of the hurt side listens to them and emits the `Events` signal, passing the `DamageInfo` first. `Feedback` and `Audio` then play `info.feedback` and `info.sound` when they are set, and the event's own binding otherwise. The event still needs a binding row so the services listen to it.

**Attacks.** An `AttackData` config holds one attack's hitbox, timing, damage, knockback, and effects. A `Moveset` picks the attack by stance and input direction, falling back from air to ground to `ground_neutral`.

## ActorSprite

`ActorSprite` (`scripts/core/actor_sprite.gd`) is the sprite of a character. `build(defs)` makes its frames and its own flash material. `play_id(id)` plays an animation and sets `offset` from the first frame's size, so the feet stay at the node origin for any frame size, then moves the asset label to the offset. `flash(color, duration)` blends the sprite to a color and back. The flash shader multiplies by the sprite's modulate, so the invulnerability blink on the parent still works. `SpriteFlashEffect` calls `flash` on the owner. Enemies use the same class.

## Player combat

The player attacks, takes hits, and dies through states: `Attack`, `Hurt`, and `Dead`. `Attack` reads the `Moveset` and the held direction when it starts, locks the facing, and turns `AttackHitbox` on after startup and off after the active time. `Health` and `Stats` are siblings under the player. A hit reaches the player through `Hurtbox`; the player emits `player_damaged`, `player_health_changed`, and `player_died`, and `Audio` and `Feedback` play from bindings. Run end on death is the run loop's job, not the player's.

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
