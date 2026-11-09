class_name Economy
extends Node
## The run's currency. Killed enemies drop pickups under the combat content.

const PICKUP_SCENE: PackedScene = preload("res://scenes/economy/pickup.tscn")
## Where a drop appears, relative to the enemy's feet (px).
const DROP_OFFSET: Vector2 = Vector2(0, -12)

@export var config: EconomyConfig

## Currency collected so far this run.
var currency: int = 0


func _ready() -> void:
	config.check()
	currency = config.start_currency
	Events.enemy_killed.connect(_on_enemy_killed)
	Events.currency_collected.connect(_on_currency_collected)
	Events.run_started.connect(_on_run_started)
	Events.world_shift_started.connect(_on_world_shift_started)


## Splits `amount` into `count` parts that sum to `amount`. The remainder goes one each to the
## first parts.
static func split_amount(amount: int, count: int) -> Array[int]:
	var parts: Array[int] = []
	if count < 1:
		return parts
	var remainder: int = amount % count
	@warning_ignore("integer_division")
	var share: int = amount / count
	for i: int in count:
		parts.append(share + (1 if i < remainder else 0))
	return parts


func _on_enemy_killed(enemy: Node2D, data: EnemyData, _info: DamageInfo) -> void:
	if data == null or data.currency_drop <= 0 or not is_instance_valid(enemy):
		return
	_drop(enemy.global_position + DROP_OFFSET, data.currency_drop)


func _on_currency_collected(amount: int) -> void:
	currency += amount
	Events.wallet_changed.emit(currency)


func _on_run_started() -> void:
	Events.wallet_changed.emit(currency)


func _on_world_shift_started(_to: World.Id) -> void:
	for pickup: Node in get_tree().get_nodes_in_group(Groups.PICKUP):
		pickup.queue_free()


func _drop(at: Vector2, amount: int) -> void:
	var parent: Node2D = Game.content_parent(World.Id.COMBAT)
	if parent == null:
		return
	var count: int = clampi(amount, 1, config.max_pickups_per_drop)
	for part: int in split_amount(amount, count):
		var velocity: Vector2 = Vector2(
			randf_range(-config.pop_speed.x, config.pop_speed.x),
			randf_range(-config.pop_speed.y, -config.pop_speed.y / 2.0)
		)
		var pickup: Pickup = PICKUP_SCENE.instantiate() as Pickup
		pickup.setup(part, config, velocity)
		pickup.position = parent.to_local(at)
		# A kill can land inside a physics callback, where areas cannot be added yet.
		parent.add_child.call_deferred(pickup)
