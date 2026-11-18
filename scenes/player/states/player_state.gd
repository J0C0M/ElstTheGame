class_name PlayerState
extends State
## Base for the player's states, with a typed reference to the player.

var player: Player


func _ready() -> void:
	player = owner as Player
