extends GdUnitTestSuite

class RecordingState:
	extends State
	var log: Array[String] = []

	func enter(previous: StringName) -> void:
		log.append("enter:%s" % previous)

	func exit() -> void:
		log.append("exit")


var _owner: Node
var _machine: StateMachine
var _a: RecordingState
var _b: RecordingState


func before_test() -> void:
	_owner = auto_free(Node.new())
	_machine = StateMachine.new()
	_a = RecordingState.new()
	_a.name = &"A"
	_b = RecordingState.new()
	_b.name = &"B"
	_machine.add_child(_a)
	_machine.add_child(_b)
	_machine.initial_state = _a
	_owner.add_child(_machine)
	_machine.owner = _owner
	add_child(_owner)


func test_initial_state_entered_deferred() -> void:
	assert_array(_a.log).is_empty()
	await get_tree().process_frame
	assert_object(_machine.current).is_same(_a)
	assert_array(_a.log).is_equal(["enter:"])


func test_transition_calls_exit_then_enter_with_previous() -> void:
	await get_tree().process_frame
	_machine.transition_to(&"B")
	assert_array(_a.log).is_equal(["enter:", "exit"])
	assert_array(_b.log).is_equal(["enter:A"])
	assert_object(_machine.current).is_same(_b)


func test_transition_to_current_does_nothing() -> void:
	await get_tree().process_frame
	_machine.transition_to(&"A")
	assert_array(_a.log).is_equal(["enter:"])
	assert_object(_machine.current).is_same(_a)


func test_unknown_state_errors_and_keeps_current() -> void:
	await get_tree().process_frame
	await assert_error(func() -> void: _machine.transition_to(&"Nope")) \
		.is_push_error("StateMachine: unknown state 'Nope'")
	assert_object(_machine.current).is_same(_a)


func test_state_changed_emitted() -> void:
	var seen: Array = []
	_machine.state_changed.connect(func(from: StringName, to: StringName) -> void:
		seen.append([from, to]))
	await get_tree().process_frame
	_machine.transition_to(&"B")
	assert_array(seen).is_equal([[&"", &"A"], [&"A", &"B"]])
