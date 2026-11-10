# Architecture

Godot 4.7.2, GDScript, GL Compatibility renderer, web export.

## Folders

```
res://
  scripts/
    core/        shared code: Events, Stats helpers, AssetLoader, Layers, Display, Groups, World
    systems/     one folder per module: player, enemies, shift, camera, arena, input, debug, run, audio
    ui/          screens and widgets: title, menu stack and pages, results, initials entry, high score list, theme
  scenes/        title.tscn, run.tscn, and one scene folder per module
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

## Enemies

Enemies live in `scripts/systems/enemies/`. `enemy_base.tscn` is the shared scene: an `Enemy` body with `Stats`, `Health`, a `Hurtbox` and a `ContactHitbox` on the enemy team, a `StateMachine` holding `Hurt` and `Die`, an `EnemyAnimator`, and a `Visual` with the sprite and a ledge ray. Each enemy type is a scene that inherits the base and adds its own states, such as `walker.tscn` with `Patrol` and `Chase`, and an `EnemyData` config beside it.

**Data is set by the spawner.** `Enemy.data` is set before the enemy enters the tree and is never saved in a scene, which would make a resource cycle with `EnemyData.scene`. `_ready` gives `data` to `Stats`, sizes the body, hurtbox, and contact box from `body_size`, and emits `enemy_spawned`.

**Frame order.** Like the player, the enemy drives its machine: state physics, then `move_and_slide`. States call the enemy's verbs (`walk`, `stop`, `apply_gravity`, `at_wall`, `at_ledge`, `target_in`) and own the transitions.

**Hit, hurt, and death.** A hit reaches `Hurtbox`; the enemy emits `hit_landed` and enters `Hurt`, which applies the knockback less `knockback_resistance` and returns to `resume_state`. When `Health` empties, the enemy enters `Die` first: it turns both boxes off, emits `enemy_killed`, and frees itself after `death_time`, counted in physics. `Run` counts kills from `enemy_killed`. `Audio` and `Feedback` play from bindings.

**Spawner.** `Spawner` is a run-scene node. Each physics frame it does nothing unless `Game.is_combat_live()`, so a peaceful world or a run that is not `RUNNING` stops its countdown. When the countdown ends and enemies plus telegraphs are under the cap for the run's progress, it picks a random `enemy_spawn` marker far enough from `Game.player` and adds a `SpawnTelegraph` there. Telegraphs and the enemies they place live under the combat `Content`, so the world freeze stops both, and a telegraph counts its time in physics. `SpawnConfig` turns run progress into the interval and the cap (see [tuning.md](tuning.md)).

## Economy

`Economy` is a run-scene node in `scripts/systems/economy/`. It holds the wallet (`currency`, starting at `start_currency`). On `enemy_killed` it splits the enemy's `currency_drop` into `Pickup` nodes under the combat `Content`, added deferred because a kill can land inside a physics callback. A `Pickup` is an `Area2D` on the pickup layer that watches the player layer: after `pickup_delay` it flies toward an overlapping area in the `magnet` group (the player's `Magnet`) or is collected by touching a body in the `player` group, then emits `currency_collected`. `Economy` adds that amount and emits `wallet_changed`, and again on `run_started`. On `world_shift_started` it frees every pickup. Pickups count time in `_physics_process`, so the world freeze stops them. `EconomyConfig` holds the tunables (see [tuning.md](tuning.md)); `magnet_radius` is a player stat.

## Score

`Score` is a run-scene node in `scripts/systems/scoring/`, placed after `Economy`. It holds `score`, the combo bar `fill`, and the `multiplier`. On `hit_landed` and `enemy_killed` it adds score, but only while `Game.world` is combat; a hit also fills the bar and raises the multiplier when it is full. Each physics frame, while `Game.phase` is `RUNNING` and the world is combat (or `drain_in_peaceful`), the bar drains after `drain_delay` without a hit. Draining to 0 with a multiplier above 1, or `player_damaged`, breaks the combo. It announces `score_changed`, `combo_changed`, `combo_raised`, and `combo_broken`; on `run_started` it announces its starting values. `Run` keeps `score` and `best_multiplier` from those events and copies them into the run result. `ScoreConfig` holds the tunables (see [tuning.md](tuning.md)).

## ActorSprite

`ActorSprite` (`scripts/core/actor_sprite.gd`) is the sprite of a character. `build(defs)` makes its frames and its own flash material. `play_id(id)` plays an animation and sets `offset` from the first frame's size, so the feet stay at the node origin for any frame size, then moves the asset label to the offset. `flash(color, duration)` blends the sprite to a color and back. The flash shader multiplies by the sprite's modulate, so the invulnerability blink on the parent still works. `SpriteFlashEffect` calls `flash` on the owner. Enemies use the same class.

In the editor, `ActorSprite` draws the first frame of `preview_animation` from the config at `preview_config` (or its labeled box), so each character shows in its scene. The preview is only drawn, never saved into the scene.

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
| `UiTheme` | Builds the shared UI `Theme` from `UiConfig` (font, colors, focus outline, panel box, compact buttons), once per config |
| `InputRebinder` | Rebinds one key and one gamepad button per action, with labels and glyph paths for the controls screen |
| `EventRouter` | Connects config-driven event keys to one handler and finds the binding for an emitted event |

## Save

`Save` (autoload, `scripts/core/save.gd`) keeps the top 10 high scores and the last initials in `user://save.cfg` (a browser reload keeps it on the web build). It loads in `_ready`. `qualifies(score)` says whether a score makes the table, and `add_high_score(initials, score)` inserts it, saves, and returns its rank. An equal score ranks below the existing one.

