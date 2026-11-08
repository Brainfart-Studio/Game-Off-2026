# Asset List

Generated from the team's planning copy. Do not edit here; ask Brainfart for changes.

For the artist and SFX designer. Rows are added per phase. Paths are relative to the game repo root. Names describe the role, not the theme, so they stay the same whatever setting we pick.

## Rules

- Commit only to your folder: `art/` (art) or `audio/sfx/` (SFX). Music is `audio/music/` (Brainfart).
- Use the exact path and file name. A missing file shows as a labeled box (art) or silence (sound), so commit rough versions early and replace them freely.
- Art: PNG. Animations are one horizontal strip per file, frames left to right, all frames the same size, no padding. Characters stand on the bottom edge, centered.
- Game resolution is 480x270, scaled up by whole numbers. Tiles are 16x16. The player is about 24 px tall inside a 32x32 frame.
- If you need a different frame size or count, change it and tell Brainfart; it is one config value, not code.
- SFX: WAV, 44.1 kHz, mono unless noted, trimmed with no leading silence. Variations: add `_2`, `_3` to the name (for example `hit_enemy_2.wav`); the game picks one at random.
- Music: OGG, seamless loop.

## Art

| Id | Path | Frame size | Frames | FPS | Loop | Phase | What it is |
|---|---|---|---|---|---|---|---|
| player_idle | `art/player/player_idle.png` | 32x32 | 4 | 8 | yes | P1 | Standing still |
| player_run | `art/player/player_run.png` | 32x32 | 8 | 12 | yes | P1 | Running |
| player_jump | `art/player/player_jump.png` | 32x32 | 2 | 10 | no | P1 | Rising |
| player_apex | `art/player/player_apex.png` | 32x32 | 1 | | no | P1 | Top of the jump |
| player_fall | `art/player/player_fall.png` | 32x32 | 2 | 10 | yes | P1 | Falling |
| player_land | `art/player/player_land.png` | 32x32 | 2 | 15 | no | P1 | Landing squash |
| tiles_peaceful | `art/tiles/tiles_peaceful.png` | 16x16 | | | | P1 | Peaceful world ground tiles, one 48x32 sheet of 3x2 tiles. Top row: top-left corner, top, top-right corner. Bottom row: left edge, fill, right edge |
| tiles_combat | `art/tiles/tiles_combat.png` | 16x16 | | | | P1 | Combat world ground tiles, same 48x32 layout as peaceful |
| bg_peaceful | `art/backgrounds/bg_peaceful.png` | 480x270 | 1 | | | P1 | Peaceful world background |
| bg_combat | `art/backgrounds/bg_combat.png` | 480x270 | 1 | | | P1 | Combat world background |
| player_attack_side | `art/player/player_attack_side.png` | 64x32 | 6 | 20 | no | P2 | Attack forward (ground and air) |
| player_attack_up | `art/player/player_attack_up.png` | 32x64 | 6 | 20 | no | P2 | Attack upward |
| player_attack_neutral | `art/player/player_attack_neutral.png` | 64x32 | 6 | 20 | no | P2 | Attack with no direction held |
| player_attack_down_air | `art/player/player_attack_down_air.png` | 32x64 | 5 | 20 | no | P2 | Downward attack in the air (pogo) |
| player_hurt | `art/player/player_hurt.png` | 32x32 | 2 | 10 | no | P2 | Taking a hit |
| player_death | `art/player/player_death.png` | 32x32 | 6 | 10 | no | P2 | Dying |
| walker_idle | `art/enemies/walker/walker_idle.png` | 32x32 | 4 | 8 | yes | P2 | First enemy, standing |
| walker_run | `art/enemies/walker/walker_run.png` | 32x32 | 6 | 12 | yes | P2 | Walking and chasing |
| walker_hurt | `art/enemies/walker/walker_hurt.png` | 32x32 | 2 | 10 | no | P2 | Taking a hit |
| walker_death | `art/enemies/walker/walker_death.png` | 32x32 | 6 | 12 | no | P2 | Dying |
| fx_spawn_telegraph | `art/fx/fx_spawn_telegraph.png` | 32x32 | 6 | 12 | yes | P2 | Warning where an enemy is about to appear |
| fx_hit_spark | `art/fx/fx_hit_spark.png` | 32x32 | 4 | 24 | no | P2 | Burst on a landed hit |
| fx_death_burst | `art/fx/fx_death_burst.png` | 32x32 | 6 | 20 | no | P2 | Burst when an enemy dies |
| pickup_currency | `art/pickups/pickup_currency.png` | 12x12 | 6 | 12 | yes | P2 | Currency dropped by enemies |
| ui_health_full | `art/ui/ui_health_full.png` | 12x12 | 1 | | | P2 | Health pip, full |
| ui_health_empty | `art/ui/ui_health_empty.png` | 12x12 | 1 | | | P2 | Health pip, empty |
| ui_currency_icon | `art/ui/ui_currency_icon.png` | 12x12 | 1 | | | P2 | Currency icon on the HUD |
| ui_combo_frame | `art/ui/ui_combo_frame.png` | 96x10 | 1 | | | P2 | Combo bar outline |
| ui_combo_fill | `art/ui/ui_combo_fill.png` | 96x10 | 1 | | | P2 | Combo bar fill, cropped by the game as it fills |
| ui_panel | `art/ui/ui_panel.png` | 48x48 | 1 | | | P2 | 9-slice panel for results and menus (16 px borders) |
| font_main | `art/fonts/font_main.ttf` | | | | | P2 | Pixel font (or a free licensed one); credit it |

