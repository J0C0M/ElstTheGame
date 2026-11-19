class_name LocationArea
extends Area3D
## A named place in the world. Shows its name when the player walks in and
## remembers it as the current location, for the save files of Phase 3.

@export var id: StringName
## Name the player sees, for example "Westeraam Getho".
@export var display_name: String = ""


func _ready() -> void:
	collision_layer = 0
	collision_mask = PhysicsLayers.PLAYER
	monitorable = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		GameState.current_location = display_name
		EventBus.location_entered.emit(display_name)
		EventBus.area_entered.emit(id)
