class_name LowPolyMesh
## Builds flat-shaded, vertex-coloured meshes from boxes, roofs and cones.
## One mesh per prop means one draw call, and all props share one material.

static var _material: StandardMaterial3D


## The shared material: flat colours taken from the vertex colours.
static func get_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
		_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return _material


static func begin() -> SurfaceTool:
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	return tool


static func commit(tool: SurfaceTool) -> ArrayMesh:
	var mesh: ArrayMesh = tool.commit()
	mesh.surface_set_material(0, get_material())
	return mesh


static func add_box(tool: SurfaceTool, center: Vector3, size: Vector3, color: Color) -> void:
	var h: Vector3 = size * 0.5
	var corners: Array[Vector3] = []
	for x: float in [-h.x, h.x]:
		for y: float in [-h.y, h.y]:
			for z: float in [-h.z, h.z]:
				corners.append(center + Vector3(x, y, z))
	# Corner index bits: x is 4, y is 2, z is 1.
	for face: Array in [[4, 5, 7, 6], [0, 2, 3, 1], [2, 6, 7, 3], [0, 1, 5, 4], [1, 3, 7, 5], [0, 4, 6, 2]]:
		var points: PackedVector3Array = [corners[face[0]], corners[face[1]], corners[face[2]], corners[face[3]]]
		add_face(tool, points, center, color)


## Pitched roof whose ridge runs along X, standing on [param base_center].
static func add_roof(tool: SurfaceTool, base_center: Vector3, size: Vector3, color: Color) -> void:
	var h: Vector3 = Vector3(size.x * 0.5, size.y, size.z * 0.5)
	var c: Vector3 = base_center
	var inside: Vector3 = c + Vector3(0, size.y * 0.3, 0)
	var ridge_left: Vector3 = c + Vector3(-h.x, h.y, 0)
	var ridge_right: Vector3 = c + Vector3(h.x, h.y, 0)
	var front_left: Vector3 = c + Vector3(-h.x, 0, -h.z)
	var front_right: Vector3 = c + Vector3(h.x, 0, -h.z)
	var back_left: Vector3 = c + Vector3(-h.x, 0, h.z)
	var back_right: Vector3 = c + Vector3(h.x, 0, h.z)
	add_face(tool, [front_left, front_right, ridge_right, ridge_left], inside, color)
	add_face(tool, [back_left, back_right, ridge_right, ridge_left], inside, color)
	add_face(tool, [front_left, back_left, ridge_left], inside, color.darkened(0.15))
	add_face(tool, [front_right, back_right, ridge_right], inside, color.darkened(0.15))
	add_face(tool, [front_left, front_right, back_right, back_left], inside, color.darkened(0.3))


## Cone (or pyramid with few sides) standing on [param base_center].
static func add_cone(tool: SurfaceTool, base_center: Vector3, radius: float, height: float, sides: int, color: Color) -> void:
	var tip: Vector3 = base_center + Vector3(0, height, 0)
	var inside: Vector3 = base_center + Vector3(0, height * 0.3, 0)
	var ring: PackedVector3Array = []
	for i: int in sides:
		var angle: float = TAU * i / sides
		ring.append(base_center + Vector3(cos(angle) * radius, 0, sin(angle) * radius))
	for i: int in sides:
		add_face(tool, [ring[i], ring[(i + 1) % sides], tip], inside, color)
	add_face(tool, ring, inside, color.darkened(0.3))


## Adds a flat polygon. The winding is fixed up so the face points away
## from [param inside_point].
static func add_face(tool: SurfaceTool, points: PackedVector3Array, inside_point: Vector3, color: Color) -> void:
	var normal: Vector3 = (points[1] - points[0]).cross(points[2] - points[0]).normalized()
	var face_center: Vector3 = Vector3.ZERO
	for point: Vector3 in points:
		face_center += point
	face_center /= points.size()
	if normal.dot(face_center - inside_point) < 0.0:
		normal = -normal
		points.reverse()
	# Godot treats clockwise triangles as front faces, so the points must run
	# clockwise around the outward normal.
	if (points[1] - points[0]).cross(points[2] - points[0]).dot(normal) > 0.0:
		points.reverse()
	tool.set_color(color)
	tool.set_normal(normal)
	for i: int in range(1, points.size() - 1):
		tool.add_vertex(points[0])
		tool.add_vertex(points[i])
		tool.add_vertex(points[i + 1])
