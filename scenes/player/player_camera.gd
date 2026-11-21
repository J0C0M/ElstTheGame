class_name PlayerCamera
extends Node3D
## Third-person camera that orbits the player with the mouse, looking over the
## right shoulder. A spring arm pulls it in front of walls. It follows the
## player's interpolated position every frame, so its own physics
## interpolation is off.

@export var height: float = 1.55
@export var min_pitch_degrees: float = -55.0
@export var max_pitch_degrees: float = 35.0
@export var start_pitch_degrees: float = -12.0

## The node to follow. Defaults to the parent.
var target: Node3D
var yaw: float = 0.0
var pitch: float = 0.0

@onready var camera: Camera3D = $Pitch/SpringArm3D/Camera3D
@onready var _pitch_pivot: Node3D = $Pitch


func _ready() -> void:
	if target == null:
		target = get_parent() as Node3D
	pitch = deg_to_rad(start_pitch_degrees)
	snap_behind_target()


func _unhandled_input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	# screen_relative is not scaled by the retro filter, unlike relative.
	var sensitivity: float = deg_to_rad(Settings.mouse_sensitivity)
	yaw -= motion.screen_relative.x * sensitivity
	pitch = clampf(pitch - motion.screen_relative.y * sensitivity,
		deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))


func _process(_delta: float) -> void:
	if target == null:
		return
	global_position = target.get_global_transform_interpolated().origin + Vector3.UP * height
	rotation = Vector3(0.0, yaw, 0.0)
	_pitch_pivot.rotation = Vector3(pitch, 0.0, 0.0)


## Rotation around the vertical axis only, for camera-relative movement.
func get_yaw_basis() -> Basis:
	return Basis(Vector3.UP, yaw)


## Turns the camera to look the same way as the target.
func snap_behind_target() -> void:
	if target != null:
		yaw = target.global_rotation.y
