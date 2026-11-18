extends PlayerState
## The player is dead and waits until something calls Player.respawn().


func enter(_data: Dictionary) -> void:
	player.is_sprinting = false
	player.model.play_action(&"death", 1.0, true)


func physics_update(delta: float) -> void:
	player.move_horizontally(Vector3.ZERO, 0.0, player.stats.acceleration, delta)
