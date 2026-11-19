extends EnemyState
## Stands around for a moment, then goes on patrol. Chases on sight.

var _wait: float = 0.0


func enter(_data: Dictionary) -> void:
	enemy.aware = false
	_wait = randf_range(1.5, 3.5)


func physics_update(delta: float) -> void:
	enemy.stop_moving(delta)
	if enemy.player_detected:
		state_machine.transition_to(&"Chase")
		return
	_wait -= delta
	if _wait <= 0.0 and enemy.data.patrol_radius > 0.0:
		state_machine.transition_to(&"Patrol")
