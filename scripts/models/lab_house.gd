class_name LabHouse
extends RefCounted
## Builds an Elst house (brick walls, a tiled gable roof, white frames) in one
## of the four model proposals of Prototype 2, as one static mesh. Only for
## the model lab (P2-1). See [LabFigure] for the proposals.

const BRICK: Color = Color(0.62, 0.3, 0.22)
const BRICK_DARK: Color = Color(0.52, 0.24, 0.18)
const MORTAR: Color = Color(0.7, 0.62, 0.55)
const ROOF: Color = Color(0.25, 0.22, 0.23)
const ROOF_DARK: Color = Color(0.19, 0.17, 0.18)
const FRAME: Color = Color(0.92, 0.92, 0.88)
const GLASS: Color = Color(0.2, 0.27, 0.33)
const DOOR: Color = Color(0.18, 0.32, 0.26)
const STONE: Color = Color(0.6, 0.6, 0.58)

## Width (x), depth (z) and wall height of the house.
const SIZE: Vector3 = Vector3(7.0, 5.6, 6.0)

var _style: LabFigure.Style
var _kit: MeshKit


static func build(style: LabFigure.Style) -> MeshInstance3D:
	var house: LabHouse = LabHouse.new(style)
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = "House_%s" % ["M1", "M2", "M3", "M4"][style]
	instance.mesh = house._make()
	return instance


func _init(style: LabFigure.Style) -> void:
	_style = style
	_kit = MeshKit.new(true)


func _make() -> ArrayMesh:
	var w: float = SIZE.x
	var d: float = SIZE.z
	var h: float = SIZE.y
	match _style:
		LabFigure.Style.M1:
			_kit.box(Vector3(0, 0.15, 0), Vector3(w + 0.2, 0.3, d + 0.2), STONE, Basis.IDENTITY, 0.05)
			_kit.box(Vector3(0, h * 0.5 + 0.15, 0), Vector3(w, h - 0.3, d), BRICK, Basis.IDENTITY, 0.08)
			_roof(w, d, h, 0.35, 0.25, false)
			_chimney(Vector3(1.8, h, -1.0), 0.8, 2.6, false)
		LabFigure.Style.M2:
			_kit.box(Vector3(0, 0.2, 0), Vector3(w + 0.16, 0.4, d + 0.16), STONE)
			_kit.box(Vector3(0, h * 0.5, 0), Vector3(w, h, d), BRICK)
			_band(h - 0.25, w, d, BRICK_DARK)
			_band(2.75, w, d, BRICK_DARK)
			_roof(w, d, h, 0.5, 0.22, false)
			_gutters(w, d, h)
			_chimney(Vector3(1.8, h, -1.0), 0.75, 2.8, true)
		LabFigure.Style.M3:
			# Chunky and a little crooked: a fat base, a big roof.
			_kit.box(Vector3(0, 0.25, 0), Vector3(w + 0.4, 0.5, d + 0.4), STONE, Basis.IDENTITY, 0.12)
			_kit.box(Vector3(0, h * 0.5, 0), Vector3(w, h, d), BRICK, Basis(Vector3.BACK, 0.015), 0.25)
			_roof(w, d, h, 0.9, 0.4, false, 1.15)
			_chimney(Vector3(2.0, h + 0.2, -1.2), 1.0, 3.2, true, 0.12)
		LabFigure.Style.M4:
			_kit.box(Vector3(0, 0.2, 0), Vector3(w + 0.16, 0.4, d + 0.16), STONE)
			_kit.box(Vector3(0, h * 0.5, 0), Vector3(w, h, d), MORTAR)
			_bricks(w, d, h)
			_roof(w, d, h, 0.5, 0.18, true)
			_gutters(w, d, h)
			_chimney(Vector3(1.8, h, -1.0), 0.75, 2.8, true)
	_front(w, d, h)
	return _kit.commit()


## A ring of slightly thicker wall around the house at [param y].
func _band(y: float, w: float, d: float, color: Color) -> void:
	_kit.box(Vector3(0, y, 0), Vector3(w + 0.08, 0.18, d + 0.08), color)


