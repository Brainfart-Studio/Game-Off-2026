# Tuning

All tunable values live in config resources. No tuning value is hard-coded in a script.

## Where configs live

| Config | File | Controls |
|---|---|---|
| Player | `config/player/player_config.tres` | Movement, jump, gravity, body size, animations |
| Camera | `config/camera/camera_config.tres` | Follow smoothing, look-ahead, drag margins |
| Shift | `config/shift/shift_config.tres` | World shift cooldown and screen fade |

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

Press **F1** (or the **Back** button on a gamepad) to show or hide the debug overlay. It shows player state, velocity, floor contact, coyote and buffer timers, the current world, the shift cooldown, and FPS.
