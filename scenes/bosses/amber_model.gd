class_name AmberModel
extends Node3D
## Amber's body from tools/models/gen_amber.py, animated in code: a walk and
## a run with knees, a breathing body, a neck and head that aim, a jaw that
## opens on a glowing throat, a tail in four parts, and bat wings that fold
## along her back, spread, gust and flap (a quick downstroke and a slower
## upstroke with bent elbows, the body bobbing with each beat). Amber sets
## the pose; the joints follow smoothly.

enum Pose { IDLE, INHALE, BREATH, PANT, TAIL, WINGS, FLY, DAZED, DEAD, ROAR, RUN, TAKEOFF, LAND }

const SMOOTHING: float = 9.0
const BODY_HEIGHT: float = 3.0
## Wing beats per second in the air.
const FLAP_RATE: float = 1.3

var pose: Pose = Pose.IDLE
## Horizontal speed in metres per second, for the legs.
var walk_speed: float = 0.0
## Extra turn of the tail during a tail swipe, in radians.
var tail_sweep: float = 0.0
## Extra pitch of the neck to look up or down at a target, in radians.
var look_pitch: float = 0.0
var _time: float = 0.0
var _stride: float = 0.0
var _flap: float = 0.0
var _wings: Array[DragonWingRig] = []

@onready var _body: Node3D = $Body
@onready var _neck: Node3D = $Body/Neck
@onready var _head: Node3D = $Body/Neck/Head
@onready var _jaw: Node3D = $Body/Neck/Head/Jaw
@onready var _mouth: Node3D = $Body/Neck/Head/MouthGlow
@onready var _throat: Node3D = $Body/Neck/ThroatGlow
@onready var _tails: Array[Node3D] = [$Body/Tail, $Body/Tail/Tail2, $Body/Tail/Tail2/Tail3, $Body/Tail/Tail2/Tail3/Tail4]
@onready var _legs: Array[Node3D] = [$Body/LegFL, $Body/LegFR, $Body/LegBL, $Body/LegBR]
@onready var _knees: Array[Node3D] = [$Body/LegFL/Knee, $Body/LegFR/Knee, $Body/LegBL/Knee, $Body/LegBR/Knee]


func _ready() -> void:
	_wings = [DragonWingRig.new($Body/WingL, -1.0), DragonWingRig.new($Body/WingR, 1.0)]


## The point her flames come from, in world space.
func get_mouth() -> Vector3:
	return ($Body/Neck/Head/Mouth as Node3D).global_position


## Where her body is, as [node, radius] pairs, for keeping clear of pillars.
func get_probes(spread_wings: bool) -> Array:
	var probes: Array = [[$Body/Neck/Head/Mouth, 0.8], [$Body/Neck/Head/ProbeHead, 1.3], [$Body/Neck/ProbeNeck, 1.0], [$Body/ProbeChest, 1.9],
		[$Body, 1.9], [$Body/ProbeHips, 1.7], [$Body/Tail/Tail2/ProbeTail, 0.8], [$Body/Tail/Tail2/Tail3/Tail4/TailTip, 0.5]]
	if spread_wings:
		for side: String in ["L", "R"]:
			probes.append([get_node("Body/Wing%s/Fore/Hand/Finger1/Tip" % side), 0.4])
			probes.append([get_node("Body/Wing%s/Fore/Hand" % side), 0.4])
	# The radii are in model metres; the model may be scaled.
	for probe: Array in probes:
		probe[1] = float(probe[1]) * scale.x
	return probes


