class_name Shockwave
extends Node3D
## A ring that runs over the floor from where Grumpy Oma lands. It hurts a
## player who is on the ground when it passes: jump over it.

@export var speed: float = 9.0
@export var max_radius: float = 14.0
## How close to the ring the player has to be to get hit.
@export var width: float = 0.8

var _damage: int = 0
var _source: Node3D
var _radius: float = 0.5
var _hit: bool = false

@onready var _ring: MeshInstance3D = $Ring
@onready var _hitbox: Hitbox = $Hitbox


func start(damage: int, source: Node3D) -> void:
	_damage = damage
	_source = source
	_hitbox.source = source


func _physics_process(delta: float) -> void:
	_radius += speed * delta
	_ring.scale = Vector3(_radius, 1.0, _radius)
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	if player != null and not _hit:
		var offset: Vector3 = player.global_position - global_position
		var distance: float = Vector2(offset.x, offset.z).length()
		if absf(distance - _radius) < width and player.global_position.y < global_position.y + 0.5:
			_hit = true
			player.hurtbox.receive_hit(HitData.new(_damage, _source, _hitbox))
	if _radius >= max_radius:
		queue_free()
