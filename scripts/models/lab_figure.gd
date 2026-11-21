class_name LabFigure
extends RefCounted
## Builds a standing figure (Klaas, Gyan or a driller) in one of the four
## model proposals of Prototype 2, as one static mesh. Only for the model lab
## (P2-1): the chosen proposal gets a real rig in P2-2.
##
## The proposals:
## M1 refined blocks (bevelled boxes, square limbs, many small parts),
## M2 faceted low poly (6-sided limbs, 8x6 heads, flat shaded),
## M3 stylized (M2 with a big head, big hands and a shorter body),
## M4 PS2 level (12-sided limbs, 16x12 heads, smooth shading, most detail).

enum Style { M1, M2, M3, M4 }

const STYLE_NAMES: Array[String] = ["M1 Verfijnde blokken", "M2 Gefacetteerd", "M3 Gestileerd", "M4 PS2-niveau"]

const CHARACTERS: Array[StringName] = [&"klaas", &"gyan", &"driller"]

const SKIN_LIGHT: Color = Color(0.96, 0.79, 0.66)
const SKIN_TAN: Color = Color(0.93, 0.74, 0.58)
const BLACK: Color = Color(0.06, 0.06, 0.07)
const WHITE: Color = Color(0.93, 0.93, 0.9)
const GOLD: Color = Color(0.95, 0.75, 0.25)

var _style: Style
var _kit: MeshKit
var _spec: Dictionary
## Facets around a limb.
var _sides: int
## Body heights are multiplied by this (M3 is shorter).
var _body_y: float
var _head_scale: float
var _hand_scale: float
var _detail: bool


## A MeshInstance3D with [param character] in [param style], feet at y = 0,
## facing +Z.
static func build(character: StringName, style: Style) -> MeshInstance3D:
	var figure: LabFigure = LabFigure.new(character, style)
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = "%s_%s" % [str(character).capitalize(), ["M1", "M2", "M3", "M4"][style]]
	instance.mesh = figure._make()
	return instance


func _init(character: StringName, style: Style) -> void:
	_style = style
	_spec = _spec_for(character)
	_kit = MeshKit.new(style != Style.M4)
	_sides = [4, 6, 6, 12][style]
	_body_y = 0.86 if style == Style.M3 else 1.0
	_head_scale = 1.5 if style == Style.M3 else 1.0
	_hand_scale = 1.45 if style == Style.M3 else 1.0
	_detail = style == Style.M4


static func _spec_for(character: StringName) -> Dictionary:
	match character:
		&"klaas":
			return {
				"height": 2.0, "width": 1.32, "chest": 1.45, "skin": SKIN_TAN,
				"hair": Color(0.96, 0.84, 0.46), "hair_style": &"quiff", "shirt": Color(0.42, 0.18, 0.58),
				"shirt_alt": Color(0.5, 0.24, 0.68), "pattern": &"plain", "sleeve": 0.45,
				"pants": Color(0.14, 0.15, 0.2), "shoes": Color(0.92, 0.92, 0.9), "jaw": 0.15,
				"sunglasses": true, "chain": true, "mouth": &"smirk", "muscles": true, "belt": GOLD,
			}
		&"gyan":
			return {
				"height": 1.8, "width": 0.98, "chest": 1.0, "skin": SKIN_LIGHT,
				"hair": Color(0.25, 0.15, 0.09), "hair_style": &"messy", "shirt": Color(0.24, 0.4, 0.7),
				"shirt_alt": Color(0.92, 0.94, 0.96), "shirt_dark": Color(0.13, 0.22, 0.45), "pattern": &"plaid",
				"sleeve": 1.0, "pants": Color(0.24, 0.31, 0.46), "shoes": Color(0.2, 0.18, 0.17), "jaw": 0.35,
				"eyes": Color(0.36, 0.22, 0.12), "mouth": &"smile", "belt": Color(0.3, 0.2, 0.12),
			}
		_:
			return {
				"height": 1.8, "width": 1.05, "chest": 1.05, "skin": SKIN_LIGHT,
				"hair": BLACK, "hair_style": &"balaclava", "shirt": Color(0.17, 0.17, 0.19),
				"shirt_alt": Color(0.95, 0.8, 0.2), "pattern": &"tracksuit", "sleeve": 1.0,
				"pants": Color(0.17, 0.17, 0.19), "pants_stripe": WHITE, "shoes": WHITE, "jaw": 0.3,
				"eyes": Color(0.2, 0.25, 0.3), "mouth": &"none", "belt": Color(0.17, 0.17, 0.19),
			}


