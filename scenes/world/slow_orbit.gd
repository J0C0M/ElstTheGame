extends Node3D
## Turns slowly around its Y axis. The filter test scene uses it to orbit the camera.

@export var degrees_per_second: float = 6.0


func _process(delta: float) -> void:
	rotate_y(deg_to_rad(degrees_per_second) * delta)
