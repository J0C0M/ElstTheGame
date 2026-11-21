class_name EnemyState
extends State
## Base for the enemy states, with a typed reference to the enemy.

var enemy: Enemy


func _ready() -> void:
	enemy = owner as Enemy
