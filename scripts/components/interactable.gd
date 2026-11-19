class_name Interactable
extends Area3D
## Something the player can use with E: a door, a chest, a person. The player
## shows the prompt of the nearest one and calls interact() on E.

signal interacted(player: Player)

## Text after "[E]" on screen, for example "Station Elst binnengaan".
@export var prompt: String = ""
@export var enabled: bool = true


func _ready() -> void:
	collision_layer = PhysicsLayers.INTERACTION
	collision_mask = 0
	monitoring = false
	monitorable = true


func interact(player: Player) -> void:
	if enabled:
		interacted.emit(player)
