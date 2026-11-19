extends EnemyState
## Runs at the player and attacks when close. Flankers circle round to the
## player's side first. Gives up when the player gets away or the chase leads
## too far from home.

## Seconds without noticing the player before the enemy gives up.
const LOSE_TIME: float = 5.0
## Flankers go straight in once this close.
const FLANK_DISTANCE: float = 4.0


func enter(_data: Dictionary) -> void:
	enemy.aware = true
	enemy.time_since_seen = 0.0
	enemy.alert_pack()


func physics_update(delta: float) -> void:
	var player: Player = enemy.get_player()
	if player == null or player.health.is_dead() or enemy.time_since_seen > LOSE_TIME \
			or enemy.global_position.distance_to(enemy.home) > enemy.data.leash_range:
		state_machine.transition_to(&"Retreat")
		return
	var distance: float = enemy.distance_to_player()
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
