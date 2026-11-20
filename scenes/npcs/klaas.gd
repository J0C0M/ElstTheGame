class_name Klaas
extends StaticBody3D
## Klaas in his house: mentor, quest giver and shopkeeper. He turns to face
## the player when they come close and talks when they press E. He keeps
## moving while a conversation pauses the game. During Quest 6 he is not home
## but waits in the church, with his own conversation there.

## Klaas looks at the player within this distance.
const LOOK_RANGE: float = 7.0

@export var dialogue: DialogueData
## While this quest is active Klaas is away (he waits in the church).
@export var away_during_quest: StringName
## Shown while he is away, such as a note on the table.
@export var away_note_path: NodePath

@onready var _model: HumanoidModel = $Model
@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.interacted.connect(_on_interacted)
	var away: bool = not away_during_quest.is_empty() and QuestManager.get_status(away_during_quest) == QuestManager.Status.ACTIVE
	var note: Node3D = get_node_or_null(away_note_path) as Node3D
	if note != null:
		note.visible = away
	if away:
		queue_free()


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
