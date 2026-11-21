class_name VapeHideout
extends Node3D
## A big, slowly turning cloud of vape the Vape-koning hides in. While he is
## inside, a gold glint flickers in it: his chain catching the light.

var _occupied: bool = false
var _time: float = 0.0

@onready var _cloud: Node3D = $Cloud
@onready var _glint: OmniLight3D = $Glint


func _ready() -> void:
	_glint.visible = false


func set_occupied(occupied: bool) -> void:
	_occupied = occupied
	_glint.visible = occupied


func _process(delta: float) -> void:
	_time += delta
	_cloud.rotate_y(delta * 0.4)
	_cloud.scale = Vector3.ONE * (1.0 + sin(_time * 1.3) * 0.04)
	if _occupied:
		_glint.light_energy = 1.2 + sin(_time * 9.0) * 0.6
