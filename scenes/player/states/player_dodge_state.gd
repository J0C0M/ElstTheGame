extends PlayerState
## Dodge roll: a quick dash with a short window of invulnerability at the start.

var _direction: Vector3 = Vector3.ZERO
var _time: float = 0.0


func enter(data: Dictionary) -> void:
	_direction = data.get("direction", -player.get_forward())
	_time = 0.0
	player.is_invulnerable = true
	var backwards: bool = data.get("backwards", false)
	if not backwards:
		player.face_direction_now(_direction)
	player.model.play_action(&"roll_back" if backwards else &"roll_forward", player.stats.dodge_duration)
	AudioManager.play_sfx(&"dodge", -4.0)


func exit() -> void:
	player.is_invulnerable = false


func physics_update(delta: float) -> void:
	var stats: PlayerStats = player.stats
	_time += delta
	if _time >= stats.dodge_invulnerability:
		player.is_invulnerable = false
	# The speed falls off during the roll. 1.5 * (1 - p^2) averages to 1, so the
	# roll covers dodge_distance.
	var progress: float = clampf(_time / stats.dodge_duration, 0.0, 1.0)
	var speed: float = stats.dodge_distance / stats.dodge_duration * 1.5 * (1.0 - progress * progress)
	player.velocity.x = _direction.x * speed
	player.velocity.z = _direction.z * speed
	if _time >= stats.dodge_duration:
		state_machine.transition_to(&"Move")
