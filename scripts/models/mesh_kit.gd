class_name MeshKit
extends RefCounted
## Builds low poly meshes in code from a few shapes: boxes, tapered limbs
## (frustums with n sides), shaped spheres (heads, muscles, puffs) and
## wedges. Faceted (every triangle its own flat normal) or smooth (shared
## normals). Colours are vertex colours, so one material serves every model.
## Used by the model lab of Prototype 2 (P2-1) and later by the new models.
##
##     var kit := MeshKit.new(true)            # faceted
##     kit.limb(Vector3.ZERO, Vector3.UP, 0.1, 0.08, 6, Color.RED)
##     var mesh: ArrayMesh = kit.commit()

static var _material: StandardMaterial3D

var faceted: bool
var _tool: SurfaceTool


func _init(flat_shaded: bool = true) -> void:
	faceted = flat_shaded
	_tool = SurfaceTool.new()
	_tool.begin(Mesh.PRIMITIVE_TRIANGLES)


## The shared material: flat colours from the vertex colours.
static func get_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
		_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		_material.roughness = 1.0
	return _material


func commit() -> ArrayMesh:
	if not faceted:
		_tool.index()
	_tool.generate_normals()
	var mesh: ArrayMesh = _tool.commit()
	if mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, get_material())
	return mesh


## One triangle, turned so its front faces away from [param inside].
func tri(a: Vector3, b: Vector3, c: Vector3, color: Color, inside: Vector3) -> void:
	var normal: Vector3 = (c - a).cross(b - a)
	if normal.length_squared() < 1e-12:
		return
	if normal.dot((a + b + c) / 3.0 - inside) < 0.0:
		var swap: Vector3 = b
		b = c
		c = swap
	for vertex: Vector3 in [a, b, c]:
		_tool.set_color(color)
		_tool.add_vertex(vertex)


func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color, inside: Vector3) -> void:
	tri(a, b, c, color, inside)
	tri(a, c, d, color, inside)


## A box at [param center], turned by [param basis], with an optional
## [param bevel]: the corners cut off, as on a worked piece of wood.
func box(center: Vector3, size: Vector3, color: Color, basis: Basis = Basis.IDENTITY, bevel: float = 0.0) -> void:
	var h: Vector3 = size * 0.5
	if bevel <= 0.0:
		var c: Array[Vector3] = []
		for x: float in [-h.x, h.x]:
			for y: float in [-h.y, h.y]:
				for z: float in [-h.z, h.z]:
					c.append(center + basis * Vector3(x, y, z))
		for f: Array in [[4, 5, 7, 6], [0, 2, 3, 1], [2, 6, 7, 3], [0, 1, 5, 4], [1, 3, 7, 5], [0, 4, 6, 2]]:
			quad(c[f[0]], c[f[1]], c[f[2]], c[f[3]], color, center)
		return
	# A bevelled box: a ring of 8 points per height, three heights.
	var b: float = minf(bevel, minf(h.x, minf(h.y, h.z)) * 0.9)
	var levels: Array[float] = [-h.y, -h.y + b, h.y - b, h.y]
	var rings: Array = []
	for n: int in 4:
		var inset: float = b if n in [0, 3] else 0.0
		var ring: Array[Vector3] = []
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			var x: float = corner.x * (h.x - inset)
			var z: float = corner.y * (h.z - inset)
			ring.append(center + basis * Vector3(x - corner.x * (b - inset), levels[n], z))
			ring.append(center + basis * Vector3(x, levels[n], z - corner.y * (b - inset)))
		rings.append(_reorder_ring(ring))
	_rings(rings, color, center, true)


