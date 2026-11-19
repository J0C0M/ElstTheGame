class_name Klaas
extends StaticBody3D
## Klaas in his house: mentor, quest giver and shopkeeper. He turns to face
## the player when they come close and talks when they press E. He keeps
## moving while a conversation pauses the game.

## Klaas looks at the player within this distance.
const LOOK_RANGE: float = 7.0

@export var dialogue: DialogueData

@onready var _model: HumanoidModel = $Model
@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.interacted.connect(_on_interacted)


func _physics_process(delta: float) -> void:
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	if player == null:
		return
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() > LOOK_RANGE or to_player.length() < 0.1:
		return
	var target_yaw: float = atan2(-to_player.x, -to_player.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-4.0 * delta))


## Plays an animation on Klaas' model; used by the dialogue box.
func play_model_action(action: StringName) -> void:
	_model.play_action(action, 1.4)


func _on_interacted(_player: Player) -> void:
	EventBus.dialogue_requested.emit(dialogue, self)
