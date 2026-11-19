class_name DialogueLine
extends Resource
## One thing a speaker says, with the player's choices after it.

@export var id: StringName
@export_multiline var text: String = ""
## Line that follows when there are no choices. Empty ends the conversation.
@export var next: StringName
@export var choices: Array[DialogueChoice] = []
## For start lines: only used when this holds.
@export var condition: DialogueCondition
## Runs when the line is shown, such as set_flag or raise_inwijding.
@export var action: StringName
@export var action_value: String = ""
## Animation for the speaker's model, such as flex.
@export var model_action: StringName


func get_available_choices() -> Array[DialogueChoice]:
	var available: Array[DialogueChoice] = []
	for choice: DialogueChoice in choices:
		if choice.is_available():
			available.append(choice)
	return available
