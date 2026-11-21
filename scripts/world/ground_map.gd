@tool
class_name GroundMap
extends Node3D
## Flat ground for a whole world in one mesh and one draw call: streets,
## gardens, fields, parks and water, coloured cell by cell from a small raster.
## The raster is data, not a texture: each cell holds a palette index in its
## red channel. Cells of the same colour are merged into larger quads. The
## raster is centred on this node, and a skirt in [member skirt_color] runs on
## to [member skirt_extent] so the ground never ends inside the tornado.

## Palette index per cell, in the red channel (an L8 image is fastest).
@export var raster: Image:
	set(value):
		raster = value
		_rebuild()
## Size of one raster cell in metres.
@export var cell_size: float = 1.0:
	set(value):
		cell_size = value
		_rebuild()
## Colour for each palette index.
@export var palette: PackedColorArray = PackedColorArray():
	set(value):
		palette = value
		_rebuild()
## Colour of the ground around the raster.
@export var skirt_color: Color = Color(0.46, 0.6, 0.32):
	set(value):
		skirt_color = value
		_rebuild()
## Half the width of the ground including the skirt, in metres.
@export var skirt_extent: float = 280.0:
	set(value):
		skirt_extent = value
		_rebuild()

var _mesh_instance: MeshInstance3D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree() or raster == null or palette.is_empty():
		return
	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_mesh_instance)
	_mesh_instance.mesh = _build_mesh()


func _build_mesh() -> ArrayMesh:
	var width: int = raster.get_width()
	var height: int = raster.get_height()
	var cells: PackedByteArray = _read_cells()
	var done: PackedByteArray = PackedByteArray()
	done.resize(width * height)
	var origin: Vector2 = Vector2(width, height) * cell_size * -0.5
	var vertices: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	for z: int in height:
		var x: int = 0
		while x < width:
			var start: int = z * width + x
			if done[start] != 0:
				x += 1
				continue
			var value: int = cells[start]
			var x_end: int = x + 1
			while x_end < width and cells[z * width + x_end] == value and done[z * width + x_end] == 0:
				x_end += 1
			var z_end: int = z + 1
			while z_end < height and _row_matches(cells, done, z_end * width, x, x_end, value):
				z_end += 1
			for row: int in range(z, z_end):
				for column: int in range(x, x_end):
					done[row * width + column] = 1
			var color: Color = palette[mini(value, palette.size() - 1)]
			_add_quad(vertices, colors, origin + Vector2(x, z) * cell_size, origin + Vector2(x_end, z_end) * cell_size, color)
			x = x_end
	_add_skirt(vertices, colors, -origin)
	var normals: PackedVector3Array = PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.UP)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, LowPolyMesh.get_material())
	return mesh


func _read_cells() -> PackedByteArray:
	if raster.get_format() == Image.FORMAT_L8:
		return raster.get_data()
	var cells: PackedByteArray = PackedByteArray()
	cells.resize(raster.get_width() * raster.get_height())
	for z: int in raster.get_height():
		for x: int in raster.get_width():
			cells[z * raster.get_width() + x] = raster.get_pixel(x, z).r8
	return cells


func _row_matches(cells: PackedByteArray, done: PackedByteArray, row_start: int, x0: int, x1: int, value: int) -> bool:
	for column: int in range(x0, x1):
		if cells[row_start + column] != value or done[row_start + column] != 0:
			return false
	return true


## The ring of ground between the raster and the skirt edge.
func _add_skirt(vertices: PackedVector3Array, colors: PackedColorArray, half: Vector2) -> void:
	var outer: float = maxf(skirt_extent, maxf(half.x, half.y))
	_add_quad(vertices, colors, Vector2(-outer, -outer), Vector2(outer, -half.y), skirt_color)
	_add_quad(vertices, colors, Vector2(-outer, half.y), Vector2(outer, outer), skirt_color)
	_add_quad(vertices, colors, Vector2(-outer, -half.y), Vector2(-half.x, half.y), skirt_color)
	_add_quad(vertices, colors, Vector2(half.x, -half.y), Vector2(outer, half.y), skirt_color)


## Two triangles facing up from corner [param a] to corner [param b] (x, z).
func _add_quad(vertices: PackedVector3Array, colors: PackedColorArray, a: Vector2, b: Vector2, color: Color) -> void:
	var p0: Vector3 = Vector3(a.x, 0, a.y)
	var p1: Vector3 = Vector3(b.x, 0, a.y)
	var p2: Vector3 = Vector3(b.x, 0, b.y)
	var p3: Vector3 = Vector3(a.x, 0, b.y)
	vertices.append_array(PackedVector3Array([p0, p1, p2, p0, p2, p3]))
	for i: int in 6:
		colors.append(color)
