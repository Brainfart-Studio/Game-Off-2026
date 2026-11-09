extends GdUnitTestSuite


class HitboxTestConfig:
	extends GameConfig
	@export var max_health: int = 10
	@export var iframes: float = 0.2


var _runner: GdUnitSceneRunner
var _root: Node2D
var _attacker: Node2D
var _hitbox: Hitbox
var _target: Node2D
var _health: Health
var _hurtbox: Hurtbox
var _landed: Array[DamageInfo] = []


func before_test() -> void:
	Feedback.enabled = false
	_root = auto_free(Node2D.new())
	_attacker = Node2D.new()
	_hitbox = Hitbox.new()
	_hitbox.team = Team.Id.PLAYER
	_attacker.add_child(_hitbox)
	_root.add_child(_attacker)
	_landed.clear()
	_hitbox.landed.connect(func(info: DamageInfo) -> void: _landed.append(info))
	_runner = scene_runner(_root)


func after_test() -> void:
	Feedback.enabled = true
	Game.reset()


## Puts a target with health and a hurtbox at `at`, with or without invulnerability after a hit.
func _spawn_target(team: Team.Id, at: Vector2, with_iframes: bool = false) -> void:
	_target = Node2D.new()
	_target.position = at
	var stats: Stats = Stats.new()
	stats.config = HitboxTestConfig.new()
	_target.add_child(stats)
	_health = Health.new()
	_health.stats = stats
	if with_iframes:
		_health.iframes_stat = &"iframes"
	_target.add_child(_health)
	_hurtbox = Hurtbox.new()
	_hurtbox.team = team
	_hurtbox.health = _health
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	shape.shape = rect
	_hurtbox.add_child(shape)
	_target.add_child(_hurtbox)
	_root.add_child(_target)
	_health.setup()


func _attack() -> AttackData:
	var data: AttackData = AttackData.new()
	data.id = &"slash"
	data.damage = 2
	return data


func _physics_frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func test_attack_hits_once_per_activation() -> void:
	_spawn_target(Team.Id.ENEMY, Vector2(16, -12))
	_hitbox.activate(_attack(), 1, 2)
	await _physics_frames(6)
	assert_int(_landed.size()).is_equal(1)
	assert_int(_health.current).is_equal(8)


func test_second_activation_hits_again() -> void:
	_spawn_target(Team.Id.ENEMY, Vector2(16, -12))
	_hitbox.activate(_attack(), 1, 2)
	await _physics_frames(6)
	_hitbox.deactivate()
	await _physics_frames(2)
	_hitbox.activate(_attack(), 1, 2)
	await _physics_frames(6)
	assert_int(_landed.size()).is_equal(2)
	assert_int(_health.current).is_equal(6)


func test_landed_carries_the_damage_info() -> void:
	_spawn_target(Team.Id.ENEMY, Vector2(16, -12))
	var data: AttackData = _attack()
	data.tags = [&"fire"]
	_hitbox.activate(data, 1, 3)
	await _physics_frames(6)
	assert_int(_landed.size()).is_equal(1)
	var info: DamageInfo = _landed[0]
	assert_int(info.amount).is_equal(3)
	assert_str(String(info.attack_id)).is_equal("slash")
	assert_str(String(info.feedback)).is_equal("hit_light")
	assert_str(String(info.sound)).is_equal("hit_enemy")
	assert_array(info.tags).is_equal([&"fire"])
	assert_object(info.source).is_same(_attacker)
	assert_object(info.target).is_same(_target)
	assert_vector(info.position).is_equal_approx(Vector2(16, -12), Vector2(1, 1))


func test_knockback_x_sign_follows_facing() -> void:
	_spawn_target(Team.Id.ENEMY, Vector2(16, -12))
	_hitbox.activate(_attack(), 1, 2)
	await _physics_frames(6)
	assert_float(_landed[0].knockback.x).is_greater(0.0)
	assert_float(_landed[0].knockback.y).is_less(0.0)
	_hitbox.deactivate()
	_target.position = Vector2(-16, -12)
	_health.setup()
	await _physics_frames(2)
	_landed.clear()
	_hitbox.activate(_attack(), -1, 2)
	await _physics_frames(6)
	assert_int(_landed.size()).is_equal(1)
	assert_float(_landed[0].knockback.x).is_less(0.0)
	assert_float(_landed[0].knockback.y).is_less(0.0)


func test_contact_hits_again_only_after_invulnerability() -> void:
	_spawn_target(Team.Id.ENEMY, Vector2(0, -8), true)
	_hitbox.set_contact(Vector2(16, 16), Vector2(0, -8), 1, 100.0, -45.0)
	await _physics_frames(6)
	assert_int(_health.current).is_equal(9)
	assert_int(_landed.size()).is_equal(1)
	await _physics_frames(30)
	assert_int(_health.current).is_less(9)
	assert_int(_landed.size()).is_greater(1)


func test_contact_knockback_points_away_from_the_hitbox() -> void:
	_spawn_target(Team.Id.ENEMY, Vector2(-6, -8))
	_hitbox.set_contact(Vector2(16, 16), Vector2(0, -8), 1, 100.0, -45.0)
	await _physics_frames(6)
	assert_float(_landed[0].knockback.x).is_less(0.0)
	assert_float(_landed[0].knockback.y).is_less(0.0)


func test_player_hitbox_ignores_a_player_hurtbox() -> void:
	_spawn_target(Team.Id.PLAYER, Vector2(16, -12))
	_hitbox.activate(_attack(), 1, 2)
	await _physics_frames(6)
	assert_int(_landed.size()).is_equal(0)
	assert_int(_health.current).is_equal(10)


func test_deactivated_hitbox_hits_nothing() -> void:
	_spawn_target(Team.Id.ENEMY, Vector2(16, -12))
	_hitbox.activate(_attack(), 1, 2)
	_hitbox.deactivate()
	await _physics_frames(6)
	assert_int(_landed.size()).is_equal(0)


func test_disabled_hurtbox_refuses_hits() -> void:
	_spawn_target(Team.Id.ENEMY, Vector2(16, -12))
	_hurtbox.enabled = false
	_hitbox.activate(_attack(), 1, 2)
	await _physics_frames(6)
	assert_int(_landed.size()).is_equal(0)
	assert_int(_health.current).is_equal(10)
