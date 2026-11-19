extends PlayerState
## Staggered after a hit or a broken guard: no control for a moment.

var _time_left: float = 0.0


func enter(data: Dictionary) -> void:
	_time_left = data.get("duration", player.stats.hurt_duration)
	player.model.play_action(&"hurt", _time_left)


func physics_update(delta: float) -> void:
	player.move_horizontally(Vector3.ZERO, 0.0, player.stats.acceleration * 0.5, delta)
	_time_left -= delta
	if _time_left <= 0.0:
		state_machine.transition_to(&"Move")
