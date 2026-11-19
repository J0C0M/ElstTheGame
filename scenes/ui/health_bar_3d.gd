class_name HealthBar3D
extends MeshInstance3D
## Small health bar above an enemy. Hidden while health is full or zero.

@export var hide_when_full: bool = true


func set_ratio(ratio: float) -> void:
	set_instance_shader_parameter(&"fill_ratio", clampf(ratio, 0.0, 1.0))
	visible = ratio > 0.0 and (ratio < 1.0 or not hide_when_full)
