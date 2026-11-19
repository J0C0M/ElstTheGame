class_name State
extends Node
## One state of a StateMachine. Override the methods you need.

var state_machine: StateMachine


## Called when the machine switches to this state. [param data] carries
## optional values from the previous state, such as a direction.
func enter(_data: Dictionary) -> void:
	pass


func exit() -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