func _make() -> ArrayMesh:
	_build_legs()
	_build_torso()
	_build_arms()
	_build_head()
	return _kit.commit()


## A point on the body: [param x] is scaled by the width, [param y] by the
## height (and the M3 squash), [param z] by the depth.
func _p(x: float, y: float, z: float = 0.0) -> Vector3:
	var height: float = _spec["height"]
	var width: float = _spec["width"]
	return Vector3(x * width, y * height / 1.8 * _body_y, z * width)


func _w() -> float:
	return _spec["width"]


# --- Legs, hips and shoes -------------------------------------------------

func _build_legs() -> void:
	var pants: Color = _spec["pants"]
	var stripe: Color = _spec.get("pants_stripe", pants)
	for side: float in [-1.0, 1.0]:
		var hip: Vector3 = _p(0.1 * side, 0.93)
		var knee: Vector3 = _p(0.105 * side, 0.5, 0.015)
		var ankle: Vector3 = _p(0.1 * side, 0.1)
		var outer: int = _sides - 1 if side > 0.0 else _sides / 2 - 1
		var leg_color: Callable = func(k: int, _s: int) -> Color:
			return stripe if k == outer else pants
		_kit.limb_pattern(hip, knee, 0.085 * _w(), 0.063 * _w(), _sides, 1, leg_color)
		_kit.limb_pattern(knee, ankle, 0.063 * _w(), 0.048 * _w(), _sides, 1, leg_color)
		if _style != Style.M1:
			_kit.ball(knee, Vector3.ONE * 0.064 * _w(), _sides, 4, pants)
		_build_shoe(Vector3(ankle.x, 0.0, ankle.z), side)
	# Hips.
	_kit.limb(_p(0, 0.9), _p(0, 1.05), 0.165 * _w(), 0.158 * _w(), maxi(_sides, 6) if _style != Style.M1 else 4, pants,
		Vector2(1.0, 0.66))
	var belt: Color = _spec["belt"]
	_kit.limb(_p(0, 1.02), _p(0, 1.06), 0.163 * _w(), 0.162 * _w(), maxi(_sides, 6) if _style != Style.M1 else 4, belt,
		Vector2(1.0, 0.68))
	if _detail or _spec.has("chain"):
		_kit.box(_p(0, 1.04, 0.112), Vector3(0.05, 0.035, 0.012) * _w(), GOLD if _spec.has("chain") else Color(0.7, 0.7, 0.68))


func _build_shoe(foot: Vector3, side: float) -> void:
	var shoes: Color = _spec["shoes"]
	var size: Vector3 = Vector3(0.11, 0.1, 0.26) * Vector3(_w(), _spec["height"] / 1.8, _w())
	var center: Vector3 = foot + Vector3(0.0, size.y * 0.5, 0.045 * _w())
	match _style:
		Style.M1:
			_kit.box(center, size, shoes, Basis.IDENTITY, 0.02)
		Style.M4:
			_kit.box(center + Vector3(0, -size.y * 0.35, 0), Vector3(size.x * 1.06, size.y * 0.3, size.z * 1.04),
				Color(0.85, 0.84, 0.8) if shoes != WHITE else Color(0.75, 0.75, 0.73))
			_kit.ball(center + Vector3(0, size.y * 0.05, 0.02), Vector3(size.x * 0.52, size.y * 0.55, size.z * 0.52), 12, 6,
				shoes, Basis.IDENTITY, func(p: Vector3) -> Vector3: return Vector3(p.x, maxf(p.y, -0.5), p.z))
			_kit.limb(foot + Vector3(0, size.y * 0.55, -0.02), foot + Vector3(0, size.y * 1.05, -0.02), 0.05 * _w(),
				0.05 * _w(), 12, shoes)
		_:
			var s: float = 1.2 if _style == Style.M3 else 1.0
			_kit.ball(center + Vector3(0, 0, 0.01), Vector3(size.x * 0.55, size.y * 0.6, size.z * 0.55) * s, 6, 4, shoes,
				Basis.IDENTITY, func(p: Vector3) -> Vector3: return Vector3(p.x, maxf(p.y, -0.6), p.z))


