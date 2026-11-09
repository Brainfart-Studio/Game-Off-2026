extends GdUnitTestSuite


class HealthTestConfig:
	extends GameConfig
	@export var max_health: int = 3
	@export var iframes: float = 0.2


var _owner: Node
var _stats: Stats
var _health: Health
var _died_count: int = 0
var _changes: Array[Vector2i] = []


func before_test() -> void:
	_owner = auto_free(Node.new())
	_stats = Stats.new()
	_stats.config = HealthTestConfig.new()
	_owner.add_child(_stats)
	_health = Health.new()
	_health.stats = _stats
	_health.iframes_stat = &"iframes"
	_owner.add_child(_health)
	add_child(_owner)
	_died_count = 0
	_changes.clear()
	_health.died.connect(func(_info: DamageInfo) -> void: _died_count += 1)
	_health.changed.connect(func(current: int, max_value: int) -> void: _changes.append(Vector2i(current, max_value)))
	_health.setup()


func _hit(amount: int = 1) -> DamageInfo:
	var info: DamageInfo = DamageInfo.new()
	info.amount = amount
	return info


func test_setup_fills_health_from_stats() -> void:
	assert_int(_health.current).is_equal(3)
	assert_int(_health.max_value).is_equal(3)
	assert_array(_changes).is_equal([Vector2i(3, 3)])


func test_damage_lowers_current_and_emits_changed_then_damaged() -> void:
	var order: Array[String] = []
	_health.changed.connect(func(_c: int, _m: int) -> void: order.append("changed"))
	_health.damaged.connect(func(_i: DamageInfo) -> void: order.append("damaged"))
	assert_bool(_health.damage(_hit())).is_true()
	assert_int(_health.current).is_equal(2)
	assert_array(order).is_equal(["changed", "damaged"])


func test_damage_with_no_amount_is_refused() -> void:
	assert_bool(_health.damage(_hit(0))).is_false()
	assert_bool(_health.damage(_hit(-2))).is_false()
	assert_int(_health.current).is_equal(3)


func test_damage_clamps_at_zero_and_died_fires_once() -> void:
	assert_bool(_health.damage(_hit(10))).is_true()
	assert_int(_health.current).is_equal(0)
	assert_bool(_health.is_dead()).is_true()
	assert_int(_died_count).is_equal(1)
	assert_bool(_health.damage(_hit(1))).is_false()
	assert_int(_died_count).is_equal(1)


func test_invulnerability_blocks_hits_then_expires() -> void:
	assert_bool(_health.damage(_hit())).is_true()
	assert_bool(_health.is_invulnerable()).is_true()
	assert_bool(_health.damage(_hit())).is_false()
	assert_int(_health.current).is_equal(2)
	_health._physics_process(0.1)
	assert_bool(_health.is_invulnerable()).is_true()
	_health._physics_process(0.15)
	assert_bool(_health.is_invulnerable()).is_false()
	assert_float(_health.invulnerable_left).is_equal(0.0)
	assert_bool(_health.damage(_hit())).is_true()
	assert_int(_health.current).is_equal(1)


func test_no_iframes_stat_means_no_invulnerability() -> void:
	_health.iframes_stat = &""
	assert_bool(_health.damage(_hit())).is_true()
	assert_bool(_health.is_invulnerable()).is_false()
	assert_bool(_health.damage(_hit())).is_true()
	assert_int(_health.current).is_equal(1)


func test_heal_clamps_at_max_and_emits_healed() -> void:
	var healed: Array[int] = []
	_health.healed.connect(func(amount: int) -> void: healed.append(amount))
	_health.damage(_hit(2))
	_health.heal(5)
	assert_int(_health.current).is_equal(3)
	assert_array(healed).is_equal([2])
	_health.heal(1)
	assert_array(healed).is_equal([2])


func test_heal_does_not_revive() -> void:
	_health.damage(_hit(3))
	_health.heal(2)
	assert_int(_health.current).is_equal(0)


func test_raising_max_with_a_modifier_raises_current() -> void:
	_health.damage(_hit(1))
	_stats.add_modifier(&"buff", &"max_health", 2.0)
	assert_int(_health.max_value).is_equal(5)
	assert_int(_health.current).is_equal(4)
	_stats.remove_modifiers(&"buff")
	assert_int(_health.max_value).is_equal(3)
	assert_int(_health.current).is_equal(3)


func test_stats_changed_for_another_owner_is_ignored() -> void:
	Events.stats_changed.emit(auto_free(Node.new()))
	assert_int(_health.max_value).is_equal(3)
