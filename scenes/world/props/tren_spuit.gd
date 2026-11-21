class_name TrenSpuit
extends Node3D
## The golden Tren syringe that Amber drops. It turns and glows on the floor;
## press E to pick it up, then use it on Klaas.

@export var found_flag: StringName = &"tren_spuit_found"

@onready var _interactable: Interactable = $Interactable
@onready var _visual: Node3D = $Visual


func _ready() -> void:
	if GameState.has_flag(found_flag):
		queue_free()
		return
	_interactable.interacted.connect(_on_interacted)


func _physics_process(delta: float) -> void:
	_visual.rotate_y(delta * 1.5)


func _on_interacted(_player: Player) -> void:
	GameState.set_flag(found_flag)
	EventBus.message_requested.emit("Je hebt de gouden Tren-spuit! Gebruik hem op Klaas.")
	queue_free()
