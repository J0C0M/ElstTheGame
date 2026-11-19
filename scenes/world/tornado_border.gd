class_name TornadoBorder
extends Node3D
## The tornado around Elst: a spinning wall of dust and debris that can be
## seen from everywhere. Close to it the wind pushes the player back, and a
## solid ring behind that keeps everyone inside. Amber's defeat (Phase 11)
## makes it disappear.

const MESSAGE: String = "De tornado is te sterk. Je kunt Elst niet ontsnappen."
const DEBRIS_COLORS: Array[Color] = [
	Color(0.45, 0.32, 0.2), Color(0.5, 0.48, 0.45), Color(0.35, 0.3, 0.26), Color(0.62, 0.5, 0.36),
]

## Radius of the solid wall, in metres from this node.
@export var radius: float = 240.0
## From this radius on the wind pushes inwards, harder closer to the wall.
@export var push_start_radius: float = 222.0
## Wind speed right at the wall, in metres per second. Faster than sprinting.
@export var max_wind_speed: float = 11.0
## Seconds between two warning messages.
@export var message_cooldown: float = 5.0
@export var debris_count: int = 260
## Turn speed of the flying debris, in radians per second.
@export var debris_spin_speed: float = 0.12
@export var wall_segments: int = 64

var _message_wait: float = 0.0

@onready var _debris: MultiMeshInstance3D = $Debris
@onready var _wall: StaticBody3D = $Wall


func _ready() -> void:
	_build_wall()
	_build_debris()


func _physics_process(delta: float) -> void:
	_debris.rotate_y(debris_spin_speed * delta)
	_message_wait = maxf(_message_wait - delta, 0.0)
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	if player == null:
		return
	var offset: Vector3 = player.global_position - global_position
	offset.y = 0.0
	var distance: float = offset.length()
	if distance <= push_start_radius:
		return
	var strength: float = clampf(inverse_lerp(push_start_radius, radius, distance), 0.0, 1.0)
	player.apply_wind(-offset.normalized() * max_wind_speed * strength)
	if _message_wait <= 0.0:
		_message_wait = message_cooldown
		EventBus.message_requested.emit(MESSAGE)


func _build_wall() -> void:
	_wall.collision_layer = PhysicsLayers.TORNADO_BORDER
	_wall.collision_mask = 0
	var segment_length: float = TAU * radius / wall_segments + 1.0
	for i: int in wall_segments:
		var angle: float = TAU * i / wall_segments
		var outward: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(segment_length, 80.0, 4.0)
		var shape: CollisionShape3D = CollisionShape3D.new()
		shape.shape = box
		shape.transform = Transform3D(Basis.looking_at(outward), outward * (radius + 2.0) + Vector3(0, 40, 0))
		_wall.add_child(shape)


func _build_debris() -> void:
	var tool: SurfaceTool = LowPolyMesh.begin()
	LowPolyMesh.add_box(tool, Vector3.ZERO, Vector3.ONE, Color.WHITE)
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = LowPolyMesh.commit(tool)
	multimesh.instance_count = debris_count
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	for i: int in debris_count:
		var angle: float = rng.randf() * TAU
		var distance: float = radius + rng.randf_range(-4.0, 12.0)
		var origin: Vector3 = Vector3(cos(angle) * distance, rng.randf_range(4.0, 110.0), sin(angle) * distance)
		var basis: Basis = Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU))
		# Planks, crates and the odd shed roof.
		var piece_size: Vector3 = Vector3(rng.randf_range(0.6, 3.5), rng.randf_range(0.2, 1.2), rng.randf_range(0.4, 2.0))
		multimesh.set_instance_transform(i, Transform3D(basis.scaled(piece_size), origin))
		multimesh.set_instance_color(i, DEBRIS_COLORS[rng.randi() % DEBRIS_COLORS.size()])
	_debris.multimesh = multimesh