# --- Torso ----------------------------------------------------------------

## The colour per facet of the shirt. On a sleeve ([param arm_side] -1 or 1)
## a tracksuit gets a white stripe on the outside.
func _shirt_color(arm_side: float = 0.0) -> Callable:
	var shirt: Color = _spec["shirt"]
	var alt: Color = _spec["shirt_alt"]
	var dark: Color = _spec.get("shirt_dark", shirt)
	match _spec["pattern"]:
		&"plaid":
			return func(k: int, s: int) -> Color:
				var across: bool = k % 2 == 0
				var along: bool = s % 2 == 1
				if across and along:
					return dark
				if across or along:
					return shirt
				return alt
		&"tracksuit":
			if arm_side == 0.0:
				return func(_k: int, _s: int) -> Color: return shirt
			var outer: int = _sides - 1 if arm_side > 0.0 else _sides / 2 - 1
			return func(k: int, _s: int) -> Color:
				return WHITE if k == outer else shirt
		_:
			return func(_k: int, _s: int) -> Color: return shirt


func _build_torso() -> void:
	var chest: float = _spec["chest"]
	var shirt: Color = _spec["shirt"]
	var color_fn: Callable = _shirt_color()
	# Waist, belly, chest, under the shoulders, shoulder line.
	var heights: Array[float] = [1.03, 1.14, 1.26, 1.36, 1.44, 1.49]
	var widths: Array[float] = [0.145, 0.142, 0.15 * chest, 0.162 * chest, 0.158 * chest, 0.12 * chest]
	if _style == Style.M1:
		heights = [1.03, 1.2, 1.36, 1.49]
		widths = [0.145, 0.15 * chest, 0.162 * chest, 0.15 * chest]
	elif _detail:
		heights = [1.03, 1.09, 1.15, 1.21, 1.27, 1.33, 1.39, 1.44, 1.48, 1.5]
		widths = [0.145, 0.141, 0.143, 0.15 * chest, 0.157 * chest, 0.162 * chest, 0.162 * chest, 0.156 * chest,
			0.14 * chest, 0.1 * chest]
	var points: Array[Vector3] = []
	var radii: Array[float] = []
	for n: int in heights.size():
		points.append(_p(0, heights[n]))
		radii.append(widths[n] * _w())
	_kit.loft(points, radii, _sides, color_fn, Vector2(1.0, 0.6))
	if _spec["pattern"] == &"tracksuit":
		# The yellow band of Westeraam across the chest.
		_kit.limb(_p(0, 1.29), _p(0, 1.35), 0.158 * chest * _w() + 0.006, 0.162 * chest * _w() + 0.006, _sides, _spec["shirt_alt"],
			Vector2(1.0, 0.6))
	# Shoulder line: a flattened ball as the top of the chest.
	if _style == Style.M1:
		_kit.box(_p(0, 1.47), Vector3(0.3 * chest, 0.05, 0.17) * _w(), shirt, Basis.IDENTITY, 0.02)
	if _spec.has("muscles"):
		for side: float in [-1.0, 1.0]:
			var pec: Vector3 = _p(0.07 * side * chest, 1.35, 0.058 * chest)
			if _style == Style.M1:
				_kit.box(pec, Vector3(0.13, 0.08, 0.05) * _w(), shirt, Basis.IDENTITY, 0.015)
			else:
				_kit.ball(pec, Vector3(0.08, 0.055, 0.04) * _w(), _sides, 4, shirt)
	# Collar and buttons.
	if _detail or _style == Style.M1:
		if _spec["pattern"] == &"plaid":
			for side: float in [-1.0, 1.0]:
				_kit.wedge(_p(0.0, 1.5, 0.07), _p(0.075 * side, 1.5, 0.05), _p(0.03 * side, 1.43, 0.09),
					Vector3(0, 0, 0.012), _spec["shirt_dark"])
			for n: int in 4:
				_kit.box(_p(0, 1.38 - n * 0.09, 0.1), Vector3(0.014, 0.014, 0.01) * _w(), WHITE)
		elif _spec["pattern"] == &"tracksuit":
			_kit.box(_p(0, 1.25, 0.1), Vector3(0.008, 0.4, 0.01) * _w(), Color(0.55, 0.55, 0.55))
	if _spec.has("chain"):
		_build_chain()