## Brick courses: thin rows of bricks over the mortar, every other row shifted.
func _bricks(w: float, d: float, h: float) -> void:
	var row: float = 0.3
	var rows: int = int((h - 0.4) / row)
	for n: int in rows:
		var y: float = 0.4 + (n + 0.5) * row
		var color: Color = BRICK if n % 3 != 1 else BRICK_DARK
		var shift: float = 0.25 if n % 2 == 0 else 0.0
		# Front and back: bricks as strips of 4 with gaps.
		for face: float in [-1.0, 1.0]:
			var x: float = -w * 0.5 + 0.02 + shift
			while x < w * 0.5 - 0.1:
				var length: float = minf(0.95, w * 0.5 - 0.02 - x)
				_kit.box(Vector3(x + length * 0.5, y, face * (d * 0.5 + 0.02)), Vector3(length - 0.04, row - 0.05, 0.05), color)
				x += 1.0
		for face: float in [-1.0, 1.0]:
			var z: float = -d * 0.5 + 0.02 + shift
			while z < d * 0.5 - 0.1:
				var length: float = minf(0.95, d * 0.5 - 0.02 - z)
				_kit.box(Vector3(face * (w * 0.5 + 0.02), y, z + length * 0.5), Vector3(0.05, row - 0.05, length - 0.04), color)
				z += 1.0
	# The gable ends are brick too.
	for face: float in [-1.0, 1.0]:
		_kit.wedge(Vector3(-w * 0.5, h, face * (d * 0.5 + 0.03)), Vector3(w * 0.5, h, face * (d * 0.5 + 0.03)),
			Vector3(0, h + w * 0.5, face * (d * 0.5 + 0.03)), Vector3(0, 0, -face * 0.04), BRICK)


## A gable roof with its ridge along X... turned: the ridge runs along Z so
## the gable faces the street (+Z), as in much of Elst.
func _roof(w: float, d: float, h: float, overhang: float, thickness: float, tiles: bool, pitch_scale: float = 1.0) -> void:
	var rise: float = w * 0.5 * pitch_scale
	var half_span: float = w * 0.5 + overhang
	var slope_len: float = sqrt(half_span * half_span + (rise * half_span / (w * 0.5)) ** 2)
	var angle: float = atan2(rise, w * 0.5)
	var length: float = d + overhang * 2.0
	# Gable walls (brick triangles) unless the bricks drew them.
	if not tiles:
		for face: float in [-1.0, 1.0]:
			_kit.wedge(Vector3(-w * 0.5, h, face * d * 0.5), Vector3(w * 0.5, h, face * d * 0.5),
				Vector3(0, h + rise, face * d * 0.5), Vector3(0, 0, -face * 0.3), BRICK)
	for side: float in [-1.0, 1.0]:
		var basis: Basis = Basis(Vector3.BACK, -side * angle)
		var mid: Vector3 = Vector3(side * (half_span * 0.5 - overhang * 0.5) * 1.0, h + rise * 0.5, 0)
		mid.x = side * (w * 0.5 + overhang) * 0.5
		mid.y = h + rise - rise * ((w * 0.5 + overhang) * 0.5) / (w * 0.5)
		mid += basis * Vector3(0, thickness * 0.5, 0)
		if not tiles:
			_kit.box(mid, Vector3(slope_len, thickness, length), ROOF, basis, 0.04 if _style != LabFigure.Style.M2 else 0.0)
		else:
			# Rows of tiles: each row a slab that overlaps the next one down.
			var rows: int = 9
			for n: int in rows:
				var t: float = (n + 0.5) / rows - 0.5
				var row_center: Vector3 = mid + basis * Vector3(-side * t * slope_len, (n % 2) * 0.03, 0)
				_kit.box(row_center, Vector3(slope_len / rows + 0.08, thickness, length), ROOF if n % 2 == 0 else ROOF_DARK,
					basis * Basis(Vector3.BACK, side * 0.06))
	# Ridge.
	if _style != LabFigure.Style.M1:
		_kit.box(Vector3(0, h + rise + thickness * 0.6, 0), Vector3(0.3, 0.2, length + 0.05), ROOF_DARK,
			Basis(Vector3.BACK, PI * 0.25))


func _gutters(w: float, d: float, h: float) -> void:
	for side: float in [-1.0, 1.0]:
		_kit.limb(Vector3(side * (w * 0.5 + 0.45), h - 0.15, -d * 0.5 - 0.5), Vector3(side * (w * 0.5 + 0.45), h - 0.15, d * 0.5 + 0.5),
			0.1, 0.1, 6 if _style == LabFigure.Style.M4 else 4, Color(0.75, 0.75, 0.74))
	# Drainpipe.
	_kit.limb(Vector3(w * 0.5 + 0.12, h - 0.25, d * 0.5 - 0.15), Vector3(w * 0.5 + 0.12, 0.1, d * 0.5 - 0.15), 0.07, 0.07,
		6 if _style == LabFigure.Style.M4 else 4, Color(0.75, 0.75, 0.74))


func _chimney(base: Vector3, size: float, height: float, cap: bool, lean: float = 0.0) -> void:
	var basis: Basis = Basis(Vector3.BACK, lean)
	_kit.box(base + Vector3(0, height * 0.5, 0), Vector3(size, height, size), BRICK_DARK, basis,
		0.06 if _style in [LabFigure.Style.M1, LabFigure.Style.M3] else 0.0)
	if cap:
		_kit.box(base + basis * Vector3(0, height + 0.08, 0), Vector3(size + 0.2, 0.16, size + 0.2), STONE, basis)


