class_name DialogueChoice
extends Resource
## An answer the player can pick in a conversation.

@export var text: String = ""
## Id of the line that follows. Empty ends the conversation.
@export var next: StringName
## Hidden unless this holds. Empty means always available.
@export var condition: DialogueCondition
## Runs when picked, such as set_flag, raise_inwijding, open_shop or sleep.
@export var action: StringName
@export var action_value: String = ""


func is_available() -> bool:
	return condition == null or condition.is_met()