func _build_chain() -> void:
	var links: int = 9 if _style == Style.M1 else (20 if _detail else 12)
	for n: int in links:
		var angle: float = PI * (n + 0.5) / links
		var chest: float = _spec["chest"]
		var x: float = cos(angle) * 0.085
		var z: float = 0.02 + sin(angle) * (0.155 * chest * 0.6 - 0.005)
		var y: float = 1.49 - sin(angle) * 0.11
		var point: Vector3 = _p(x, y, z)
		if _style == Style.M1:
			_kit.box(point, Vector3.ONE * 0.026 * _w(), GOLD)
		else:
			_kit.ball(point, Vector3.ONE * (0.017 if _detail else 0.021) * _w(), 6 if _detail else 4, 3, GOLD)
	if _style != Style.M1:
		_kit.ball(_p(0, 1.365, 0.155 * float(_spec["chest"]) * 0.6 + 0.02), Vector3(0.03, 0.036, 0.015) * _w(), 6, 4, GOLD)


# --- Arms and hands -------------------------------------------------------

func _build_arms() -> void:
	var chest: float = _spec["chest"]
	var shirt: Color = _spec["shirt"]
	var skin: Color = _spec["skin"]
	var sleeve: float = _spec["sleeve"]
	var bulk: float = 1.3 if _spec.has("muscles") else 1.0
	for side: float in [-1.0, 1.0]:
		var color_fn: Callable = _shirt_color(side)
		var shoulder: Vector3 = _p((0.15 * chest + 0.03) * side, 1.43)
		var elbow: Vector3 = _p((0.15 * chest + 0.06) * side, 1.16, -0.03)
		var wrist: Vector3 = _p((0.15 * chest + 0.075) * side, 0.92, 0.04)
		# Upper arm: sleeve to [param sleeve] of the way, then skin.
		if sleeve >= 1.0:
			_kit.limb_pattern(shoulder, elbow, 0.062 * _w() * bulk, 0.05 * _w() * bulk, _sides, 2, color_fn)
			_kit.limb_pattern(elbow, wrist, 0.05 * _w() * bulk, 0.042 * _w(), _sides, 2, color_fn)
			if _detail:
				_kit.limb(wrist.lerp(elbow, 0.1), wrist.lerp(elbow, -0.02), 0.046 * _w(), 0.046 * _w(), _sides,
					_spec.get("shirt_dark", shirt))
		else:
			var cuff: Vector3 = shoulder.lerp(elbow, sleeve)
			_kit.limb(shoulder, cuff, 0.068 * _w() * bulk, 0.062 * _w() * bulk, _sides, shirt)
			_kit.limb(cuff, elbow, 0.056 * _w() * bulk, 0.05 * _w() * bulk, _sides, skin)
			_kit.limb(elbow, wrist, 0.05 * _w() * bulk, 0.04 * _w(), _sides, skin)
		if _style != Style.M1:
			_kit.ball(shoulder + Vector3(0, 0.01, 0), Vector3(0.07, 0.06, 0.06) * _w() * sqrt(bulk), _sides, 4, shirt)
			_kit.ball(elbow, Vector3.ONE * 0.05 * _w() * bulk, _sides, 4, shirt if sleeve >= 1.0 else skin)
		_build_hand(wrist, side)


func _build_hand(wrist: Vector3, side: float) -> void:
	var skin: Color = _spec["skin"]
	if _spec["hair_style"] == &"balaclava":
		skin = BLACK  # Gloves.
	var s: float = _hand_scale * _w()
	var center: Vector3 = wrist + Vector3(0.005 * side, -0.065 * s, 0.0)
	match _style:
		Style.M1:
			_kit.box(center, Vector3(0.045, 0.1, 0.085) * s, skin, Basis.IDENTITY, 0.012)
			_kit.box(center + Vector3(-0.01 * side, 0.01, 0.05) * s, Vector3(0.03, 0.05, 0.03) * s, skin)
		Style.M4:
			_kit.ball(center + Vector3(0, 0.015, 0) * s, Vector3(0.025, 0.045, 0.045) * s, 10, 6, skin)
			_kit.limb(center + Vector3(0, -0.02, 0.0) * s, center + Vector3(0.008 * side, -0.075, 0.008) * s,
				0.026 * s, 0.018 * s, 8, skin, Vector2(0.6, 1.0))
			_kit.limb(center + Vector3(-0.005 * side, 0.01, 0.035) * s, center + Vector3(-0.012 * side, -0.035, 0.055) * s,
				0.011 * s, 0.009 * s, 6, skin)
		_:
			_kit.ball(center, Vector3(0.03, 0.055, 0.045) * s, 6, 4, skin)
			_kit.ball(center + Vector3(-0.008 * side, 0.005, 0.04) * s, Vector3(0.013, 0.025, 0.013) * s, 4, 3, skin)


