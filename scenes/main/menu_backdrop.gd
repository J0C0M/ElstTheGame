extends Node3D
## Background for the main menu: Elst seen from a camera that slowly circles
## the church. The world's player is removed before it ever runs.

@export var world_scene: PackedScene
@export var orbit_radius: float = 75.0
@export var orbit_height: float = 26.0
@export var look_at_point: Vector3 = Vector3(0, 14, 0)
@export var degrees_per_second: float = 2.5

var _angle: float = deg_to_rad(200.0)

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	var world: Node3D = world_scene.instantiate()
	var player: Node = world.get_node_or_null("Player")
	if player != null:
		world.remove_child(player)
		player.free()
	add_child(world)
	_place_camera()
	_camera.make_current()


func _physics_process(delta: float) -> void:
	_angle += deg_to_rad(degrees_per_second) * delta
	_place_camera()


func _place_camera() -> void:
	var offset: Vector3 = Vector3(cos(_angle), 0.0, sin(_angle)) * orbit_radius
	_camera.look_at_from_position(look_at_point + offset + Vector3.UP * (orbit_height - look_at_point.y), look_at_point)
