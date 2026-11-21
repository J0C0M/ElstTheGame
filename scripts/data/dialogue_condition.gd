class_name DialogueCondition
extends Resource
## When a dialogue line or choice is available: an Inwijding range, flags in
## GameState and the state of a quest.

@export var min_inwijding: int = 0
@export var max_inwijding: int = 6
## Only when this GameState flag is set. Empty means no check.
@export var required_flag: StringName
## Only when this GameState flag is not set. Empty means no check.
@export var forbidden_flag: StringName
## Quest to check. Empty means no quest check.
@export var quest_id: StringName
## Required QuestManager.Status of [member quest_id]: 0 not started, 1 active,
## 2 completed. -1 means any.
@export var quest_status: int = -1
## Only while the quest's current step has this id. Empty means any step.
@export var quest_step: StringName


func is_met() -> bool:
	if GameState.inwijding < min_inwijding or GameState.inwijding > max_inwijding:
		return false
	if not required_flag.is_empty() and not GameState.has_flag(required_flag):
		return false
	if not forbidden_flag.is_empty() and GameState.has_flag(forbidden_flag):
		return false
	if not quest_id.is_empty():
		if quest_status >= 0 and QuestManager.get_status(quest_id) != quest_status:
			return false
		if not quest_step.is_empty():
			var step: QuestStep = QuestManager.get_current_step(quest_id)
			if step == null or step.id != quest_step:
				return false
	return true
