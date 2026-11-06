extends GdUnitTestSuite

var _owner: Node
var _stats: Stats


func before_test() -> void:
	_owner = auto_free(Node.new())
	_stats = Stats.new()
	_stats.config = PlayerConfig.new()
	_owner.add_child(_stats)


func test_base_value() -> void:
	assert_float(_stats.value(&"run_speed")).is_equal(120.0)


func test_add_modifier() -> void:
	_stats.add_modifier(&"a", &"run_speed", 30.0)
	assert_float(_stats.value(&"run_speed")).is_equal(150.0)


func test_mult_modifier() -> void:
	_stats.add_modifier(&"a", &"run_speed", 0.0, 2.0)
	assert_float(_stats.value(&"run_speed")).is_equal(240.0)


func test_add_then_mult_order() -> void:
	_stats.add_modifier(&"a", &"run_speed", 30.0)
	_stats.add_modifier(&"b", &"run_speed", 0.0, 2.0)
	assert_float(_stats.value(&"run_speed")).is_equal(300.0)


func test_remove_by_source() -> void:
	_stats.add_modifier(&"a", &"run_speed", 30.0)
	_stats.add_modifier(&"b", &"run_speed", 0.0, 2.0)
	_stats.remove_modifiers(&"b")
	assert_float(_stats.value(&"run_speed")).is_equal(150.0)


func test_stats_changed_emits_owner() -> void:
	monitor_signals(Events, false)
	_stats.add_modifier(&"a", &"run_speed", 1.0)
	await assert_signal(Events).is_emitted("stats_changed", [_owner])
	_stats.remove_modifiers(&"a")
	await assert_signal(Events).is_emitted("stats_changed", [_owner])


func test_missing_stat_returns_zero() -> void:
	await assert_error(func() -> void: assert_float(_stats.value(&"nope")).is_equal(0.0)) \
		.is_push_error("Stats: 'nope' is not a number on ")


func test_non_numeric_stat_returns_zero() -> void:
	await assert_error(func() -> void: assert_float(_stats.value(&"analog_run")).is_equal(0.0)) \
		.is_push_error("Stats: 'analog_run' is not a number on ")