# --- Head -----------------------------------------------------------------

func _build_head() -> void:
	var skin: Color = _spec["skin"]
	var hair_style: StringName = _spec["hair_style"]
	var neck_color: Color = BLACK if hair_style == &"balaclava" else skin
	var neck_top: Vector3 = _p(0, 1.57)
	_kit.limb(_p(0, 1.46), neck_top, 0.055 * _w(), 0.05 * _w(), maxi(_sides, 6) if _style != Style.M1 else 4, neck_color)
	var r: Vector3 = Vector3(0.11, 0.13, 0.12) * _head_scale
	if _spec.has("muscles"):
		r *= Vector3(1.12, 1.05, 1.05)
	var c: Vector3 = neck_top + Vector3(0, r.y * 0.82, 0.01)
	var jaw: float = _spec["jaw"]
	if _style == Style.M1:
		_kit.box(c + Vector3(0, r.y * 0.1, 0), Vector3(r.x * 1.9, r.y * 1.75, r.z * 1.9), skin if hair_style != &"balaclava" else BLACK,
			Basis.IDENTITY, 0.02)
		_kit.box(c + Vector3(0, -r.y * 0.72, 0.01), Vector3(r.x * 1.9 * (1.0 - jaw * 0.6), r.y * 0.35, r.z * 1.6),
			skin if hair_style != &"balaclava" else BLACK, Basis.IDENTITY, 0.015)
	else:
		var shape: Callable = func(p: Vector3) -> Vector3:
			var q: Vector3 = p
			if q.y < 0.0:
				q.x *= 1.0 - jaw * minf(-q.y, 1.0)
				if q.z > 0.0:
					q.z += 0.08 * -q.y
			if q.y > 0.4:
				q.z -= 0.08 * (q.y - 0.4)
			return q
		var around: int = 16 if _detail else 8
		var high: int = 12 if _detail else 6
		_kit.ball(c, r, around, high, skin if hair_style != &"balaclava" else BLACK, Basis.IDENTITY, shape)
	_build_face(c, r)
	_build_hair(c, r)


