@tool
class_name House
extends StaticBody3D
## Low-poly building for the blockout: walls with a door and rows of windows
## on the front (-Z), and a pitched roof (or a flat one with roof_height 0).
## The mesh is built from the exported values, so one scene covers houses,
## flats and halls.

## Beyond this distance the building is not drawn; the fog hides it anyway.
const DRAW_DISTANCE: float = 260.0
const WINDOW_COLOR: Color = Color(0.22, 0.28, 0.36)
const FLOOR_HEIGHT: float = 3.0

@export var size: Vector3 = Vector3(9, 6, 8):
	set(value):
		size = value
		_rebuild()
@export var roof_height: float = 3.0:
	set(value):
		roof_height = value
		_rebuild()
@export var wall_color: Color = Color(0.62, 0.32, 0.24):
	set(value):
		wall_color = value
		_rebuild()
@export var roof_color: Color = Color(0.3, 0.28, 0.3):
	set(value):
		roof_color = value
		_rebuild()
@export var has_door: bool = true:
	set(value):
		has_door = value
		_rebuild()

var _mesh_instance: MeshInstance3D
var _collision: CollisionShape3D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.visibility_range_end = DRAW_DISTANCE
		add_child(_mesh_instance)
		_collision = CollisionShape3D.new()
		add_child(_collision)
	_mesh_instance.mesh = _build_mesh()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	_collision.shape = shape
	_collision.position = Vector3(0, size.y * 0.5, 0)


func _build_mesh() -> ArrayMesh:
	var tool: SurfaceTool = LowPolyMesh.begin()
	LowPolyMesh.add_box(tool, Vector3(0, size.y * 0.5, 0), size, wall_color)
	if roof_height > 0.0:
		LowPolyMesh.add_roof(tool, Vector3(0, size.y, 0), Vector3(size.x + 0.6, roof_height, size.z + 0.6), roof_color)
	else:
		LowPolyMesh.add_box(tool, Vector3(0, size.y + 0.15, 0), Vector3(size.x + 0.2, 0.3, size.z + 0.2), roof_color)
	var front: float = -size.z * 0.5 - 0.03
	var back: float = size.z * 0.5 + 0.03
	if has_door:
		LowPolyMesh.add_box(tool, Vector3(0, 1.05, front), Vector3(1.1, 2.1, 0.06), wall_color.darkened(0.55))
	var floors: int = maxi(int(size.y / FLOOR_HEIGHT), 1)
	var columns: int = maxi(int(size.x / 3.0), 1)
	for floor_index: int in floors:
		var y: float = floor_index * FLOOR_HEIGHT + FLOOR_HEIGHT * 0.6
		for column: int in columns:
			var x: float = (column + 0.5) * size.x / columns - size.x * 0.5
			var is_door_spot: bool = has_door and floor_index == 0 and absf(x) < 1.4
			if not is_door_spot:
				LowPolyMesh.add_box(tool, Vector3(x, y, front), Vector3(1.1, 1.0, 0.06), WINDOW_COLOR)
			LowPolyMesh.add_box(tool, Vector3(x, y, back), Vector3(1.1, 1.0, 0.06), WINDOW_COLOR)
	return LowPolyMesh.commit(tool)
