extends GdUnitTestSuite

var _runner: GdUnitSceneRunner
var _root: Node2D
var _player: Player
var _contact: Hitbox
var _damaged: Array[DamageInfo] = []
var _deaths: int = 0
var _health_events: Array[Vector2i] = []


func before_test() -> void:
	Feedback.enabled = false
	_root = auto_free(Node2D.new())
	var floor_body: StaticBody2D = StaticBody2D.new()
	floor_body.collision_layer = Layers.WORLD
	var floor_shape: CollisionShape2D = CollisionShape2D.new()
	var floor_rect: RectangleShape2D = RectangleShape2D.new()
	floor_rect.size = Vector2(1200.0, 20.0)
	floor_shape.shape = floor_rect
	floor_body.add_child(floor_shape)
	floor_body.position = Vector2(0.0, 10.0)
	_root.add_child(floor_body)
	_player = (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	_player.position = Vector2(0.0, -2.0)
	_root.add_child(_player)
	# An enemy to the left of the player whose contact box covers a wide area, so the player
	# stays inside it after being knocked back.
	var enemy: Node2D = Node2D.new()
	enemy.position = Vector2(-8.0, 0.0)
	_contact = Hitbox.new()
	_contact.team = Team.Id.ENEMY
	enemy.add_child(_contact)
	_root.add_child(enemy)
	_damaged.clear()
	_deaths = 0
	_health_events.clear()
	Events.player_damaged.connect(_on_damaged)
	Events.player_died.connect(_on_died)
	Events.player_health_changed.connect(_on_health_changed)
	_runner = scene_runner(_root)


func after_test() -> void:
	Events.player_damaged.disconnect(_on_damaged)
	Events.player_died.disconnect(_on_died)
	Events.player_health_changed.disconnect(_on_health_changed)
	Feedback.enabled = true
	Game.reset()


func _on_damaged(info: DamageInfo) -> void:
	_damaged.append(info)


func _on_died() -> void:
	_deaths += 1


func _on_health_changed(current: int, max_health: int) -> void:
	_health_events.append(Vector2i(current, max_health))


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _state() -> StringName:
	return _player.machine.current.name


func _start_contact() -> void:
	_contact.set_contact(Vector2(300.0, 40.0), Vector2(0.0, -10.0), 1, 200.0, -30.0)


func test_contact_hit_damages_stuns_and_knocks_the_player_away() -> void:
	await _frames(30)
	_start_contact()
	await _frames(2)
	assert_int(_damaged.size()).is_equal(1)
	assert_str(String(_state())).is_equal("Hurt")
	assert_int(_player.health.current).is_equal(2)
	assert_float(_player.last_hit.knockback.x).is_greater(0.0)
	assert_float(_player.velocity.x).is_greater(0.0)


func test_further_hits_are_blocked_while_invulnerable() -> void:
	await _frames(30)
	_start_contact()
	await _frames(30)
	assert_int(_damaged.size()).is_equal(1)
	assert_int(_player.health.current).is_equal(2)
	assert_bool(_player.health.is_invulnerable()).is_true()


func test_stun_ends_in_idle_or_fall() -> void:
	await _frames(30)
	_start_contact()
	await _frames(1)
	_contact.deactivate()
	await _frames(40)
	assert_str(String(_state())).is_not_equal("Hurt")


func test_three_hits_kill_the_player() -> void:
	var config: PlayerConfig = (_player.stats.config as PlayerConfig).duplicate() as PlayerConfig
	config.hurt_iframes = 0.05
	_player.stats.config = config
	_player.config = config
	await _frames(30)
	_start_contact()
	await _frames(40)
	assert_str(String(_state())).is_equal("Dead")
	assert_int(_deaths).is_equal(1)
	assert_int(_damaged.size()).is_equal(3)
	assert_int(_player.health.current).is_equal(0)
	assert_array(_health_events).is_equal([Vector2i(2, 3), Vector2i(1, 3), Vector2i(0, 3)])
	assert_bool(_player.hurtbox.enabled).is_false()
