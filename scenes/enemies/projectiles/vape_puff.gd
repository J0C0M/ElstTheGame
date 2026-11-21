class_name VapePuff
extends Area3D
## A projectile that drifts in a straight line: a slow cloud of vape that an
## enemy blows at the player, or a football (same script, other settings). It
## stops at a wall or after a while, hangs in the air for a moment and then
## fades. It hurts the player once, through its Hitbox, so blocking and
## parrying work as against any other attack.

## Metres per second while drifting.
@export var speed: float = 5.0
## Seconds it drifts before it stops by itself.
@export var travel_time: float = 2.2
## Seconds it hangs in the air after it stopped.
@export var linger_time: float = 1.4

var _direction: Vector3 = Vector3.FORWARD
var _time: float = 0.0
var _stopped_at: float = -1.0
var _material: StandardMaterial3D

@onready var _hitbox: Hitbox = $Hitbox
@onready var _visual: Node3D = $Visual


## Sends the puff from [param origin] along [param direction] for [param damage].
func launch(origin: Vector3, direction: Vector3, damage: int, source: Node3D) -> void:
	global_position = origin
	_direction = direction.normalized()
	_hitbox.source = source
	_hitbox.activate(damage)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_hitbox.hit_landed.connect(func(_hurtbox: Hurtbox) -> void: _stop())
	# Every puff fades on its own, so it needs its own material.
	_material = (_visual.get_child(0) as MeshInstance3D).mesh.surface_get_material(0).duplicate() as StandardMaterial3D
	for child: Node in _visual.get_children():
		(child as MeshInstance3D).material_override = _material


func _physics_process(delta: float) -> void:
	_time += delta
	_visual.rotate_y(delta * 1.5)
	if _stopped_at < 0.0:
		global_position += _direction * speed * delta
		if _time >= travel_time:
			_stop()
		return
	var linger: float = _time - _stopped_at
	_visual.scale = Vector3.ONE * (1.0 + linger * 0.5)
	_material.albedo_color.a = lerpf(0.55, 0.0, clampf(linger / linger_time, 0.0, 1.0))
	if linger >= linger_time:
		queue_free()


func _stop() -> void:
	if _stopped_at < 0.0:
		_stopped_at = _time


func _on_body_entered(_body: Node3D) -> void:
	_stop()
