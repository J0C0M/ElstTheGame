class_name FirePatch
extends Node3D
## A burning patch the fatbike-kindje's souped-up engine leaves behind. It
## hurts the player once on contact, flickers for a few seconds and goes out.

## Seconds the patch burns.
@export var lifetime: float = 4.0

var _age: float = 0.0

@onready var _hitbox: Hitbox = $Hitbox
@onready var _flames: Node3D = $Flames
@onready var _light: OmniLight3D = $Light


## Lights the patch: it hurts for [param damage], on behalf of [param source].
func ignite(damage: int, source: Node3D) -> void:
	_hitbox.source = source
	_hitbox.activate(damage)


func _physics_process(delta: float) -> void:
	_age += delta
	var left: float = clampf(1.0 - _age / lifetime, 0.0, 1.0)
	_flames.scale = Vector3(1.0, (0.7 + sin(_age * 18.0) * 0.3) * left, 1.0)
	_light.light_energy = 1.5 * left
	if _age >= lifetime:
		queue_free()
