extends GdUnitTestSuite

const WALKER_DATA: String = "res://config/enemies/walker.tres"
const TIMEOUT_FRAMES: int = 240

class TargetConfig:
	extends GameConfig
	@export var max_health: int = 10

var _runner: GdUnitSceneRunner
var _root: Node2D
var _data: EnemyData
var _walker: Enemy
var _target: Node2D
var _spawned: Array[Node2D] = []
var _hits: Array[DamageInfo] = []
var _kills: Array[DamageInfo] = []
var _killed_data: Array[EnemyData] = []


func before_test() -> void:
	Feedback.enabled = false
	_root = auto_free(Node2D.new())
	_root.add_child(_solid(Vector2(0.0, 10.0), Vector2(1200.0, 20.0)))
	_root.add_child(_solid(Vector2(-100.0, -30.0), Vector2(10.0, 60.0)))
	_root.add_child(_solid(Vector2(100.0, -30.0), Vector2(10.0, 60.0)))
	_target = Node2D.new()
	_target.position = Vector2(400.0, 0.0)
	_root.add_child(_target)
	_data = (load(WALKER_DATA) as EnemyData).duplicate() as EnemyData
	_data.move_speed = 120.0
	_data.death_time = 0.1
	_spawned.clear()
	_hits.clear()
	_kills.clear()
	_killed_data.clear()
	Events.enemy_spawned.connect(_on_spawned)
	Events.hit_landed.connect(_on_hit)
	Events.enemy_killed.connect(_on_killed)
	_runner = scene_runner(_root)


func after_test() -> void:
	Events.enemy_spawned.disconnect(_on_spawned)
	Events.hit_landed.disconnect(_on_hit)
	Events.enemy_killed.disconnect(_on_killed)
	Feedback.enabled = true
	Game.reset()


func _on_spawned(enemy: Node2D) -> void:
	_spawned.append(enemy)


func _on_hit(info: DamageInfo) -> void:
	_hits.append(info)


func _on_killed(_enemy: Node2D, data: EnemyData, info: DamageInfo) -> void:
	_kills.append(info)
	_killed_data.append(data)


func _solid(at: Vector2, size: Vector2) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.collision_layer = Layers.WORLD
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	body.position = at
	return body


## Spawns the walker with `data` set before it enters the tree.
func _spawn(at: Vector2 = Vector2.ZERO) -> void:
	_walker = _data.scene.instantiate() as Enemy
	_walker.data = _data
	_walker.position = at
	_root.add_child(_walker)
	await _frames(2)


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


## Waits until `done` is true, up to TIMEOUT_FRAMES physics frames.
func _wait_for(done: Callable) -> void:
	var frames: int = 0
	while not done.call() and frames < TIMEOUT_FRAMES:
		await get_tree().physics_frame
		frames += 1


func _state() -> StringName:
	return _walker.machine.current.name


func _player_hit(damage: int, facing: int) -> Hitbox:
	var attacker: Node2D = Node2D.new()
	attacker.position = _walker.position
	var hitbox: Hitbox = Hitbox.new()
	hitbox.team = Team.Id.PLAYER
	attacker.add_child(hitbox)
	_root.add_child(attacker)
	var attack: AttackData = AttackData.new()
	attack.id = &"test_hit"
	attack.hitbox_size = Vector2(40.0, 24.0)
	attack.hitbox_offset = Vector2(0.0, -10.0)
	attack.knockback_force = 200.0
	attack.knockback_angle = -30.0
	hitbox.activate(attack, facing, damage)
	return hitbox


func test_spawn_announces_the_enemy_and_starts_patrolling() -> void:
	await _spawn()
	assert_int(_spawned.size()).is_equal(1)
	assert_object(_spawned[0]).is_same(_walker)
	assert_bool(_walker.is_in_group(Groups.ENEMY)).is_true()
	assert_int(_walker.health.current).is_equal(3)
	assert_str(_state()).is_equal("Patrol")


func test_patrol_turns_at_a_wall() -> void:
	await _spawn()
	assert_int(_walker.facing).is_equal(1)
	await _wait_for(func() -> bool: return _walker.facing == -1)
	assert_int(_walker.facing).is_equal(-1)
	assert_float(_walker.position.x).is_less(100.0)
	assert_str(_state()).is_equal("Patrol")


func test_chases_a_target_in_range_and_gives_up_beyond_lose_range() -> void:
	await _spawn()
	Game.player = _target
	_target.position = Vector2(-60.0, 0.0)
	await _wait_for(func() -> bool: return _state() == &"Chase")
	assert_str(_state()).is_equal("Chase")
	await _wait_for(func() -> bool: return _walker.position.x < -10.0)
	assert_int(_walker.facing).is_equal(-1)
	assert_float(_walker.position.x).is_less(-10.0)
	_target.position = Vector2(500.0, 0.0)
	await _wait_for(func() -> bool: return _state() == &"Patrol")
	assert_str(_state()).is_equal("Patrol")


func test_player_hit_lands_stuns_and_knocks_back() -> void:
	await _spawn()
	_player_hit(1, -1)
	await _wait_for(func() -> bool: return _state() == &"Hurt")
	assert_str(_state()).is_equal("Hurt")
	assert_int(_hits.size()).is_equal(1)
	assert_int(_hits[0].amount).is_equal(1)
	assert_int(_walker.health.current).is_equal(2)
	assert_float(_walker.velocity.x).is_less(0.0)
	assert_float(_walker.velocity.y).is_less(0.0)
	assert_int(_kills.size()).is_equal(0)
	await _wait_for(func() -> bool: return _state() != &"Hurt")
	assert_str(_state()).is_not_equal("Hurt")


func test_kill_emits_enemy_killed_disables_the_boxes_and_frees_after_death_time() -> void:
	await _spawn()
	_player_hit(3, 1)
	await _wait_for(func() -> bool: return _state() == &"Die")
	assert_str(_state()).is_equal("Die")
	assert_int(_kills.size()).is_equal(1)
	assert_object(_killed_data[0]).is_same(_data)
	assert_int(_kills[0].amount).is_equal(3)
	assert_bool(_walker.hurtbox.enabled).is_false()
	assert_bool(_walker.contact_hitbox.is_active()).is_false()
	assert_float(_walker.velocity.x).is_equal(0.0)
	await _wait_for(func() -> bool: return not is_instance_valid(_walker))
	assert_bool(is_instance_valid(_walker)).is_false()


func test_contact_hitbox_damages_a_player_hurtbox() -> void:
	await _spawn()
	var victim: Node2D = Node2D.new()
	var stats: Stats = Stats.new()
	stats.config = TargetConfig.new()
	victim.add_child(stats)
	var health: Health = Health.new()
	health.stats = stats
	victim.add_child(health)
	var hurtbox: Hurtbox = Hurtbox.new()
	hurtbox.team = Team.Id.PLAYER
	hurtbox.health = health
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(10.0, 10.0)
	shape.shape = rect
	hurtbox.add_child(shape)
	victim.add_child(hurtbox)
	victim.position = Vector2(0.0, -10.0)
	_root.add_child(victim)
	health.setup()
	await _wait_for(func() -> bool: return health.current < health.max_value)
	assert_int(health.current).is_equal(9)
