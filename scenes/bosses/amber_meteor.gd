class_name AmberMeteor
extends Node3D
## A fireball Amber spits from the air. A red ring shows where it lands; a
## second later it strikes there, hurts whoever stands close and leaves a
## burning patch. A pillar in the way catches it.

@export var travel_time: float = 1.0
@export var radius: float = 2.4

var _from: Vector3
var _to: Vector3
var _damage: int = 0
var _source: Node3D
var _fire_scene: PackedScene
var _fire_damage: int = 0
var _time: float = 0.0
var _flying: bool = false

@onready var _ring: Node3D = $Ring
@onready var _ball: Node3D = $Ball
@onready var _hitbox: Hitbox = $Hitbox


## Flies from [param from] to [param to] and strikes there.
func launch(from: Vector3, to: Vector3, damage: int, source: Node3D, fire_scene: PackedScene, fire_damage: int) -> void:
	_from = from
	_to = to
	_damage = damage
	_source = source
	_fire_scene = fire_scene
	_fire_damage = fire_damage
	_hitbox.source = source
	global_position = to
	_ring.global_position = Vector3(to.x, to.y + 0.05, to.z)
	_ball.global_position = from
	_flying = true


func _physics_process(delta: float) -> void:
	if not _flying:
		return
	_time += delta
	var t: float = clampf(_time / travel_time, 0.0, 1.0)
	_ball.global_position = _from.lerp(_to, t)
	_ring.scale = Vector3.ONE * (1.2 - 0.2 * t)
	if t >= 1.0:
		_strike()


func _strike() -> void:
	_flying = false
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	if player != null and player.global_position.distance_to(_to) <= radius:
		player.get_node("Hurtbox").call(&"receive_hit", HitData.new(_damage, _source, _hitbox))
	if _fire_scene != null:
		var patch: Node3D = _fire_scene.instantiate() as Node3D
		get_parent().add_child(patch)
		patch.global_position = _to
		patch.call(&"ignite", _fire_damage, _source)
	queue_free()
