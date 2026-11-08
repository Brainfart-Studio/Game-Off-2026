extends GdUnitTestSuite

class FakeSource extends Object:
	signal ping()
	signal one(a: int)
	signal two(a: int, b: String)
	signal four(a: int, b: int, c: int, d: int)


var _source: FakeSource
var _calls: Array[Array] = []


func before_test() -> void:
	_source = auto_free(FakeSource.new())
	_calls.clear()


func _handler(event: StringName, args: Array) -> void:
	_calls.append([event, args])


func test_base_name() -> void:
	assert_str(String(EventRouter.base_name(&"world_shifted.combat"))).is_equal("world_shifted")
	assert_str(String(EventRouter.base_name(&"player_jumped"))).is_equal("player_jumped")
	assert_str(String(EventRouter.base_name(&"a.b.c"))).is_equal("a")


func test_zero_argument_signal_reaches_handler() -> void:
	EventRouter.connect_keys(_source, [&"ping"], _handler)
	_source.ping.emit()
	assert_int(_calls.size()).is_equal(1)
	assert_str(String(_calls[0][0])).is_equal("ping")
	assert_array(_calls[0][1]).is_empty()


func test_one_and_two_argument_signals_pass_args() -> void:
	EventRouter.connect_keys(_source, [&"one", &"two"], _handler)
	_source.one.emit(7)
	_source.two.emit(3, "x")
	assert_int(_calls.size()).is_equal(2)
	assert_array(_calls[0][1]).is_equal([7])
	assert_array(_calls[1][1]).is_equal([3, "x"])


func test_variant_keys_share_one_connection() -> void:
	EventRouter.connect_keys(_source, [&"one.a", &"one.b", &"one"], _handler)
	_source.one.emit(1)
	assert_int(_calls.size()).is_equal(1)
	assert_str(String(_calls[0][0])).is_equal("one")


func test_unknown_signal_errors_and_is_skipped() -> void:
	await assert_error(func() -> void: EventRouter.connect_keys(_source, [&"nope"], _handler)) \
		.is_push_error("EventRouter: no signal 'nope'")
	assert_int(_calls.size()).is_equal(0)


func test_signal_with_too_many_arguments_errors() -> void:
	await assert_error(func() -> void: EventRouter.connect_keys(_source, [&"four"], _handler)) \
		.is_push_error("EventRouter: signal 'four' has more than 3 arguments")
	assert_bool(_source.four.get_connections().is_empty()).is_true()


func test_world_event_looks_up_world_variant_first() -> void:
	var keys: Array[StringName] = EventRouter.lookup_keys(&"world_shift_started", [World.Id.COMBAT])
	assert_array(keys).is_equal([&"world_shift_started.combat", &"world_shift_started"])
	keys = EventRouter.lookup_keys(&"world_shifted", [World.Id.PEACEFUL])
	assert_array(keys).is_equal([&"world_shifted.peaceful", &"world_shifted"])


func test_other_events_look_up_only_their_name() -> void:
	assert_array(EventRouter.lookup_keys(&"player_jumped", [])).is_equal([&"player_jumped"])
	assert_array(EventRouter.lookup_keys(&"world_shifted", [])).is_equal([&"world_shifted"])
	assert_array(EventRouter.lookup_keys(&"shift_denied", [1])).is_equal([&"shift_denied"])
