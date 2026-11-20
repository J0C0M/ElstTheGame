class_name MembraneMesh
extends MeshInstance3D
## A skin stretched between marker nodes, such as the wing of a dragon: it
## follows the bones it hangs from as they fold and flap. The triangles are
## rebuilt every frame from the interpolated marker positions, with one flat
## normal per triangle. Built by tools/models/model_builder.py.

## Marker nodes the skin hangs from.
@export var points: Array[NodePath] = []
## Triangles as indices into points, three per triangle.
@export var triangles: PackedInt32Array = PackedInt32Array()

var _markers: Array[Node3D] = []
var _mesh: ImmediateMesh


func _ready() -> void:
	for path: NodePath in points:
		_markers.append(get_node(path) as Node3D)
	_mesh = ImmediateMesh.new()
	mesh = _mesh
	# The skin moves with its bones every frame; its own transform does not.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_rebuild()


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		_rebuild()


func _rebuild() -> void:
	if _markers.is_empty() or not is_inside_tree():
		return
	var to_local: Transform3D = global_transform.affine_inverse()
	var local: PackedVector3Array = PackedVector3Array()
	for marker: Node3D in _markers:
		local.append(to_local * marker.get_global_transform_interpolated().origin)
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(0, triangles.size() - 2, 3):
		var a: Vector3 = local[triangles[i]]
		var b: Vector3 = local[triangles[i + 1]]
		var c: Vector3 = local[triangles[i + 2]]
		var normal: Vector3 = (c - a).cross(b - a).normalized()
		for vertex: Vector3 in [a, b, c]:
			_mesh.surface_set_normal(normal)
			_mesh.surface_add_vertex(vertex)
	_mesh.surface_end()
