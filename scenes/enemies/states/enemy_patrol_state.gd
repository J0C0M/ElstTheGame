extends EnemyState
## Walks to a random spot near home, then idles again. Chases on sight.

## Give up on a spot that takes longer than this to reach.
const MAX_WALK_TIME: float = 10.0

var _target: Vector3 = Vector3.ZERO
var _time: float = 0.0


func enter(_data: Dictionary) -> void:
	_time = 0.0
	var angle: float = randf() * TAU
	var distance: float = randf_range(0.4, 1.0) * enemy.data.patrol_radius
	_target = enemy.home + Vector3(cos(angle), 0.0, sin(angle)) * distance
	var map: RID = enemy.agent.get_navigation_map()
	var on_mesh: Vector3 = NavigationServer3D.map_get_closest_point(map, _target)
	if on_mesh != Vector3.ZERO:
		_target = on_mesh


func physics_update(delta: float) -> void:
	if enemy.player_detected:
		state_machine.transition_to(&"Chase")
		return
	_time += delta
	var to_target: Vector3 = _target - enemy.global_position
	to_target.y = 0.0
	if to_target.length() < 1.0 or _time > MAX_WALK_TIME:
		state_machine.transition_to(&"Idle")
		return
	enemy.move_towards(_target, enemy.data.walk_speed, delta)