func _build_face(c: Vector3, r: Vector3) -> void:
	var skin: Color = _spec["skin"]
	var hair_style: StringName = _spec["hair_style"]
	var face_z: float = c.z + r.z * (0.92 if _style != Style.M1 else 0.95)
	var eye_y: float = c.y + r.y * 0.08
	var eye_x: float = r.x * 0.4
	if hair_style == &"balaclava":
		# The eye slit of the balaclava.
		_kit.box(Vector3(c.x, eye_y, face_z - r.z * 0.05), Vector3(r.x * 1.35, r.y * 0.3, r.z * 0.2), skin)
	# Ears.
	if hair_style != &"balaclava" and _style != Style.M3:
		for side: float in [-1.0, 1.0]:
			var ear: Vector3 = Vector3(c.x + r.x * 0.97 * side, c.y, c.z - r.z * 0.05)
			if _style == Style.M1:
				_kit.box(ear, Vector3(r.x * 0.2, r.y * 0.38, r.z * 0.3), skin)
			else:
				_kit.ball(ear, Vector3(r.x * 0.12, r.y * 0.24, r.z * 0.17), 6 if _detail else 4, 4, skin)
	# Eyes or sunglasses.
	if _spec.has("sunglasses"):
		_kit.box(Vector3(c.x, eye_y, face_z + r.z * 0.04), Vector3(r.x * 1.75, r.y * 0.26, r.z * 0.08), BLACK, Basis.IDENTITY,
			0.004 if _style == Style.M1 else 0.0)
		if _detail:
			for side: float in [-1.0, 1.0]:
				_kit.box(Vector3(c.x + r.x * 0.9 * side, eye_y + r.y * 0.04, c.z + r.z * 0.4),
					Vector3(r.x * 0.06, r.y * 0.06, r.z * 1.0), BLACK)
				_kit.box(Vector3(c.x + eye_x * side, eye_y + r.y * 0.04, face_z + r.z * 0.09),
					Vector3(r.x * 0.35, r.y * 0.06, r.z * 0.02), Color(0.3, 0.3, 0.35))
	else:
		var iris: Color = _spec.get("eyes", BLACK)
		for side: float in [-1.0, 1.0]:
			var eye: Vector3 = Vector3(c.x + eye_x * side, eye_y, face_z)
			match _style:
				Style.M1, Style.M2:
					_kit.box(eye, Vector3(r.x * 0.2, r.y * 0.16, r.z * 0.1), BLACK)
				Style.M3:
					_kit.box(eye, Vector3(r.x * 0.3, r.y * 0.3, r.z * 0.06), WHITE)
					_kit.box(eye + Vector3(0, -r.y * 0.03, r.z * 0.03), Vector3(r.x * 0.17, r.y * 0.22, r.z * 0.04), iris)
					_kit.box(eye + Vector3(0, -r.y * 0.03, r.z * 0.05), Vector3(r.x * 0.08, r.y * 0.1, r.z * 0.03), BLACK)
				Style.M4:
					_kit.ball(eye + Vector3(0, 0, -r.z * 0.04), Vector3(r.x * 0.17, r.y * 0.1, r.z * 0.08), 8, 4, WHITE)
					_kit.ball(eye + Vector3(0, 0, r.z * 0.02), Vector3(r.x * 0.08, r.y * 0.08, r.z * 0.04), 6, 4, iris)
			# Eyebrows.
			if hair_style != &"balaclava" and _style != Style.M2:
				var brow: Color = _spec["hair"]
				brow = brow.darkened(0.25) if hair_style == &"quiff" else brow
				_kit.box(eye + Vector3(0, r.y * (0.24 if _style == Style.M3 else 0.17), r.z * 0.02),
					Vector3(r.x * 0.3, r.y * 0.06, r.z * 0.06), brow)
	if hair_style == &"balaclava":
		return
	# Nose.
	var nose_w: float = r.x * (0.12 if _detail else 0.15)
	var nose_top: float = eye_y - r.y * 0.05
	var nose_bottom: float = c.y - r.y * 0.25
	var nose_len: float = r.z * (0.18 if _style != Style.M3 else 0.12)
	_kit.wedge(Vector3(c.x - nose_w, nose_top, face_z - r.z * 0.03), Vector3(c.x - nose_w, nose_bottom, face_z - r.z * 0.03),
		Vector3(c.x - nose_w, nose_bottom, face_z + nose_len), Vector3(nose_w * 2.0, 0, 0), skin.darkened(0.06))
	# Mouth.
	var mouth_y: float = c.y - r.y * 0.48
	var mouth_z: float = face_z - r.z * (0.1 if _style != Style.M1 else 0.0)
	match _spec["mouth"]:
		&"smile":
			_kit.box(Vector3(c.x, mouth_y, mouth_z), Vector3(r.x * 0.62, r.y * 0.12, r.z * 0.08), Color(0.45, 0.15, 0.15))
			_kit.box(Vector3(c.x, mouth_y + r.y * 0.025, mouth_z + r.z * 0.02), Vector3(r.x * 0.5, r.y * 0.06, r.z * 0.06), WHITE)
			for side: float in [-1.0, 1.0]:
				_kit.box(Vector3(c.x + r.x * 0.33 * side, mouth_y + r.y * 0.06, mouth_z), Vector3(r.x * 0.1, r.y * 0.08, r.z * 0.07),
					Color(0.45, 0.15, 0.15))
		&"smirk":
			_kit.box(Vector3(c.x + r.x * 0.05, mouth_y, mouth_z), Vector3(r.x * 0.5, r.y * 0.06, r.z * 0.07), Color(0.5, 0.25, 0.22))
			_kit.box(Vector3(c.x + r.x * 0.3, mouth_y + r.y * 0.04, mouth_z), Vector3(r.x * 0.12, r.y * 0.06, r.z * 0.07),
				Color(0.5, 0.25, 0.22))


