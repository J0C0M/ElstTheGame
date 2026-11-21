extends PlayerState
## Walking, sprinting and jumping. The starting point for every other state.

## After stamina runs out, sprint stays off until Shift is released.
var _sprint_locked: bool = false
var _step_distance: float = 0.0
var _was_on_floor: bool = true
var _fall_speed: float = 0.0


func enter(_data: Dictionary) -> void:
	player.is_sprinting = false


func exit() -> void:
	player.is_sprinting = false
	player.set_aiming(false)


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"jump") and player.is_on_floor():
		player.velocity.y = player.stats.jump_velocity
		AudioManager.play_sfx(&"jump", -8.0)
		EventBus.player_action.emit(&"jump")
	elif event.is_action_pressed(&"interact"):
		player.interact()
	elif event.is_action_pressed(&"use_potion") and player.is_on_floor():
		player.try_drink()
	elif event.is_action_pressed(&"weapon_sword"):
		player.select_weapon(&"sword")
	elif event.is_action_pressed(&"weapon_crossbow"):
		player.select_weapon(&"crossbow")
	elif event.is_action_pressed(&"attack") and player.weapon == &"crossbow":
		player.try_shoot()
	elif event.is_action_pressed(&"attack") and player.is_on_floor():
		if player.check_sword():
			state_machine.transition_to(&"Attack")
	elif event.is_action_pressed(&"block_aim") and player.is_on_floor() and player.weapon == &"sword":
		if player.check_sword():
			state_machine.transition_to(&"Block", {"fresh_press": true})
	elif event.is_action_pressed(&"dodge"):
		player.try_dodge(player.get_move_direction())
	else:
		for action: StringName in Player.TAP_DIRECTIONS:
			if event.is_action_pressed(action) and player.register_direction_tap(action):
				player.try_dodge(player.get_tap_direction(action))


func physics_update(delta: float) -> void:
	_play_steps(delta)
	player.set_aiming(player.weapon == &"crossbow" and Input.is_action_pressed(&"block_aim"))
	if player.aiming:
		player.face_camera_direction()
	elif Input.is_action_pressed(&"block_aim") and player.is_on_floor() and player.has_sword() and player.weapon == &"sword":
		# Still holding block after an attack, roll or stagger.
		state_machine.transition_to(&"Block")
		return
	var stats: PlayerStats = player.stats
	var direction: Vector3 = player.get_move_direction()
	if not Input.is_action_pressed(&"sprint"):
		_sprint_locked = false
	var was_sprinting: bool = player.is_sprinting
	player.is_sprinting = (Input.is_action_pressed(&"sprint") and not _sprint_locked
		and direction.length_squared() > 0.01 and not player.stamina.is_empty())
	if player.is_sprinting and not was_sprinting:
		EventBus.player_action.emit(&"sprint")
	if player.is_sprinting and not GameState.dev_powers:
		player.stamina.drain(stats.sprint_stamina_per_second * delta)
		if player.stamina.is_empty():
			_sprint_locked = true
			player.stamina.insufficient.emit()
	var speed: float = stats.sprint_speed if player.is_sprinting else stats.walk_speed
	if GameState.dev_powers:
		speed *= Player.DEV_SPEED_FACTOR
	var acceleration: float = stats.acceleration if player.is_on_floor() else stats.air_acceleration
	player.move_horizontally(direction, speed, acceleration, delta)
	player.turn_towards(direction, delta)


## Footsteps on the ground, closer together when sprinting, and a thud on
## landing after a fall.
func _play_steps(delta: float) -> void:
	var on_floor: bool = player.is_on_floor()
	if on_floor and not _was_on_floor and _fall_speed > 4.0:
		AudioManager.play_sfx(&"land", -6.0)
	_fall_speed = maxf(-player.velocity.y, 0.0) if not on_floor else 0.0
	_was_on_floor = on_floor
	var speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	if not on_floor or speed < 0.5:
		return
	_step_distance += speed * delta
	if _step_distance >= (2.4 if player.is_sprinting else 1.8):
		_step_distance = 0.0
		AudioManager.play_sfx(&"step", -14.0, 0.15)
