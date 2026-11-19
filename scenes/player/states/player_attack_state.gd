extends PlayerState
## Sword attacks. A tap gives a light swing, and another tap during that swing
## chains the second swing of the combo. Holding the button gives a heavy
## attack, which costs stamina.

enum Swing { NONE, LIGHT_1, LIGHT_2, HEAVY }

const SWING_ACTIONS: Dictionary = {
	Swing.LIGHT_1: &"swing_light_1",
	Swing.LIGHT_2: &"swing_light_2",
	Swing.HEAVY: &"swing_heavy",
}

var _swing: Swing = Swing.NONE
var _time: float = 0.0
var _hold_time: float = 0.0
var _combo_queued: bool = false
var _hit_opened: bool = false
var _hit_closed: bool = false


func enter(_data: Dictionary) -> void:
	_swing = Swing.NONE
	_hold_time = 0.0
	_combo_queued = false
	player.face_camera_direction()
	player.model.play_action(&"attack_ready", player.stats.heavy_hold_time, true)


func exit() -> void:
	player.sword_hitbox.deactivate()


func handle_input(event: InputEvent) -> void:
	if _swing == Swing.NONE and event.is_action_released(&"attack"):
		_start_swing(Swing.LIGHT_1)
	elif (_swing == Swing.LIGHT_1 and event.is_action_pressed(&"attack")
			and _time >= player.stats.combo_input_open):
		_combo_queued = true


func physics_update(delta: float) -> void:
	var stats: PlayerStats = player.stats
	if _swing == Swing.NONE:
		# Wait to see whether this is a tap or a hold.
		player.move_horizontally(Vector3.ZERO, 0.0, stats.acceleration, delta)
		_hold_time += delta
		if not Input.is_action_pressed(&"attack"):
			_start_swing(Swing.LIGHT_1)
		elif _hold_time >= stats.heavy_hold_time:
			var can_heavy: bool = player.stamina.try_spend(stats.heavy_attack_stamina_cost)
			_start_swing(Swing.HEAVY if can_heavy else Swing.LIGHT_1)
		return
	_time += delta
	if not _hit_opened and _time >= _active_start():
		_hit_opened = true
		player.sword_hitbox.activate(player.get_sword_damage(_damage_multiplier()))
	if _hit_opened and not _hit_closed and _time >= _active_end():
		_hit_closed = true
		player.sword_hitbox.deactivate()
	var lunge: float = stats.attack_lunge_speed if _hit_opened and not _hit_closed else 0.0
	player.move_horizontally(player.get_forward(), lunge, stats.acceleration, delta)
	if _swing == Swing.LIGHT_1 and _combo_queued and _time >= stats.combo_chain_time:
		_start_swing(Swing.LIGHT_2)
	elif _time >= _duration():
		state_machine.transition_to(&"Move")


func _start_swing(swing: Swing) -> void:
	_swing = swing
	_time = 0.0
	_combo_queued = false
	_hit_opened = false
	_hit_closed = false
	player.sword_hitbox.deactivate()
	player.face_camera_direction()
	player.model.play_action(SWING_ACTIONS[swing], _duration())


func _duration() -> float:
	return player.stats.heavy_attack_duration if _swing == Swing.HEAVY else player.stats.light_attack_duration


func _active_start() -> float:
	return player.stats.heavy_attack_active_start if _swing == Swing.HEAVY else player.stats.light_attack_active_start


func _active_end() -> float:
	return player.stats.heavy_attack_active_end if _swing == Swing.HEAVY else player.stats.light_attack_active_end


func _damage_multiplier() -> float:
	match _swing:
		Swing.LIGHT_2:
			return player.stats.combo_damage_multiplier
		Swing.HEAVY:
			return player.stats.heavy_damage_multiplier
		_:
			return 1.0
