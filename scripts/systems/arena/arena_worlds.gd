class_name ArenaWorlds
extends Node
## Shows the world matching `Events.world_shifted` and disables the other.

@onready var _peaceful: Node2D = $"../PeacefulWorld"
@onready var _combat: Node2D = $"../CombatWorld"


func _ready() -> void:
	Events.world_shifted.connect(_on_world_shifted)
	_apply(World.Id.PEACEFUL)


func _on_world_shifted(to: World.Id) -> void:
	_apply(to)


func _apply(to: World.Id) -> void:
	_set_world(_peaceful, to == World.Id.PEACEFUL)
	_set_world(_combat, to == World.Id.COMBAT)


func _set_world(world: Node2D, active: bool) -> void:
	world.visible = active
	world.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	# CanvasLayers do not inherit visibility.
	var background: CanvasLayer = world.get_node("Background") as CanvasLayer
	background.visible = active
