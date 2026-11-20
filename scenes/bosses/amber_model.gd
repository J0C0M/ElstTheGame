class_name AmberModel
extends Node3D
## Amber's body from tools/models/gen_amber.py, animated in code: walking
## legs, a breathing body, a swaying neck and tail, wings that fold or flap,
## and a jaw that opens on a glowing throat. Amber sets the pose; the joints
## follow smoothly.

enum Pose { IDLE, INHALE, BREATH, PANT, TAIL, WINGS, FLY, DAZED, DEAD }

const SMOOTHING: float = 10.0
const BODY_HEIGHT: float = 3.0

var pose: Pose = Pose.IDLE
## Horizontal speed in metres per second, for the legs.
var walk_speed: float = 0.0
## Extra turn of the tail during a tail swipe, in radians.
var tail_sweep: float = 0.0
var _time: float = 0.0

@onready var _body: Node3D = $Body
@onready var _neck: Node3D = $Body/Neck
@onready var _head: Node3D = $Body/Neck/Head
@onready var _jaw: Node3D = $Body/Neck/Head/Jaw
@onready var _mouth: Node3D = $Body/Neck/Head/MouthGlow
@onready var _tail: Node3D = $Body/Tail
@onready var _tail2: Node3D = $Body/Tail/Tail2
@onready var _tail3: Node3D = $Body/Tail/Tail2/Tail3
@onready var _wing_l: Node3D = $Body/WingL
@onready var _wing_r: Node3D = $Body/WingR
@onready var _legs: Array[Node3D] = [$Body/LegFL, $Body/LegFR, $Body/LegBL, $Body/LegBR]


func _physics_process(delta: float) -> void:
	_time += delta
	var weight: float = 1.0 - exp(-SMOOTHING * delta)
	var neck_pitch: float = 0.45 + sin(_time * 1.2) * 0.05
	var jaw_open: float = 0.05
	var body_y: float = BODY_HEIGHT + sin(_time * 1.6) * 0.06
	var body_roll: float = 0.0
	match pose:
		Pose.INHALE:
			neck_pitch = 0.95
			jaw_open = 0.55
		Pose.BREATH:
			neck_pitch = 0.1 + sin(_time * 3.0) * 0.05
			jaw_open = 0.6
		Pose.PANT:
			neck_pitch = -0.2
			jaw_open = 0.3 + sin(_time * 8.0) * 0.1
			body_y = BODY_HEIGHT - 0.4
		Pose.DAZED:
			neck_pitch = -0.35
			jaw_open = 0.2
			body_y = BODY_HEIGHT - 1.0
		Pose.DEAD:
			neck_pitch = -0.4
			jaw_open = 0.4
			body_y = BODY_HEIGHT - 1.4
			body_roll = 0.35
	_mouth.visible = pose in [Pose.INHALE, Pose.BREATH]
	_neck.rotation.x = lerp_angle(_neck.rotation.x, neck_pitch, weight)
	_head.rotation.x = lerp_angle(_head.rotation.x, -neck_pitch * 0.6, weight)
	_jaw.rotation.x = lerp_angle(_jaw.rotation.x, -jaw_open, weight)
	_body.position.y = lerpf(_body.position.y, body_y, weight)
	_body.rotation.z = lerp_angle(_body.rotation.z, body_roll, weight)
	var sway: float = sin(_time * 1.5) * 0.2
	_tail.rotation.y = lerp_angle(_tail.rotation.y, sway + tail_sweep, weight)
	_tail2.rotation.y = lerp_angle(_tail2.rotation.y, sway * 0.8 + tail_sweep * 0.4, weight)
	_tail3.rotation.y = lerp_angle(_tail3.rotation.y, sway * 0.6, weight)
	_animate_wings(weight)
	_animate_legs(weight)


func _animate_wings(weight: float) -> void:
	var lift: float = -0.25
	if pose == Pose.FLY:
		lift = sin(_time * 7.0) * 0.9
	elif pose == Pose.WINGS:
		lift = sin(_time * 10.0) * 1.0
	elif pose in [Pose.DAZED, Pose.DEAD]:
		lift = -0.5
	# Folded wings lie along the body; open ones spread out and flap.
	var fold: float = 0.0 if pose in [Pose.FLY, Pose.WINGS] else 1.2
	_wing_l.rotation = _wing_l.rotation.lerp(Vector3(0, -fold, -lift), weight)
	_wing_r.rotation = _wing_r.rotation.lerp(Vector3(0, fold, lift), weight)


func _animate_legs(weight: float) -> void:
	for i: int in _legs.size():
		var swing: float = 0.0
		if pose == Pose.FLY:
			swing = 0.9
		elif walk_speed > 0.1:
			swing = sin(_time * walk_speed * 1.4 + (PI if i in [1, 2] else 0.0)) * 0.45
		_legs[i].rotation.x = lerp_angle(_legs[i].rotation.x, swing, weight)
