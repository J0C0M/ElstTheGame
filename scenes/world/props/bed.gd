extends StaticBody3D
## A place to rest: a bed, or a bench halfway through a dungeon. Resting heals
## the player and makes an autosave (Main does the work after
## EventBus.rest_requested).

## What the player reads after resting.
@export var rest_message: String = "Je hebt goed geslapen."


func _ready() -> void:
	($Interactable as Interactable).interacted.connect(func(_player: Player) -> void: EventBus.rest_requested.emit(rest_message))
