extends EnemyState
## Off balance after a parry: cannot attack or move for a moment.

var _time_left: float = 0.0


func enter(_data: Dictionary) -> void:
	_time_left = enemy.data.parry_stagger_duration
	enemy.model.play_action(&"hurt", _time_left)


func physics_update(delta: float) -> void:
	enemy.stop_moving(delta)
	_time_left -= delta
	if _time_left <= 0.0:
		state_machine.transition_to(&"Chase")
