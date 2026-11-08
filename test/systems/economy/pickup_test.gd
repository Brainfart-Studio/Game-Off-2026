extends GdUnitTestSuite

const CONFIG_PATH: String = "res://config/economy/economy_config.tres"
const PICKUP_SCENE: String = "res://scenes/economy/pickup.tscn"
const TIMEOUT_FRAMES: int = 240

var _runner: GdUnitSceneRunner
var _root: Node2D
var _collected: Array[int] = []


func before_test() -> void:
	_collected.clear()
	_root = auto_free(Node2D.new())
	Events.currency_collected.connect(_on_collected)
	_runner = scene_runner(_root)


func after_test() -> void:
	Events.currency_collected.disconnect(_on_collected)


func _on_collected(amount: int) -> void:
	_collected.append(amount)


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _config(delay: float, lifetime: float) -> EconomyConfig:
	var cfg: EconomyConfig = (load(CONFIG_PATH) as EconomyConfig).duplicate() as EconomyConfig
	cfg.pickup_delay = delay
	cfg.lifetime = lifetime
	cfg.blink_time = minf(cfg.blink_time, lifetime)
	return cfg


## A pickup worth `amount` at `at`, standing still.
func _pickup(cfg: EconomyConfig, at: Vector2, amount: int = 5) -> Pickup:
	var pickup: Pickup = (load(PICKUP_SCENE) as PackedScene).instantiate() as Pickup
	pickup.setup(amount, cfg, Vector2.ZERO)
	pickup.position = at
	_root.add_child(pickup)
	return pickup


## A magnet like the player's: on the player layer, seen by pickups, never looking itself.
func _magnet(at: Vector2, radius: float) -> Area2D:
	var magnet: Area2D = Area2D.new()
	magnet.collision_layer = Layers.PLAYER
	magnet.collision_mask = 0
	magnet.monitoring = false
	magnet.add_to_group(Groups.MAGNET)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	magnet.add_child(shape)
	magnet.position = at
	_root.add_child(magnet)
	return magnet


func test_no_attraction_before_the_delay() -> void:
	var pickup: Pickup = _pickup(_config(5.0, 20.0), Vector2(20.0, 0.0))
	_magnet(Vector2.ZERO, 40.0)
	await _frames(20)
	assert_vector(pickup.position).is_equal(Vector2(20.0, 0.0))
	assert_array(_collected).is_empty()


func test_a_magnet_pulls_a_pickup_in_and_it_collects_once() -> void:
	var pickup: Pickup = _pickup(_config(0.05, 20.0), Vector2(20.0, 0.0), 5)
	_magnet(Vector2.ZERO, 40.0)
	var frames: int = 0
	while _collected.is_empty() and frames < TIMEOUT_FRAMES:
		await get_tree().physics_frame
		frames += 1
	assert_array(_collected).is_equal([5])
	await _frames(5)
	assert_array(_collected).is_equal([5])
	assert_bool(is_instance_valid(pickup) and not pickup.is_queued_for_deletion()).is_false()


func test_touching_the_player_body_collects() -> void:
	var cfg: EconomyConfig = _config(0.05, 20.0)
	var body: CharacterBody2D = CharacterBody2D.new()
	body.collision_layer = Layers.PLAYER
	body.add_to_group(Groups.PLAYER)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(12.0, 22.0)
	shape.shape = rect
	body.add_child(shape)
	_root.add_child(body)
	_pickup(cfg, Vector2.ZERO, 2)
	var frames: int = 0
	while _collected.is_empty() and frames < TIMEOUT_FRAMES:
		await get_tree().physics_frame
		frames += 1
	assert_array(_collected).is_equal([2])


func test_an_uncollected_pickup_frees_at_its_lifetime() -> void:
	var pickup: Pickup = _pickup(_config(0.05, 0.2), Vector2(200.0, 0.0))
	await _frames(5)
	assert_bool(is_instance_valid(pickup)).is_true()
	await _frames(30)
	assert_bool(is_instance_valid(pickup)).is_false()
	assert_array(_collected).is_empty()
