class_name HitData
extends RefCounted
## One hit from a Hitbox on a Hurtbox.

var damage: int
## The attacker, used for direction checks such as blocking.
var source: Node3D
var hitbox: Hitbox


func _init(hit_damage: int, hit_source: Node3D, from_hitbox: Hitbox) -> void:
	damage = hit_damage
	source = hit_source
	hitbox = from_hitbox