## SFX

| Id | Path | Phase | When it plays |
|---|---|---|---|
| player_jump | `audio/sfx/player_jump.wav` | P1 | Jump starts |
| player_land | `audio/sfx/player_land.wav` | P1 | Landing |
| player_step | `audio/sfx/player_step.wav` | P1 | Footstep while running (variations welcome) |
| shift_to_peaceful | `audio/sfx/shift_to_peaceful.wav` | P1 | Shifting into the peaceful world |
| shift_to_combat | `audio/sfx/shift_to_combat.wav` | P1 | Shifting into the combat world |
| shift_denied | `audio/sfx/shift_denied.wav` | P1 | Shift pressed during its cooldown |
| attack_swing | `audio/sfx/attack_swing.wav` | P2 | Any attack starts (variations welcome) |
| hit_enemy | `audio/sfx/hit_enemy.wav` | P2 | The player's attack lands |
| player_hurt | `audio/sfx/player_hurt.wav` | P2 | The player takes a hit |
| player_death | `audio/sfx/player_death.wav` | P2 | The player dies |
| enemy_spawn_warning | `audio/sfx/enemy_spawn_warning.wav` | P2 | Spawn warning appears |
| enemy_spawn | `audio/sfx/enemy_spawn.wav` | P2 | The enemy appears |
| enemy_death | `audio/sfx/enemy_death.wav` | P2 | An enemy dies |
| currency_pickup | `audio/sfx/currency_pickup.wav` | P2 | Currency collected (short, plays a lot) |
| combo_up | `audio/sfx/combo_up.wav` | P2 | Multiplier goes up a step |
| combo_break | `audio/sfx/combo_break.wav` | P2 | Multiplier lost |
| timer_warning | `audio/sfx/timer_warning.wav` | P2 | Last 10 seconds, once per second |
| run_end | `audio/sfx/run_end.wav` | P2 | The run ends |
| high_score | `audio/sfx/high_score.wav` | P2 | New high score on the results screen |
| ui_move | `audio/sfx/ui_move.wav` | P2 | Menu selection moves |
| ui_confirm | `audio/sfx/ui_confirm.wav` | P2 | Menu confirm |
| ui_back | `audio/sfx/ui_back.wav` | P2 | Menu back |

## Music

| Id | Path | Phase | What it is |
|---|---|---|---|
| music_peaceful | `audio/music/music_peaceful.ogg` | P2 | Peaceful world loop |
| music_combat | `audio/music/music_combat.ogg` | P2 | Combat world loop; crossfades with peaceful on a shift |