## A tapered limb from [param a] to [param b]: [param sides] facets, radius
## [param ra] at a and [param rb] at b, with closed ends.
func limb(a: Vector3, b: Vector3, ra: float, rb: float, sides: int, color: Color, squash: Vector2 = Vector2.ONE) -> void:
	var axis: Vector3 = (b - a).normalized()
	var side: Vector3 = axis.cross(Vector3.FORWARD if absf(axis.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var up: Vector3 = side.cross(axis).normalized()
	var rings: Array = []
	for end: Array in [[a, ra], [b, rb]]:
		var ring: Array[Vector3] = []
		for k: int in sides:
			var angle: float = TAU * (k + 0.5) / sides
			ring.append(end[0] + (side * cos(angle) * squash.x + up * sin(angle) * squash.y) * float(end[1]))
		rings.append(ring)
	_rings(rings, color, (a + b) * 0.5, true)


## A limb like [method limb] in [param segments] pieces along its length,
## coloured per facet by [param color_fn] (facet index, segment index) ->
## Color: stripes, checks or a plaid shirt.
func limb_pattern(a: Vector3, b: Vector3, ra: float, rb: float, sides: int, segments: int, color_fn: Callable,
		squash: Vector2 = Vector2.ONE) -> void:
	var points: Array[Vector3] = []
	var radii: Array[float] = []
	for n: int in segments + 1:
		var t: float = float(n) / segments
		points.append(a.lerp(b, t))
		radii.append(lerpf(ra, rb, t))
	loft(points, radii, sides, color_fn, squash)


## A tube through [param points] with a radius per point, closed at both
## ends: a torso that is narrow at the waist and wide at the chest, a curved
## limb. Coloured per facet by [param color_fn] (facet, segment) -> Color.
func loft(points: Array[Vector3], radii: Array[float], sides: int, color_fn: Callable, squash: Vector2 = Vector2.ONE) -> void:
	var axis: Vector3 = (points[points.size() - 1] - points[0]).normalized()
	var side: Vector3 = axis.cross(Vector3.FORWARD if absf(axis.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var up: Vector3 = side.cross(axis).normalized()
	var inside: Vector3 = Vector3.ZERO
	for p: Vector3 in points:
		inside += p
	inside /= points.size()
	var rings: Array = []
	for n: int in points.size():
		var ring: Array[Vector3] = []
		for k: int in sides:
			var angle: float = TAU * (k + 0.5) / sides
			ring.append(points[n] + (side * cos(angle) * squash.x + up * sin(angle) * squash.y) * radii[n])
		rings.append(ring)
	var segments: int = points.size() - 1
	for n: int in segments:
		var r0: Array = rings[n]
		var r1: Array = rings[n + 1]
		var mid: Vector3 = (points[n] + points[n + 1]) * 0.5
		for k: int in sides:
			quad(r0[k], r0[(k + 1) % sides], r1[(k + 1) % sides], r1[k], color_fn.call(k, n), mid)
	for end: int in [0, segments]:
		var ring: Array = rings[end]
		for k: int in sides:
			tri(points[end], ring[k], ring[(k + 1) % sides], color_fn.call(k, maxi(end - 1, 0)), inside)


## A sphere with [param radii], [param around] facets round and [param high]
## bands high, whose points can be moved by [param shape] (a Callable that
## takes the unit-sphere point and returns an offset point, for jaws, chins
## and bulges). [param color_at] can colour per band (a Callable taking the
## height from -1 to 1 and returning a Color), else [param color].
func ball(center: Vector3, radii: Vector3, around: int, high: int, color: Color, basis: Basis = Basis.IDENTITY,
		shape: Callable = Callable(), color_at: Callable = Callable()) -> void:
	var rings: Array = []
	for band: int in range(1, high):
		var v: float = PI * band / high
		var ring: Array[Vector3] = []
		for k: int in around:
			var u: float = TAU * (k + 0.5 * (band % 2)) / around
			var p: Vector3 = Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u))
			if shape.is_valid():
				p = shape.call(p)
			ring.append(center + basis * (p * radii))
		rings.append(ring)
	var top: Vector3 = center + basis * ((shape.call(Vector3.UP) if shape.is_valid() else Vector3.UP) * radii)
	var bottom: Vector3 = center + basis * ((shape.call(Vector3.DOWN) if shape.is_valid() else Vector3.DOWN) * radii)
	var count: int = rings.size()
	for n: int in count:
		var c: Color = color_at.call(1.0 - 2.0 * (n + 0.5) / count) if color_at.is_valid() else color
		var ring: Array = rings[n]
		if n == 0:
			for k: int in around:
				tri(top, ring[k], ring[(k + 1) % around], c, center)
		if n < count - 1:
			var next: Array = rings[n + 1]
			for k: int in around:
				quad(ring[k], ring[(k + 1) % around], next[(k + 1) % around], next[k], c, center)
		else:
			for k: int in around:
				tri(bottom, ring[k], ring[(k + 1) % around], c, center)


## A wedge (a triangular prism) such as a nose or a roof: the triangle
## [param a], [param b], [param c] pushed by [param depth].
func wedge(a: Vector3, b: Vector3, c: Vector3, depth: Vector3, color: Color) -> void:
	var inside: Vector3 = (a + b + c) / 3.0 + depth * 0.5
	tri(a, b, c, color, inside)
	tri(a + depth, b + depth, c + depth, color, inside)
	quad(a, b, b + depth, a + depth, color, inside)
	quad(b, c, c + depth, b + depth, color, inside)
	quad(c, a, a + depth, c + depth, color, inside)


func _rings(rings: Array, color: Color, inside: Vector3, closed: bool) -> void:
	var sides: int = (rings[0] as Array).size()
	for n: int in rings.size() - 1:
		var r0: Array = rings[n]
		var r1: Array = rings[n + 1]
		for k: int in sides:
			quad(r0[k], r0[(k + 1) % sides], r1[(k + 1) % sides], r1[k], color, inside)
	if closed:
		for ring: Array in [rings[0], rings[rings.size() - 1]]:
			var middle: Vector3 = Vector3.ZERO
			for p: Vector3 in ring:
				middle += p
			middle /= ring.size()
			for k: int in sides:
				tri(middle, ring[k], ring[(k + 1) % sides], color, inside)


## The 8 points of a bevelled ring in order around.
func _reorder_ring(ring: Array[Vector3]) -> Array[Vector3]:
	return [ring[0], ring[2], ring[3], ring[5], ring[4], ring[6], ring[7], ring[1]] as Array[Vector3]
