@tool
class_name BoxCluster
extends StaticBody3D
## Many boxes in one vertex-coloured mesh: the details of a location, such as
## cars, fences, bikes and signs. One mesh means one draw call. Each box is
## seven numbers in [member boxes] (centre x, y, z, size x, y, z and a turn
## around Y); its colour has the same index in [member colors]. The location
## scenes come from tools/map/gen_locations.py.

enum Look {
	## Normal flat colours with light and shade.
	LIT,
	## Always fully bright, for lamps, neon and lit windows.
	GLOW,
	## See-through, with the alpha of the colour, for glass and vape clouds.
	GLASS,
}

const FLOATS_PER_BOX: int = 7

@export var boxes: PackedFloat32Array = PackedFloat32Array()
@export var colors: PackedColorArray = PackedColorArray()
@export var look: Look = Look.LIT
## Every box also blocks: walls, cars, bins. Off for small decoration.
@export var solid: bool = false

static var _glow_material: StandardMaterial3D
static var _glass_material: StandardMaterial3D


func _ready() -> void:
	var tool: SurfaceTool = LowPolyMesh.begin()
	for i: int in colors.size():
		var b: int = i * FLOATS_PER_BOX
		var center: Vector3 = Vector3(boxes[b], boxes[b + 1], boxes[b + 2])
		var size: Vector3 = Vector3(boxes[b + 3], boxes[b + 4], boxes[b + 5])
		var yaw: float = boxes[b + 6]
		_add_box(tool, center, size, yaw, colors[i])
		if solid and not Engine.is_editor_hint():
			var shape: BoxShape3D = BoxShape3D.new()
			shape.size = size
			var collision: CollisionShape3D = CollisionShape3D.new()
			collision.shape = shape
			collision.transform = Transform3D(Basis(Vector3.UP, yaw), center)
			add_child(collision)
	if colors.is_empty():
		return
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = LowPolyMesh.commit(tool)
	instance.visibility_range_end = 260.0
	match look:
		Look.GLOW:
			instance.material_override = _get_glow_material()
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		Look.GLASS:
			instance.material_override = _get_glass_material()
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


func _add_box(tool: SurfaceTool, center: Vector3, size: Vector3, yaw: float, color: Color) -> void:
	if is_zero_approx(yaw):
		LowPolyMesh.add_box(tool, center, size, color)
		return
	var basis: Basis = Basis(Vector3.UP, yaw)
	var h: Vector3 = size * 0.5
	var corners: Array[Vector3] = []
	for x: float in [-h.x, h.x]:
		for y: float in [-h.y, h.y]:
			for z: float in [-h.z, h.z]:
				corners.append(center + basis * Vector3(x, y, z))
	# Corner index bits: x is 4, y is 2, z is 1, as in LowPolyMesh.add_box.
	for face: Array in [[4, 5, 7, 6], [0, 2, 3, 1], [2, 6, 7, 3], [0, 1, 5, 4], [1, 3, 7, 5], [0, 4, 6, 2]]:
		var points: PackedVector3Array = [corners[face[0]], corners[face[1]], corners[face[2]], corners[face[3]]]
		LowPolyMesh.add_face(tool, points, center, color)


static func _get_glow_material() -> StandardMaterial3D:
	if _glow_material == null:
		_glow_material = StandardMaterial3D.new()
		_glow_material.vertex_color_use_as_albedo = true
		_glow_material.vertex_color_is_srgb = true
		_glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _glow_material


static func _get_glass_material() -> StandardMaterial3D:
	if _glass_material == null:
		_glass_material = StandardMaterial3D.new()
		_glass_material.vertex_color_use_as_albedo = true
		_glass_material.vertex_color_is_srgb = true
		_glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_glass_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		_glass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _glass_material
