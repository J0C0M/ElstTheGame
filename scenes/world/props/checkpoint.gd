class_name Checkpoint
extends Area3D
## A safe spot halfway through a dungeon. The first time the player walks in
## during a visit, the game autosaves, so dying further on brings the player
## back here instead of to the dungeon entrance.

## What the player reads on arrival.
@export var message: String = "Checkpoint. Het spel is opgeslagen."

## A player who is already inside this soon after loading came from a save.
const LOAD_GRACE: float = 0.5

var _reached: bool = false
var _age: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_age += delta


func is_reached() -> bool:
	return _reached


func _on_body_entered(body: Node3D) -> void:
	if _reached or not body is Player:
		return
	_reached = true
	if _age < LOAD_GRACE:
		return
	EventBus.message_requested.emit(message)
	SaveManager.request_autosave()
