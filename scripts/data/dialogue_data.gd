class_name DialogueData
extends Resource
## A conversation: lines and the choices between them. It opens with the
## first line in [member starts] whose condition holds.

@export var speaker: String = ""
## Ids of possible opening lines, most specific first.
@export var starts: Array[StringName] = []
@export var lines: Array[DialogueLine] = []


func get_line(id: StringName) -> DialogueLine:
	for line: DialogueLine in lines:
		if line.id == id:
			return line
	return null


func get_start() -> DialogueLine:
	for id: StringName in starts:
		var line: DialogueLine = get_line(id)
		if line != null and (line.condition == null or line.condition.is_met()):
			return line
	return null
