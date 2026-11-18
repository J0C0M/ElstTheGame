class_name Hurtbox
extends Area3D
## Area a Hitbox can hit. The owner decides what a hit does (blocking,
## armour, damage) by listening to hit_received.

signal hit_received(hit: HitData)


func _ready() -> void:
	monitoring = false
	monitorable = true


func receive_hit(hit: HitData) -> void:
	hit_received.emit(hit)


## Turns hits on or off, for example while a prop is destroyed.
func set_enabled(enabled: bool) -> void:
	set_deferred("monitorable", enabled)
