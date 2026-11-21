class_name Hitbox
extends Area3D
## Damages every Hurtbox it touches while active, once per activation.
## The owner turns it on for the active frames of an attack.

## Emitted for every Hurtbox hit during the current activation.
signal hit_landed(hurtbox: Hurtbox)
## Emitted when the defender parried this attack.
signal parried

## The attacker. Defaults to the root of the scene this hitbox is in.
var source: Node3D
var damage: int = 0

var _active: bool = false
var _already_hit: Array[Hurtbox] = []


func _ready() -> void:
	monitorable = false
	monitoring = false
	if source == null:
		source = owner as Node3D
	area_entered.connect(_on_area_entered)


func activate(hit_damage: int) -> void:
	damage = hit_damage
	_already_hit.clear()
	_active = true
	set_deferred("monitoring", true)


func deactivate() -> void:
	_active = false
	set_deferred("monitoring", false)


func is_active() -> bool:
	return _active


func _on_area_entered(area: Area3D) -> void:
	var hurtbox: Hurtbox = area as Hurtbox
	if not _active or hurtbox == null or hurtbox in _already_hit or hurtbox.owner == source:
		return
	_already_hit.append(hurtbox)
	hurtbox.receive_hit(HitData.new(damage, source, self))
	hit_landed.emit(hurtbox)
