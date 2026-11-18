class_name HealthComponent
extends Node
## Hit points for the player, enemies and props.

signal health_changed(current: int, maximum: int)
## Emitted after taking damage, with the amount actually lost.
signal damaged(amount: int)
signal died

@export var max_health: int = 100

var current_health: int = 0


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int) -> void:
	if is_dead() or amount <= 0:
		return
	var lost: int = mini(amount, current_health)
	current_health -= lost
	health_changed.emit(current_health, max_health)
	damaged.emit(lost)
	if current_health == 0:
		died.emit()


func heal(amount: int) -> void:
	if is_dead() or amount <= 0:
		return
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


## Sets a new maximum (or keeps the current one) and fills up to it.
func reset(new_max_health: int = max_health) -> void:
	max_health = new_max_health
	current_health = max_health
	health_changed.emit(current_health, max_health)


func is_dead() -> bool:
	return current_health <= 0


func get_ratio() -> float:
	return float(current_health) / float(maxi(max_health, 1))