## The street side: door, windows on two floors, sills, a step.
func _front(w: float, d: float, h: float) -> void:
	var z: float = d * 0.5
	var big: float = 1.25 if _style == LabFigure.Style.M3 else 1.0
	# Door.
	_window_or_door(Vector3(-w * 0.25, 0.4 + 1.1, z), Vector2(1.1, 2.2) * Vector2(big, 1.0), true)
	_kit.box(Vector3(-w * 0.25, 0.25, z + 0.35), Vector3(1.6, 0.18, 0.7), STONE, Basis.IDENTITY,
		0.03 if _style in [LabFigure.Style.M1, LabFigure.Style.M3] else 0.0)
	# Windows: big one downstairs, two upstairs, one in the gable.
	_window_or_door(Vector3(w * 0.2, 1.8, z), Vector2(2.2, 1.6) * big, false)
	_window_or_door(Vector3(-w * 0.25, 4.1, z), Vector2(1.3, 1.3) * big, false)
	_window_or_door(Vector3(w * 0.2, 4.1, z), Vector2(1.3, 1.3) * big, false)
	_window_or_door(Vector3(0, h + 1.4, z), Vector2(0.9, 0.9) * big, false)
	# House number and a lamp next to the door.
	if _style == LabFigure.Style.M4 or _style == LabFigure.Style.M2:
		_kit.box(Vector3(-w * 0.25 + 0.9, 2.2, z + 0.06), Vector3(0.2, 0.3, 0.08), Color(0.12, 0.12, 0.12))
		_kit.box(Vector3(-w * 0.25 + 0.9, 2.2, z + 0.12), Vector3(0.14, 0.2, 0.08), Color(1.0, 0.85, 0.5))


func _window_or_door(center: Vector3, size: Vector2, is_door: bool) -> void:
	var frame: float = 0.12 if _style != LabFigure.Style.M3 else 0.18
	var bevel: float = 0.03 if _style in [LabFigure.Style.M1, LabFigure.Style.M3] else 0.0
	var front: float = center.z + 0.03
	# The opening (glass or door panel), set back a little.
	_kit.box(Vector3(center.x, center.y, front), Vector3(size.x, size.y, 0.06), DOOR if is_door else GLASS)
	# Frame: four bars.
	for side: float in [-1.0, 1.0]:
		_kit.box(Vector3(center.x + side * (size.x + frame) * 0.5, center.y, front + 0.05), Vector3(frame, size.y + frame * 2.0, 0.14),
			FRAME, Basis.IDENTITY, bevel)
		_kit.box(Vector3(center.x, center.y + side * (size.y + frame) * 0.5, front + 0.05), Vector3(size.x, frame, 0.14), FRAME,
			Basis.IDENTITY, bevel)
	if is_door:
		if _style != LabFigure.Style.M1:
			_kit.box(Vector3(center.x, center.y + size.y * 0.25, front + 0.05), Vector3(size.x * 0.5, size.y * 0.25, 0.06), GLASS)
		_kit.box(Vector3(center.x + size.x * 0.35, center.y - 0.05, front + 0.1), Vector3(0.08, 0.08, 0.1), Color(0.85, 0.7, 0.3))
		return
	# Sill.
	_kit.box(Vector3(center.x, center.y - size.y * 0.5 - frame - 0.04, front + 0.12), Vector3(size.x + frame * 3.0, 0.1, 0.3), STONE,
		Basis.IDENTITY, bevel)
	if _style == LabFigure.Style.M1:
		return
	# Window bars.
	_kit.box(Vector3(center.x, center.y, front + 0.05), Vector3(0.07, size.y, 0.08), FRAME)
	if _style == LabFigure.Style.M4:
		_kit.box(Vector3(center.x, center.y + size.y * 0.15, front + 0.05), Vector3(size.x, 0.06, 0.08), FRAME)
		# Curtains just behind the glass.
		for side: float in [-1.0, 1.0]:
			_kit.box(Vector3(center.x + side * size.x * 0.38, center.y, front + 0.01), Vector3(size.x * 0.2, size.y * 0.95, 0.02),
				Color(0.85, 0.8, 0.65))
	if _style == LabFigure.Style.M3:
		# Shutters.
		for side: float in [-1.0, 1.0]:
			_kit.box(Vector3(center.x + side * (size.x * 0.5 + frame + 0.35), center.y, front + 0.04), Vector3(0.6, size.y + 0.1, 0.08),
				DOOR, Basis.IDENTITY, 0.03)