func _physics_process(delta: float) -> void:
	_time += delta
	var weight: float = 1.0 - exp(-SMOOTHING * delta)
	var fast: float = 1.0 - exp(-SMOOTHING * 2.5 * delta)
	var breathe: float = sin(_time * 1.6)
	var neck_pitch: float = 0.45 + sin(_time * 1.2) * 0.05
	var head_pitch: float = -0.27
	var jaw_open: float = 0.05
	var body_y: float = BODY_HEIGHT + breathe * 0.06
	var body_pitch: float = 0.0
	var body_roll: float = 0.0
	var tail_lift: float = 0.04
	var fold: float = 1.0
	var lift: float = 0.0
	var flex: float = 0.0
	var legs: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var knees: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var gait: float = 0.0
	match pose:
		Pose.IDLE:
			gait = clampf(walk_speed / 4.0, 0.0, 1.0)
		Pose.RUN:
			gait = 1.6
			neck_pitch = 0.18
			head_pitch = 0.0
			body_pitch = -0.06
			fold = 0.55
			lift = 0.25 + sin(_time * 6.0) * 0.12
			tail_lift = 0.12
		Pose.INHALE:
			neck_pitch = 0.95
			head_pitch = -0.45
			jaw_open = 0.5
			body_y += 0.35
			body_pitch = 0.12
			fold = 0.8
			lift = 0.3
		Pose.BREATH:
			neck_pitch = 0.08 + sin(_time * 3.0) * 0.03
			head_pitch = 0.08
			jaw_open = 0.75
			body_pitch = -0.08
			legs = [-0.25, -0.25, 0.2, 0.2]
		Pose.PANT:
			neck_pitch = -0.22
			head_pitch = 0.25
			jaw_open = 0.3 + sin(_time * 8.0) * 0.12
			body_y -= 0.45
			knees = [0.35, 0.35, -0.35, -0.35]
		Pose.TAIL:
			body_roll = 0.08
			neck_pitch = 0.3
		Pose.WINGS, Pose.ROAR:
			body_y += 0.6
			body_pitch = 0.28
			neck_pitch = 0.75 if pose == Pose.WINGS else 1.05
			head_pitch = -0.3 if pose == Pose.WINGS else -0.55
			jaw_open = 0.35 if pose == Pose.WINGS else 0.95
			legs = [0.6, 0.6, -0.25, -0.25]
			knees = [-0.9, -0.9, 0.1, 0.1]
			fold = 0.0 if pose == Pose.WINGS else 0.35
			var beat: float = sin(_time * 9.0)
			lift = 0.55 + beat * 0.6 if pose == Pose.WINGS else 0.7
			flex = maxf(beat, 0.0) * 0.6 if pose == Pose.WINGS else 0.2
			tail_lift = -0.05
		Pose.TAKEOFF:
			body_y -= 0.7
			body_pitch = 0.15
			neck_pitch = 0.65
			fold = 0.0
			lift = 1.0
			flex = 0.5
			knees = [0.6, 0.6, -0.6, -0.6]
		Pose.FLY, Pose.LAND:
			_flap = fmod(_flap + delta * FLAP_RATE * (1.6 if pose == Pose.LAND else 1.0), 1.0)
			# A quick, strong downstroke and a slower upstroke with bent wings.
			var down: bool = _flap < 0.4
			var t: float = _flap / 0.4 if down else (_flap - 0.4) / 0.6
			lift = lerpf(1.0, -0.65, _ease(t)) if down else lerpf(-0.65, 1.0, _ease(t))
			flex = 0.0 if down else sin(t * PI) * 0.9
			fold = 0.0
			body_y += (sin(_flap * TAU + 0.9) * 0.35)
			body_pitch = 0.12 if pose == Pose.FLY else 0.38
			neck_pitch = 0.1
			head_pitch = 0.35
			tail_lift = -0.18 + sin(_time * 2.2) * 0.05
			if pose == Pose.FLY:
				legs = [0.9, 0.9, -0.8, -0.8]
				knees = [-1.2, -1.2, 0.9, 0.9]
			else:
				legs = [-0.2, -0.2, 0.15, 0.15]
		Pose.DAZED:
			body_y -= 1.05
			body_roll = 0.14
			neck_pitch = -0.35
			head_pitch = 0.3
			jaw_open = 0.25
			fold = 0.7
			lift = -0.4
			knees = [0.9, 0.9, -0.9, -0.9]
			tail_lift = -0.05
		Pose.DEAD:
			body_y -= 1.45
			body_roll = 0.4
			neck_pitch = -0.5
			head_pitch = 0.4
			jaw_open = 0.4
			fold = 0.6
			lift = -0.3
			knees = [1.0, 1.0, -1.0, -1.0]
			tail_lift = -0.05
	if gait > 0.0:
		_stride = fmod(_stride + delta * (1.6 + walk_speed * 0.55), TAU)
		for i: int in 4:
			# Diagonal pairs move together; a leg bends its knee as it lifts.
			var phase: float = _stride + (PI if i in [1, 2] else 0.0)
			legs[i] = sin(phase) * 0.42 * minf(gait, 1.3)
			var raise: float = maxf(-cos(phase), 0.0) * 0.7 * minf(gait, 1.3)
			knees[i] = -raise if i < 2 else raise
		body_y += absf(sin(_stride)) * 0.12 * minf(gait, 1.0)
		body_roll += sin(_stride) * 0.03 * minf(gait, 1.0)
	neck_pitch += look_pitch
	_mouth.visible = pose in [Pose.INHALE, Pose.BREATH]
	_throat.visible = pose == Pose.INHALE
	_neck.rotation.x = lerp_angle(_neck.rotation.x, neck_pitch, weight)
	_neck.rotation.y = lerp_angle(_neck.rotation.y, sin(_time * 0.7) * 0.06, weight)
	_head.rotation.x = lerp_angle(_head.rotation.x, head_pitch, weight)
	_jaw.rotation.x = lerp_angle(_jaw.rotation.x, -jaw_open, fast)
	_body.position.y = lerpf(_body.position.y, body_y, fast if pose in [Pose.FLY, Pose.LAND] else weight)
	_body.rotation.x = lerp_angle(_body.rotation.x, body_pitch, weight)
	_body.rotation.z = lerp_angle(_body.rotation.z, body_roll, weight)
	for i: int in _tails.size():
		var sway: float = sin(_time * 1.5 - float(i) * 0.6) * (0.12 + 0.05 * float(i))
		var sweep: float = tail_sweep * (1.0 if i == 0 else 0.45)
		_tails[i].rotation.y = lerp_angle(_tails[i].rotation.y, sway + sweep, weight)
		_tails[i].rotation.x = lerp_angle(_tails[i].rotation.x, tail_lift, weight)
	for wing: DragonWingRig in _wings:
		wing.apply(fold, lift, flex, fast if pose in [Pose.FLY, Pose.LAND, Pose.WINGS] else weight)
	for i: int in 4:
		_legs[i].rotation.x = lerp_angle(_legs[i].rotation.x, legs[i], fast)
		_knees[i].rotation.x = lerp_angle(_knees[i].rotation.x, knees[i], fast)


func _ease(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)
