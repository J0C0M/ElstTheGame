extends EnemyState
## A long jump in an arc, like a boze oma's: crouch, then leap at the player
## and attack straight after landing. With {"away": true} the enemy hops away
## from the player instead and waits a moment before it attacks again.

const CROUCH_TIME: float = 0.35
## The leap stops this far short of the player.
const LAND_SHORT: float = 1.3
## Seconds after a leap before the enemy may leap again.
const LEAP_COOLDOWN: float = 2.5

var _away: bool = false
var _time: float = 0.0
var _jumped: bool = false
var _horizontal: Vector3 = Vector3.ZERO


func enter(data: Dictionary) -> void:
	_away = data.get("away", false)
	_time = 0.0
	_jumped = false
	enemy.model.play_action(&"enemy_windup", CROUCH_TIME, true)


func physics_update(delta: float) -> void:
	var data: EnemyData = enemy.data
	_time += delta
	if not _jumped:
		enemy.stop_moving(delta)
		enemy.face_player(delta, 10.0)
		if _time >= CROUCH_TIME:
			_jump()
		return
	var flight: float = _time - CROUCH_TIME
	if flight < data.leap_time:
		enemy.velocity.x = _horizontal.x
		enemy.velocity.z = _horizontal.z
		return
	enemy.stop_moving(delta)
	enemy.face_player(delta)
	if not _away:
		enemy.patience_left = data.patience
		enemy.leap_cooldown_left = LEAP_COOLDOWN
		state_machine.transition_to(&"Attack")
	elif flight >= data.leap_time + data.hop_away_wait and enemy.is_on_floor():
		enemy.leap_cooldown_left = 0.0
		state_machine.transition_to(&"Chase")


func _jump() -> void:
	var data: EnemyData = enemy.data
	_jumped = true
	var player: Player = enemy.get_player()
	var target: Vector3 = enemy.global_position
	if player != null:
		var from_player: Vector3 = enemy.global_position - player.global_position
		from_player.y = 0.0
		target = player.global_position + from_player.normalized() * (data.hop_away_distance if _away else LAND_SHORT)
	var offset: Vector3 = target - enemy.global_position
	offset.y = 0.0
	_horizontal = offset / data.leap_time
	var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	enemy.velocity.y = gravity * data.leap_time * 0.5
	enemy.model.play_action(&"roll_forward" if not _away else &"roll_back", data.leap_time)