func _build_hair(c: Vector3, r: Vector3) -> void:
	var hair: Color = _spec["hair"]
	var hair_style: StringName = _spec["hair_style"]
	if hair_style == &"balaclava":
		if _style != Style.M1:
			# A seam over the top.
			_kit.limb(c + Vector3(0, r.y * 0.4, r.z * 0.9), c + Vector3(0, r.y * 1.02, 0), r.x * 0.05, r.x * 0.05, 4,
				Color(0.14, 0.14, 0.15))
		return
	var front_cut: float = 0.5 if hair_style == &"messy" else 0.62
	if _style == Style.M1:
		_kit.box(c + Vector3(0, r.y * 0.72, -r.z * 0.05), Vector3(r.x * 2.06, r.y * 0.5, r.z * 2.0), hair, Basis.IDENTITY, 0.015)
		_kit.box(c + Vector3(0, r.y * 0.2, -r.z * 0.88), Vector3(r.x * 2.04, r.y * 1.0, r.z * 0.3), hair)
		for side: float in [-1.0, 1.0]:
			_kit.box(c + Vector3(r.x * 0.98 * side, r.y * 0.35, -r.z * 0.25), Vector3(r.x * 0.14, r.y * 0.6, r.z * 1.2), hair)
		if hair_style == &"messy":
			for n: int in 4:
				var x: float = (n - 1.5) * r.x * 0.45
				_kit.box(c + Vector3(x, r.y * (0.55 - 0.08 * (n % 2)), r.z * 0.88), Vector3(r.x * 0.42, r.y * 0.4, r.z * 0.22), hair,
					Basis(Vector3.BACK, 0.25 * (n - 1.5)))
		else:
			_kit.box(c + Vector3(0, r.y * 1.05, r.z * 0.55), Vector3(r.x * 1.5, r.y * 0.35, r.z * 0.8), hair, Basis(Vector3.RIGHT, -0.3),
				0.01)
		return
	var cap_shape: Callable = func(p: Vector3) -> Vector3:
		var cut: float = lerpf(-0.35, front_cut, clampf((p.z + 0.2) / 1.0, 0.0, 1.0))
		return Vector3(p.x, maxf(p.y, cut), p.z)
	var around: int = 16 if _detail else 8
	var high: int = 12 if _detail else 6
	_kit.ball(c + Vector3(0, r.y * 0.05, -r.z * 0.03), r * Vector3(1.08, 1.06, 1.08), around, high, hair, Basis.IDENTITY, cap_shape)
	if hair_style == &"messy":
		# Messy tufts and a fringe over the forehead.
		var tufts: int = 9 if _detail else 6
		for n: int in tufts:
			var angle: float = TAU * n / tufts + 0.3
			var base: Vector3 = c + Vector3(cos(angle) * r.x * 0.55, r.y * 0.95, sin(angle) * r.z * 0.55)
			var tip: Vector3 = base + Vector3(cos(angle) * r.x * 0.35, r.y * 0.2, sin(angle) * r.z * 0.35)
			_kit.limb(base, tip, r.x * 0.22, r.x * 0.02, 4 if not _detail else 5, hair)
		var fringe: int = 4 if _detail else 3
		for n: int in fringe:
			var x: float = (n - (fringe - 1) * 0.5) * r.x * 0.5
			var base: Vector3 = c + Vector3(x, r.y * 0.75, r.z * 0.75)
			var tip: Vector3 = c + Vector3(x + r.x * 0.15, r.y * 0.38, r.z * 1.02)
			_kit.limb(base, tip, r.x * 0.2, r.x * 0.03, 4 if not _detail else 5, hair)
	elif hair_style == &"quiff":
		# Klaas' quiff: a swept-up roll at the front, short sides.
		var roll_around: int = 12 if _detail else 6
		_kit.ball(c + Vector3(0, r.y * 0.95, r.z * 0.55), r * Vector3(0.82, 0.32, 0.6), roll_around, 4, hair,
			Basis(Vector3.RIGHT, -0.55))
		if _detail:
			_kit.ball(c + Vector3(r.x * 0.15, r.y * 1.12, r.z * 0.6), r * Vector3(0.45, 0.2, 0.35), 10, 4,
				hair.lightened(0.15), Basis(Vector3.RIGHT, -0.5))
