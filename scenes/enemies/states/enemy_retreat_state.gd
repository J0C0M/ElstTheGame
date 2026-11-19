extends EnemyState
## Walks back home after losing the player, and heals up on arrival. Only a
## hit (or a warning from an ally) brings it back into the fight.


func enter(_data: Dictionary) -> void:
	enemy.aware = false


func physics_update(delta: float) -> void:
	var to_home: Vector3 = enemy.home - enemy.global_position
	to_home.y = 0.0
	if to_home.length() < 1.5:
		enemy.health.reset()
		state_machine.transition_to(&"Idle")
		return
	enemy.move_towards(enemy.home, enemy.data.walk_speed * 1.4, delta)
