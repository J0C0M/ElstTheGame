extends PlayerState
## Blocking with the sword: less damage from the front, and a parry when the
## block starts just before a hit lands. The player turns to face the camera
## and can still walk slowly.


func enter(data: Dictionary) -> void:
	player.is_blocking = true
	# Only a fresh press can parry, not a block held over from another state.
	player.block_started_at = player.clock if data.get("fresh_press", false) else -INF
	player.face_camera_direction()
	player.model.set_guard(true)


func exit() -> void:
	player.is_blocking = false
	player.model.set_guard(false)


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"dodge"):
		player.try_dodge(player.get_move_direction())


func physics_update(delta: float) -> void:
	if not Input.is_action_pressed(&"block_aim"):
		state_machine.transition_to(&"Move")
		return
	var stats: PlayerStats = player.stats
	player.move_horizontally(player.get_move_direction(), stats.block_move_speed, stats.acceleration, delta)
	player.turn_towards(-player.camera.get_yaw_basis().z, delta)
