extends GdUnitTestSuite

const ECONOMY_SCENE: String = "res://scenes/economy/economy.tscn"
const WALKER_DATA: String = "res://config/enemies/walker.tres"

var _runner: GdUnitSceneRunner
var _root: Node2D
var _content: Node2D
var _economy: Economy
var _wallet: Array[int] = []


func before_test() -> void:
	Feedback.enabled = false
	_wallet.clear()
	_root = auto_free(Node2D.new())
	_content = Node2D.new()
	_root.add_child(_content)
	Game.register_content(World.Id.COMBAT, _content)
	Events.wallet_changed.connect(_on_wallet_changed)
	_runner = scene_runner(_root)
	_economy = (load(ECONOMY_SCENE) as PackedScene).instantiate() as Economy
	_root.add_child(_economy)


func after_test() -> void:
	Events.wallet_changed.disconnect(_on_wallet_changed)
	Feedback.enabled = true
	Game.reset()


func _on_wallet_changed(currency: int) -> void:
	_wallet.append(currency)


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


## Kills a walker that drops `drop` currency at `at`.
func _kill(drop: int, at: Vector2 = Vector2(50.0, 0.0)) -> void:
	var data: EnemyData = (load(WALKER_DATA) as EnemyData).duplicate() as EnemyData
	data.currency_drop = drop
	var enemy: Node2D = Node2D.new()
	enemy.position = at
	_root.add_child(enemy)
	Events.enemy_killed.emit(enemy, data, DamageInfo.new())
	enemy.queue_free()
	await _frames(2)


func _pickups() -> Array[Node]:
	return get_tree().get_nodes_in_group(Groups.PICKUP)


func _total(pickups: Array[Node]) -> int:
	var total: int = 0
	for pickup: Node in pickups:
		total += pickup.get(&"_amount") as int
	return total


func test_a_kill_drops_one_pickup_per_currency_under_combat_content() -> void:
	await _kill(3)
	var pickups: Array[Node] = _pickups()
	assert_int(pickups.size()).is_equal(3)
	assert_int(_total(pickups)).is_equal(3)
	for pickup: Node in pickups:
		assert_object(pickup.get_parent()).is_same(_content)


func test_a_large_drop_caps_the_pickup_count_and_keeps_the_total() -> void:
	await _kill(20)
	var pickups: Array[Node] = _pickups()
	assert_int(pickups.size()).is_equal(8)
	assert_int(_total(pickups)).is_equal(20)


func test_an_enemy_with_no_drop_leaves_nothing() -> void:
	await _kill(0)
	assert_int(_pickups().size()).is_equal(0)


func test_split_spreads_the_remainder_over_the_first_parts() -> void:
	assert_array(Economy.split_amount(20, 8)).is_equal([3, 3, 3, 3, 2, 2, 2, 2])
	assert_array(Economy.split_amount(3, 3)).is_equal([1, 1, 1])


func test_collected_currency_raises_the_wallet() -> void:
	assert_int(_economy.currency).is_equal(0)
	Events.currency_collected.emit(4)
	Events.currency_collected.emit(2)
	assert_int(_economy.currency).is_equal(6)
	assert_array(_wallet).is_equal([4, 6])


func test_the_wallet_is_announced_when_a_run_starts() -> void:
	Events.run_started.emit()
	assert_array(_wallet).is_equal([0])


func test_a_shift_frees_every_pickup() -> void:
	await _kill(3)
	assert_int(_pickups().size()).is_equal(3)
	Events.world_shift_started.emit(World.Id.PEACEFUL)
	await _frames(2)
	assert_int(_pickups().size()).is_equal(0)
