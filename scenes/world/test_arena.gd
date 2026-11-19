extends Node3D
## Test arena for Phase 1. Brings the player back a few seconds after dying;
## from Phase 3 on, dying loads the last save instead.

@export var respawn_delay: float = 3.0

@onready var _player: Player = $Player
@onready var _spawn: Marker3D = $PlayerSpawn


func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)


func _on_player_died() -> void:
	await get_tree().create_timer(respawn_delay).timeout
	_player.respawn(_spawn.global_transform)
