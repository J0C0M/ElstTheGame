class_name DungeonEntrance
extends Node3D
## A door to another scene: into a dungeon from Elst, or back out to Elst.
## The player presses E in front of it (on its -Z side). A locked door only
## shows a message. A door with [member unlocked_by_flag] stays locked until
## that GameState flag is set.

## Scene to load, for example res://scenes/dungeons/Station.tscn.
@export_file("*.tscn") var target_scene: String = ""
## Spawn point in the target scene where the player comes out.
@export var target_spawn: StringName = &""
@export var prompt: String = "Naar binnen"
@export var locked: bool = false
@export var locked_message: String = "Deze deur zit op slot."
## A GameState flag that unlocks the door, such as the destroyed station.
@export var unlocked_by_flag: StringName
@export var door_color: Color = Color(0.32, 0.2, 0.12)

@onready var _interactable: Interactable = $Interactable
@onready var _door: MeshInstance3D = $Frame/Door


func _ready() -> void:
	_interactable.prompt = prompt
	_interactable.interacted.connect(_on_interacted)
	var material: StandardMaterial3D = _door.get_active_material(0).duplicate()
	material.albedo_color = door_color
	_door.material_override = material


func is_locked() -> bool:
	return locked or not unlocked_by_flag.is_empty() and not GameState.has_flag(unlocked_by_flag)


func _on_interacted(_player: Player) -> void:
	if is_locked():
		EventBus.message_requested.emit(locked_message)
	else:
		EventBus.world_change_requested.emit(target_scene, target_spawn)
