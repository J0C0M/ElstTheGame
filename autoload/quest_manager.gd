extends Node
## Loads quests from QuestData resources and tracks their status and current
## step, including factions beaten before Klaas handed out the quest. Built in
## Phase 6; saving and loading already go through here.


## Back to the start of a new game.
func reset() -> void:
	pass


func save_data() -> Dictionary:
	return {}


func load_data(_data: Dictionary) -> void:
	reset()
