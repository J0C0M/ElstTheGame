extends EnemyState
## Runs at the player and attacks when close. Flankers circle round to the
## player's side first; ranged enemies keep their distance. Gives up when
## the player gets away or the chase leads
## too far from home (further while it hunts the player who hit it).

## Seconds without noticing the player before the enemy gives up.
const LOSE_TIME: float = 5.0
## Flankers go straight in once this close.
const FLANK_DISTANCE: float = 4.0


func enter(_data: Dictionary) -> void:
	enemy.aware = true
	enemy.time_since_seen = 0.0
	if not enemy.pack_warned:
		enemy.alert_pack()


func physics_update(delta: float) -> void:
	var player: Player = enemy.get_player()
	if player == null or player.health.is_dead() or enemy.time_since_seen > LOSE_TIME \
			or enemy.global_position.distance_to(enemy.home) > enemy.get_leash():
		state_machine.transition_to(&"Retreat")
		return
	var distance: float = enemy.distance_to_player()
	if enemy.data.can_leap() and _should_leap(distance):
		return
	if enemy.data.is_ranged() and distance < enemy.data.keep_distance:
		# Too close for a ranged enemy: step back while facing the player.
		var away: Vector3 = (enemy.global_position - player.global_position).normalized()
		enemy.move_towards(enemy.global_position + away * 3.0, enemy.data.walk_speed, delta)
		enemy.face_player(delta)
		if enemy.attack_cooldown_left <= 0.0:
			state_machine.transition_to(&"Attack")
		return
	if distance <= enemy.data.attack_range:
		enemy.stop_moving(delta)
		enemy.face_player(delta)
		if enemy.attack_cooldown_left <= 0.0:
			state_machine.transition_to(&"Attack")
		return
	var target: Vector3 = player.global_position
	if enemy.data.flanks and distance > FLANK_DISTANCE:
		var from_player: Vector3 = (enemy.global_position - player.global_position).normalized()
		target = player.global_position + from_player.rotated(Vector3.UP, enemy.flank_side * deg_to_rad(65.0)) * 2.5
	enemy.move_towards(target, enemy.data.run_speed, delta)


## A leaping enemy jumps at the player from a distance, and hops away again
## when the player has not hit it for a while. Returns true when it leaps.
func _should_leap(distance: float) -> bool:
	var data: EnemyData = enemy.data
	if data.patience > 0.0 and distance <= data.attack_range + 1.0:
		enemy.patience_left = minf(enemy.patience_left, data.patience) - get_physics_process_delta_time()
		if enemy.patience_left <= 0.0:
			state_machine.transition_to(&"Leap", {"away": true})
			return true
		return false
	if enemy.leap_cooldown_left > 0.0 or distance <= data.attack_range + 2.0 or distance > data.leap_range \
			or not enemy.player_detected:
		return false
	state_machine.transition_to(&"Leap", {"away": false})
	return true