## Settings

`Settings` (autoload, `scripts/core/settings.gd`, between `Game` and `Audio`) keeps the player settings in `user://settings.cfg`: three volumes in steps of 0 to 10 (`Master`, `Music`, `SFX`) and the shake and flash toggles. The autoload order is `Events`, `Game`, `Settings`, `Audio`, `Feedback`, `Save`, so it is ready before `Feedback` reads it. A missing or unreadable file gives the defaults (10, 10, 10, on, on).

Every change saves at once and emits `settings_changed`. `set_volume(bus, steps)` clamps the steps and sets the bus volume (`volume_db`: 0 is muted, 10 is 0 dB). The `UI` bus sends into `SFX`, so the `SFX` volume scales menu sounds too. `Feedback` copies the two toggles on `_ready` and on every `settings_changed`.

## Input

Only `jump`, `attack`, `shift`, and `pause` are rebindable (`InputRebinder.REBINDABLE`), one key and one gamepad button each. Movement, the menu actions, and the debug overlay are fixed. `InputRebinder.rebind` replaces the action's events of that device. If another rebindable action already uses the new input on that device, it loses it and, when that leaves it with none, takes the old input of the rebound action. Joypad motion events are never touched.

Bindings are saved in the `input` section of `user://settings.cfg` as `<action>.<keyboard|gamepad>` keys holding arrays of key or button codes (`InputRebinder.snapshot`). `Settings.apply` restores them over the `project.godot` defaults, and an empty `input_bindings` means the defaults. `Settings.save_input_bindings` and `reset_input_bindings` save and emit `settings_changed`.

`ui_accept` (Enter, Kp Enter, Space, gamepad A) and `ui_cancel` (Escape, gamepad B) are defined in `project.godot`, so every menu works with the gamepad alone.

## UI

UI scripts are in `scripts/ui/`, scenes in `scenes/ui/`. The look comes from `UiConfig` and `UiTheme`: a screen sets `theme = UiTheme.build(config)` on its root control. All text a screen shows is in consts at the top of its script. A screen centers a `PanelContainer` in a `CenterContainer`; the theme draws the panel (9-slice, `panel_margin` border and inner space) and gives buttons compact margins. The game view is 320x180.

`Results` (a `CanvasLayer`, layer 20, process mode always so it works while the tree is paused) waits for `run_ended`. It shows a centered panel in two columns: the run's numbers and `InitialsEntry` on the left, `HighScoreList` on the right, `Restart` and `Title` below. A score that qualifies shows `InitialsEntry`, then `HighScoreList` with the new row marked. Otherwise it shows the list at once. `Restart` emits `run_restart_requested`.

`HUD` (a `CanvasLayer`, layer 10) shows the run in progress: health pips, timer, world name, score, combo bar with the multiplier, and currency. It reads events only and never polls: `player_health_changed`, `time_changed`, `time_warning`, `run_started`, `world_shifted`, `score_changed`, `combo_changed`, and `wallet_changed`. Each widget is set by its event, and the modules announce their starting values on `run_started`, so the HUD needs no direct reference to any of them. The pips are rebuilt whenever the max health changes.

## Scene flow

