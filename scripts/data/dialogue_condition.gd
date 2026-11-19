class_name DialogueCondition
extends Resource
## When a dialogue line or choice is available: an Inwijding range and flags
## in GameState. Quest conditions arrive with the quest system (Phase 6).

@export var min_inwijding: int = 0
@export var max_inwijding: int = 6
## Only when this GameState flag is set. Empty means no check.
@export var required_flag: StringName
## Only when this GameState flag is not set. Empty means no check.
@export var forbidden_flag: StringName


func is_met() -> bool:
	if GameState.inwijding < min_inwijding or GameState.inwijding > max_inwijding:
		return false
	if not required_flag.is_empty() and not GameState.has_flag(required_flag):
		return false
	if not forbidden_flag.is_empty() and GameState.has_flag(forbidden_flag):
		return false
	return true
