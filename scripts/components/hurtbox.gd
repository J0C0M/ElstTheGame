class_name Hurtbox
extends Area3D
## Area a Hitbox can hit. The owner decides what a hit does (blocking,
## armour, damage) by listening to hit_received.

signal hit_received(hit: HitData)


func _ready() -> void:
	monitoring = false
	monitorable = true


func receive_hit(hit: HitData) -> void:
	# With dev powers every hit from the player kills, whatever the owner
	# would normally do with it.
	if GameState.dev_powers and hit.source is Player:
		var health: HealthComponent = get_parent().get_node_or_null(^"Health") as HealthComponent
		if health != null:
			if not health.is_dead():
				health.take_damage(health.current_health)
			return
	hit_received.emit(hit)


## Turns hits on or off, for example while a prop is destroyed.
func set_enabled(enabled: bool) -> void:
	set_deferred("monitorable", enabled)