`title.tscn` is the main scene (`run/main_scene`). Play changes to `run.tscn`. When the run ends, `Results` offers Restart (reload the run scene) and Title. `Title` on `Results` emits `title_requested`, and `Run.go_to_title` resets `Game`, unpauses the tree, and changes to the title.

`Scenes` (`scripts/core/scenes.gd`) holds the two scene paths (`TITLE`, `RUN`) and `Scenes.change(tree, path)`, the one way to change scene: it records `last_request`, unpauses, and changes scene. Tests set `Scenes.changes_enabled = false` so the request is recorded and nothing changes.

`Title` emits `title_opened` on `_ready`, and `Audio` plays the title music (`music_title.ogg`) on it.

## Menus

`MenuStack` (`scripts/ui/menu_stack.gd`) holds `MenuPage` children, one visible at a time. `push_named` and `push` open a page, `back` returns to the one below with its focused control restored, and `ui_cancel` calls `back`. At the root `back` does nothing unless `can_close_root` is on, which then closes the stack and emits `emptied` (the pause menu uses it). `MenuStack` plays `ui_move` when focus moves inside the current page, and `ui_back` on back. A `MenuPage` has a `first_focus` control, plays `ui_confirm` for every button press in it, and has `opened()` for refreshing its content. Pages ask the stack with `push_requested` and `back_requested`.

`Title` (`scenes/title.tscn`, `scripts/ui/title.gd`) is a `MenuStack` with the pages `Main` (Play, High Scores, Credits), `HighScores` (the saved table), and `Credits`. The logo shows only on `Main`; while `ui_title_logo` is missing the game name shows as text.

## Missing assets

A missing sprite never breaks the game. `AssetLoader` returns a labeled colored box of the right size. A missing sound stays silent. Art and SFX can be added at any time.

## Two worlds

The peaceful and combat worlds share one collision layer. Only the skins and backgrounds differ, so the level shape is identical in both. A shift hides and disables the inactive world (`ArenaWorlds`). Combat content freezes while the peaceful world is active.

Rule: everything that belongs to combat (enemies, projectiles, drops) is spawned under `CombatWorld`, so the freeze applies to it.

In the editor: the floor is saved in `Collision` (paint it there), each `TileSkin` draws itself over the collision cells, and each `WorldBackground` shows its texture in an unsaved preview child. `CombatWorld` is saved hidden so the editor shows the peaceful world; toggle its eye (and its `Background`) to see combat. `ArenaWorlds` sets the real visibility when the game runs.

## Run setup order

`Run` (`scripts/systems/run/run.gd`) is the root of `run.tscn` and the composition root of the run scene. Its `_ready` runs after every child is ready. It is the only script that calls setup methods on the modules it composes. Modules do their own work in `_ready` but never depend on a sibling being set up.

1. `Game.reset()`
2. `Arena.setup()`: fills the default floor if `Collision` is empty, hides `Collision`, builds both skins, builds the walls and emits `arena_bounds_changed`, registers both `Content` nodes with `Game`
3. `Player.spawn(Arena.player_spawn_position())`: emits `player_spawned`
4. `WorldShift.start()`: emits `world_shifted` with the start world
5. Run state: sets `Game.run_duration` and `Game.time_left` from `RunConfig`, then enters `Starting`

Listeners are connected in `_ready`, so they all exist before the first signal fires. No setup signal is deferred.

## Run states

`Run` owns a `StateMachine` (last child) with three states in `scripts/systems/run/states/`. They set `Game.phase`, and `Run` is the only writer of the timer through them.

- `Starting`: emits `run_started` and `time_changed`, waits `start_delay` (or leaves at once if the player already died), then `Running`.
- `Running`: lowers `Game.time_left` each frame, emits `time_changed` when the whole seconds change and `time_warning` for the last `warning_time` seconds, and goes to `Ended` at 0. After `player_died` the timer stops and `Ended` follows after `death_delay`.
- `Ended`: pauses the tree (unless `Run.pause_tree_on_end` is off, for tests) and emits `run_ended` with a `RunResult`.

Restart: `run_restart_requested` makes `Run` unpause the tree and reload the scene, so every module starts fresh. `Feedback` resets itself on `run_started` and `run_ended`.

## Run scene

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
  Spawner
  Economy
  Score
  HUD              CanvasLayer, layer 10, reads events only
  Results          CanvasLayer, hidden until run_ended
  DebugOverlay
  StateMachine     Starting, Running, Ended
```
