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
signal stats_changed()
