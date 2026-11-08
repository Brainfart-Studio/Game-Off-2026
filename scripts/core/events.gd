extends Node
## Global event bus (autoload `Events`).
##
## Every cross-module signal is declared here. Modules emit `Events.x.emit(...)`
## and connect `Events.x.connect(...)`, never to each other. Later phases add
## their signals to this file.

signal world_shift_started(to: World.Id)
signal world_shifted(to: World.Id)
signal shift_denied()
signal arena_bounds_changed(bounds: Rect2)
signal player_spawned(player: Node2D)
signal stats_changed(owner: Node)
signal player_jumped()
signal player_landed()
signal player_stepped()
signal player_attacked(attack: AttackData)
signal player_damaged(info: DamageInfo)
signal player_health_changed(current: int, max_health: int)
signal player_died()
signal run_started()
signal time_changed(left: float)
signal time_warning(seconds_left: int)
signal run_ended(result: RunResult)
signal run_restart_requested()
signal hit_landed(info: DamageInfo)
signal enemy_spawned(enemy: Node2D)
signal enemy_killed(enemy: Node2D, data: EnemyData, info: DamageInfo)
signal enemy_spawn_warned(position: Vector2)
signal currency_collected(amount: int)
signal wallet_changed(currency: int)
signal score_changed(score: int)
signal combo_changed(fill: float, multiplier: int)
signal combo_raised(multiplier: int)
signal combo_broken()
