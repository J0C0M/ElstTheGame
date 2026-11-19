extends EnemyState
## One telegraphed attack: a windup the player can read, a short swing that
## can hit (or a projectile for ranged enemies), then a moment to recover.

const STRIKE_DURATION: float = 0.45
const RECOVER_TIME: float = 0.35

var _time: float = 0.0
var _swung: bool = false


func enter(_data: Dictionary) -> void:
	_time = 0.0
	_swung = false
	enemy.model.play_action(&"enemy_windup", enemy.data.attack_windup, true)


func exit() -> void:
	enemy.attack_hitbox.deactivate()


func physics_update(delta: float) -> void:
	var data: EnemyData = enemy.data
	_time += delta
	if not _swung:
		enemy.stop_moving(delta)
		enemy.face_player(delta, 6.0)
		if _time >= data.attack_windup:
			_swung = true
			if data.is_ranged():
				enemy.fire_projectile()
			else:
				enemy.attack_hitbox.activate(data.damage)
			enemy.model.play_action(data.attack_action, STRIKE_DURATION)
		return
	var swing_time: float = _time - data.attack_windup
	if swing_time < data.strike_time and not data.is_ranged():
		var forward: Vector3 = enemy.get_forward() * data.lunge_speed
		enemy.velocity.x = forward.x
		enemy.velocity.z = forward.z
	else:
		enemy.attack_hitbox.deactivate()
		enemy.stop_moving(delta)
	if swing_time >= STRIKE_DURATION + RECOVER_TIME:
		enemy.attack_cooldown_left = data.attack_cooldown
		state_machine.transition_to(&"Chase")
