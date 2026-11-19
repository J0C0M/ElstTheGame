extends EnemyState
## Dead: Enemy.die() handles the fall, the loot and removing the body.


func enter(_data: Dictionary) -> void:
	enemy.die()
