class_name StateMachine
extends Node
## Node-based state machine. States are child nodes of type State, keyed by node name.
## The actor handed to each state is the `owner` of this machine.

signal state_changed(from: StringName, to: StringName)

@export var initial_state: State

var current: State

var _states: Dictionary[StringName, State] = {}


func _ready() -> void:
	for child: Node in get_children():
		if child is State:
			var state: State = child
			state.machine = self
			state.actor = owner
			_states[state.name] = state
	if initial_state != null:
		_enter_initial.call_deferred()


func _enter_initial() -> void:
	current = initial_state
	current.enter(&"")
	state_changed.emit(&"", current.name)


func transition_to(state_name: StringName) -> void:
	if not _states.has(state_name):
		push_error("StateMachine: unknown state '%s'" % state_name)
		return
	if current != null and current.name == state_name:
		return
	var previous: StringName = &""
	if current != null:
		previous = current.name
		current.exit()
	current = _states[state_name]
	current.enter(previous)
	state_changed.emit(previous, state_name)


func _process(delta: float) -> void:
	if current != null:
		current.update(delta)


func _physics_process(delta: float) -> void:
	if current != null:
		current.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current != null:
		current.handle_input(event)
