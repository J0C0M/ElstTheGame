extends SceneTree
## Headless gameplay test for the test arena: plays it with simulated input
## and checks movement, stamina, dodging, attacks, blocking, parrying, dying
## and respawning against the values in the data files.
## Run: godot --headless --path . --fixed-fps 60 -s res://tests/test_player_combat.gd
##
## The main script of -s is compiled before the autoloads exist, so project
## classes that use them (Player, TrainingDummy) are held in Variant here.

## TrainingDummy.Mode values.
const DUMMY_WINDUP: int = 1
const DUMMY_STAGGERED: int = 4
const DUMMY_BROKEN: int = 5

var _failures: int = 0
var _player: Variant
var _training: Variant
var _sparring: Variant


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var arena: Node = (load("res://scenes/world/TestArena.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	_player = arena.get_node("Player")
	_training = arena.get_node("TrainingDummy")
	_sparring = arena.get_node("SparringDummy")
	# Keep the sparring dummy out of reach until the blocking tests.
	_sparring.global_position = Vector3(15, 0, -15)
	await _frames(10)
	await _test_movement_and_stamina()
	await _test_dodge()
	await _test_attacks()
	await _test_block_and_parry()
	await _test_death_and_respawn()
	await _test_dev_powers()
	print("test_player_combat: %d failed" % _failures)
	quit(1 if _failures > 0 else 0)


func _test_movement_and_stamina() -> void:
	_teleport(Vector3(0, 0, 9))
	_act(&"move_forward", true)
	await _frames(60)
	_check(is_equal_approx(snappedf(_horizontal_speed(), 0.01), _player.stats.walk_speed), "walks at walk_speed")
	_act(&"sprint", true)
	await _frames(60)
	_check(is_equal_approx(snappedf(_horizontal_speed(), 0.01), _player.stats.sprint_speed), "sprints at sprint_speed")
	_check(absf(_player.stamina.current_stamina - 85.0) < 1.0, "sprinting 1 s costs 15 stamina")
	_act(&"sprint", false)
	_act(&"move_forward", false)
	var after_sprint: float = _player.stamina.current_stamina
	await _frames(30)
	_check(absf(_player.stamina.current_stamina - after_sprint) < 0.5, "no regen within 1 s")
	await _frames(60)
	_check(is_equal_approx(_player.stamina.current_stamina, 100.0), "stamina refills after the delay")
	var start_height: float = _player.global_position.y
	await _tap(&"jump", 1)
	var peak: float = start_height
	for i: int in 60:
		await physics_frame
		peak = maxf(peak, _player.global_position.y)
	_check(peak - start_height > 1.0 and peak - start_height < 1.6, "jumps about 1.2 m high")
	_check(_player.is_on_floor(), "lands again")


func _test_dodge() -> void:
	_teleport(Vector3(0, 0, 9))
	await _frames(5)
	var start: Vector3 = _player.global_position
	await _tap(&"dodge", 1)
	await _frames(2)
	_check(_player.state_machine.get_state_name() == &"Dodge", "Alt starts a dodge")
	_check(_player.is_invulnerable, "invulnerable at the start of the dodge")
	_check(is_equal_approx(_player.stamina.current_stamina, 80.0), "a dodge costs 20 stamina")
	await _frames(18)
	_check(not _player.is_invulnerable, "invulnerability ends after 0.3 s")
	await _frames(15)
	_check(_player.state_machine.get_state_name() == &"Move", "the dodge ends after 0.5 s")
	var distance: float = (_player.global_position - start).length()
	_check(distance > 3.8 and distance < 5.0, "a dodge covers about 4.5 m")
	await _frames(5)
	await _tap(&"move_left", 3)
	await _frames(4)
	await _tap(&"move_left", 3)
	_check(_player.state_machine.get_state_name() == &"Dodge", "double tap dodges")
	await _frames(40)


func _test_attacks() -> void:
	var dummy_health: Variant = _training.get_node("Health")
	await _refill()
	_teleport(Vector3(-3, 0, 1.6))
	await _tap(&"attack")
	await _frames(40)
	_check(dummy_health.current_health == 90, "a light swing does 10 damage")
	_teleport(Vector3(-3, 0, 1.6))
	await _tap(&"attack")
	await _frames(12)
	await _tap(&"attack")
	await _frames(60)
	_check(dummy_health.current_health == 67, "the combo does 10 + 13 damage")
	_teleport(Vector3(-3, 0, 1.6))
	_act(&"attack", true)
	await _frames(20)
	_check(is_equal_approx(_player.stamina.current_stamina, 75.0), "a heavy attack costs 25 stamina")
	_act(&"attack", false)
	await _frames(60)
	_check(dummy_health.current_health == 49, "a heavy attack does 18 damage")
	for i: int in 20:
		if dummy_health.is_dead():
			break
		_teleport(Vector3(-3, 0, 1.6))
		await _tap(&"attack")
		await _frames(40)
	_check(_training.get("_mode") == DUMMY_BROKEN, "the dummy breaks at 0 HP")
	await _frames(roundi(_training.respawn_delay * 60.0) + 10)
	_check(dummy_health.current_health == 100, "the dummy stands up again")


func _test_block_and_parry() -> void:
	_sparring.global_position = Vector3(3, 0, 0)
	_sparring.reset_physics_interpolation()
	await _refill()
	_teleport(Vector3(3, 0, 2.2))
	_act(&"block_aim", true)
	await _frames(10)
	var health_before: int = _player.health.current_health
	await _wait_for_hit()
	_check(_player.health.current_health == health_before - 3, "a block takes 70% off the damage")
	_check(absf(_player.stamina.current_stamina - 85.0) < 1.0, "a blocked hit costs 15 stamina")
	_act(&"block_aim", false)
	# Parry: press block shortly before the club comes down.
	for i: int in 400:
		await physics_frame
		if _sparring.get("_mode") == DUMMY_WINDUP and _sparring.get("_mode_time") >= _sparring.data.attack_windup - 0.1:
			break
	health_before = _player.health.current_health
	_act(&"block_aim", true)
	await _frames(20)
	_check(_player.health.current_health == health_before, "a parry takes no damage")
	_check(_sparring.get("_mode") == DUMMY_STAGGERED, "a parry staggers the attacker")
	_act(&"block_aim", false)
	await _frames(5)
	health_before = _player.health.current_health
	await _wait_for_hit()
	_check(_player.health.current_health == health_before - 10, "an unblocked hit does full damage")
	_check(_player.state_machine.get_state_name() == &"Hurt", "an unblocked hit staggers the player")
	_sparring.global_position = Vector3(15, 0, -15)


func _test_death_and_respawn() -> void:
	await _frames(30)
	_player.health.take_damage(_player.health.current_health)
	await _frames(2)
	_check(_player.state_machine.get_state_name() == &"Dead", "the player dies at 0 HP")
	await _frames(200)
	_check(_player.health.current_health == 100, "the player respawns with full health")
	_check(_player.state_machine.get_state_name() == &"Move", "the player can move again")
	_check(_player.global_position.distance_to(Vector3(0, 0, 9)) < 0.5, "the player respawns at the spawn point")


func _test_dev_powers() -> void:
	var state: Variant = root.get_node("GameState")
	state.set_dev_powers(true)
	await _refill()
	_teleport(Vector3(0, 0, 9))
	_act(&"move_forward", true)
	await _frames(60)
	_check(_horizontal_speed() > _player.stats.walk_speed * 2.5, "dev powers: much faster (%.1f m/s)" % _horizontal_speed())
	_act(&"move_forward", false)
	_act(&"jump", true)
	await _frames(60)
	_act(&"jump", false)
	var height: float = _player.global_position.y
	await _frames(30)
	_check(height > 3.0 and absf(_player.global_position.y - height) < 0.3, "dev powers: fly up with Space and hover (%.1f, %.1f)" % [height, _player.global_position.y])
	_act(&"dev_fly_down", true)
	await _frames(120)
	_act(&"dev_fly_down", false)
	_check(_player.global_position.y < 0.5, "dev powers: fly down with Ctrl")
	var health_before: int = _player.health.current_health
	_player.get_node("Hurtbox").receive_hit(load("res://scripts/components/hit_data.gd").new(10, _sparring, null))
	_check(_player.health.current_health == health_before, "dev powers: no damage")
	_teleport(Vector3(-3, 0, 1.6))
	await _tap(&"attack")
	await _frames(30)
	_check(_training.get("_mode") == DUMMY_BROKEN, "dev powers: one hit kills")
	state.set_dev_powers(false)


func _wait_for_hit() -> void:
	var health_before: int = _player.health.current_health
	for i: int in 400:
		await physics_frame
		if _player.health.current_health != health_before:
			return


func _refill() -> void:
	await _frames(5)
	_player.stamina.refill()


func _teleport(position: Vector3) -> void:
	_player.global_position = position
	_player.rotation.y = 0.0
	_player.camera.yaw = 0.0
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()


func _horizontal_speed() -> float:
	return Vector2(_player.velocity.x, _player.velocity.z).length()


func _frames(count: int) -> void:
	for i: int in count:
		await physics_frame


func _act(action: StringName, pressed: bool) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _tap(action: StringName, hold_frames: int = 3) -> void:
	_act(action, true)
	await _frames(hold_frames)
	_act(action, false)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS ", description)
	else:
		_failures += 1
		printerr("FAIL ", description)
