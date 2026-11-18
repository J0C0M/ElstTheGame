class_name StateMachine
extends Node
## Runs one child State at a time. The owner calls physics_update() from its
## own _physics_process, so it can move the body after the state has run.
## Unhandled input goes to the current state automatically.

signal state_changed(state_name: StringName)

@export var initial_state: State

var current_state: State

var _states: Dictionary[StringName, State] = {}


func _ready() -> void:
	for child: Node in get_children():
		var state: State = child as State
		if state != null:
			state.state_machine = self
			_states[state.name] = state
	# Start once the owner is ready, so states can use its nodes in enter().
	await owner.ready
	current_state = initial_state
	current_state.enter({})


func _unhandled_input(event: InputEvent) -> void:
	if current_state != null:
		current_state.handle_input(event)


func physics_update(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)


func transition_to(state_name: StringName, data: Dictionary = {}) -> void:
	var next_state: State = _states.get(state_name)
	if next_state == null:
		push_error("StateMachine on %s has no state %s." % [owner.name, state_name])
		return
	if current_state != null:
		current_state.exit()
	current_state = next_state
	current_state.enter(data)
	state_changed.emit(state_name)


func get_state_name() -> StringName:
	return current_state.name if current_state != null else &""
