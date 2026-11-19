class_name QuestMarker
extends Marker3D
## A spot the quest compass can point to. One marker can stand for several
## targets: the front door of Klaas' house stands for Klaas when the player is
## outside.

## Target ids (QuestStep.target) this marker stands for in this world.
@export var ids: Array[StringName] = []


func _ready() -> void:
	add_to_group(&"quest_markers")
