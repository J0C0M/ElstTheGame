extends PlayerState
## Walking, sprinting and jumping. The starting point for every other state.

## After stamina runs out, sprint stays off until Shift is released.
var _sprint_locked: bool = false


func enter(_data: Dictionary) -> void:
	player.is_sprinting = false


func exit() -> void:
	player.is_sprinting = false


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"jump") and player.is_on_floor():
		player.velocity.y = player.stats.jump_velocity
	elif event.is_action_pressed(&"interact"):
		player.interact()
	elif event.is_action_pressed(&"attack") and player.is_on_floor():
		state_machine.transition_to(&"Attack")
	elif event.is_action_pressed(&"block_aim") and player.is_on_floor():
		state_machine.transition_to(&"Block", {"fresh_press": true})
	elif event.is_action_pressed(&"dodge"):
		player.try_dodge(player.get_move_direction())
	else:
		for action: StringName in Player.TAP_DIRECTIONS:
			if event.is_action_pressed(action) and player.register_direction_tap(action):
				player.try_dodge(player.get_tap_direction(action))


func physics_update(delta: float) -> void:
	if Input.is_action_pressed(&"block_aim") and player.is_on_floor():
		# Still holding block after an attack, roll or stagger.
		state_machine.transition_to(&"Block")
		return
	var stats: PlayerStats = player.stats
	var direction: Vector3 = player.get_move_direction()
	if not Input.is_action_pressed(&"sprint"):
		_sprint_locked = false
	player.is_sprinting = (Input.is_action_pressed(&"sprint") and not _sprint_locked
		and direction.length_squared() > 0.01 and not player.stamina.is_empty())
	if player.is_sprinting:
		player.stamina.drain(stats.sprint_stamina_per_second * delta)
		if player.stamina.is_empty():
			_sprint_locked = true
			player.stamina.insufficient.emit()
	var speed: float = stats.sprint_speed if player.is_sprinting else stats.walk_speed
	var acceleration: float = stats.acceleration if player.is_on_floor() else stats.air_acceleration
	player.move_horizontally(direction, speed, acceleration, delta)
	player.turn_towards(direction, delta)
