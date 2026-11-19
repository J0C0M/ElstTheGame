extends StaticBody3D
## A bed. Sleeping in it heals the player and makes an autosave (Main does
## the work after EventBus.sleep_requested).


func _ready() -> void:
	($Interactable as Interactable).interacted.connect(func(_player: Player) -> void: EventBus.sleep_requested.emit())
