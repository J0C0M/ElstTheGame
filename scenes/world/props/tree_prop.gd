@tool
class_name TreeProp
extends StaticBody3D
## Low-poly tree: a pine or a leafy tree. Scale the node to vary the size.
## Each kind's mesh is built once and shared by every tree.

enum Kind { PINE, LEAFY }

const DRAW_DISTANCE: float = 200.0
const TRUNK_COLOR: Color = Color(0.4, 0.27, 0.16)

@export var kind: Kind = Kind.LEAFY:
	set(value):
		kind = value
		_rebuild()

static var _meshes: Dictionary = {}

var _mesh_instance: MeshInstance3D


func _ready() -> void:
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = 0.3
	shape.height = 2.5
	collision.shape = shape
	collision.position = Vector3(0, 1.25, 0)
	add_child(collision)
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.visibility_range_end = DRAW_DISTANCE
		add_child(_mesh_instance)
	if not _meshes.has(kind):
		_meshes[kind] = _build_mesh(kind)
	_mesh_instance.mesh = _meshes[kind]


static func _build_mesh(tree_kind: Kind) -> ArrayMesh:
	var tool: SurfaceTool = LowPolyMesh.begin()
	LowPolyMesh.add_box(tool, Vector3(0, 1.2, 0), Vector3(0.4, 2.4, 0.4), TRUNK_COLOR)
	if tree_kind == Kind.PINE:
		LowPolyMesh.add_cone(tool, Vector3(0, 1.6, 0), 1.8, 2.6, 6, Color(0.18, 0.36, 0.2))
		LowPolyMesh.add_cone(tool, Vector3(0, 3.0, 0), 1.4, 2.4, 6, Color(0.2, 0.4, 0.22))
		LowPolyMesh.add_cone(tool, Vector3(0, 4.3, 0), 0.9, 2.0, 6, Color(0.22, 0.44, 0.24))
	else:
		LowPolyMesh.add_box(tool, Vector3(0, 3.6, 0), Vector3(2.8, 2.4, 2.8), Color(0.3, 0.5, 0.24))
		LowPolyMesh.add_box(tool, Vector3(0, 4.9, 0), Vector3(1.8, 1.2, 1.8), Color(0.34, 0.55, 0.27))
	return LowPolyMesh.commit(tool)
