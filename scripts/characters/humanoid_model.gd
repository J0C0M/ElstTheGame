class_name HumanoidModel
extends Node3D
## Low-poly body made of boxes, animated in code, shared by the player and
## the human enemies. Walking, running and jumping are procedural; attacks,
## blocking, rolling, getting hit and dying are keyframed poses. A model scene
## needs the joints listed in _joints. Runs in _physics_process, so physics
## interpolation keeps it smooth.

## How quickly joints follow their target pose.
const SMOOTHING: float = 28.0
## Stride phase speed per metre per second of movement.
const STRIDE_RATE: float = 2.2
const BODY_BASE_POSITION: Vector3 = Vector3(0.0, 0.95, 0.0)

## Pose held while blocking: the sword raised across the body.
const GUARD_POSE: Dictionary = {
	&"arm_r": Vector3(70, 40, 0), &"hand": Vector3(0, 70, 0),
	&"arm_l": Vector3(60, -30, 0), &"torso": Vector3(0, 10, 0),
}

## Keyframed actions: lists of [time from 0 to 1, pose]. A pose maps joint
## names to rotations in degrees; "body_offset" moves the whole body in metres.
## Joints an action leaves out keep their walking or idle pose.
const ACTIONS: Dictionary = {
	&"attack_ready": [
		[0.0, {&"arm_r": Vector3(10, 0, 5), &"hand": Vector3(0, 0, 0)}],
		[1.0, {&"arm_r": Vector3(40, 0, 10), &"hand": Vector3(-30, 0, 0)}],
	],
	&"swing_light_1": [
		[0.0, {&"arm_r": Vector3(40, 0, 10), &"hand": Vector3(-30, 0, 0), &"torso": Vector3(0, 0, 0), &"arm_l": Vector3(0, 0, 0)}],
		[0.25, {&"arm_r": Vector3(80, -85, 0), &"hand": Vector3(-80, 0, 0), &"torso": Vector3(0, -35, 0), &"arm_l": Vector3(20, 0, -15)}],
		[0.55, {&"arm_r": Vector3(80, 55, 0), &"hand": Vector3(-80, 0, 0), &"torso": Vector3(0, 35, 0), &"arm_l": Vector3(-10, 0, -10)}],
		[1.0, {&"arm_r": Vector3(10, 0, 5), &"hand": Vector3(0, 0, 0), &"torso": Vector3(0, 0, 0), &"arm_l": Vector3(0, 0, 0)}],
	],
	&"swing_light_2": [
		[0.0, {&"arm_r": Vector3(70, 45, 0), &"hand": Vector3(-80, 0, 0), &"torso": Vector3(0, 30, 0), &"arm_l": Vector3(-10, 0, -10)}],
		[0.2, {&"arm_r": Vector3(85, 75, 10), &"hand": Vector3(-80, 0, 0), &"torso": Vector3(0, 40, 0), &"arm_l": Vector3(-15, 0, -10)}],
		[0.55, {&"arm_r": Vector3(80, -80, 0), &"hand": Vector3(-80, 0, 0), &"torso": Vector3(0, -35, 0), &"arm_l": Vector3(20, 0, -15)}],
		[1.0, {&"arm_r": Vector3(10, 0, 5), &"hand": Vector3(0, 0, 0), &"torso": Vector3(0, 0, 0), &"arm_l": Vector3(0, 0, 0)}],
	],
	&"swing_heavy": [
		[0.0, {&"arm_r": Vector3(40, 0, 10), &"hand": Vector3(-30, 0, 0), &"arm_l": Vector3(0, 0, 0), &"torso": Vector3(0, 0, 0), &"body_offset": Vector3.ZERO}],
		[0.4, {&"arm_r": Vector3(175, 10, 0), &"hand": Vector3(-60, 0, 0), &"arm_l": Vector3(150, -10, 0), &"torso": Vector3(12, 0, 0), &"body_offset": Vector3.ZERO}],
		[0.5, {&"arm_r": Vector3(165, 10, 0), &"hand": Vector3(-70, 0, 0), &"arm_l": Vector3(140, -10, 0), &"torso": Vector3(8, 0, 0), &"body_offset": Vector3.ZERO}],
		[0.65, {&"arm_r": Vector3(55, 0, 0), &"hand": Vector3(-90, 0, 0), &"arm_l": Vector3(50, -10, 0), &"torso": Vector3(-25, 0, 0), &"body_offset": Vector3(0, -0.1, 0), &"leg_l": Vector3(-20, 0, 0), &"leg_r": Vector3(25, 0, 0)}],
		[1.0, {&"arm_r": Vector3(10, 0, 5), &"hand": Vector3(0, 0, 0), &"arm_l": Vector3(0, 0, 0), &"torso": Vector3(0, 0, 0), &"body_offset": Vector3.ZERO, &"leg_l": Vector3(0, 0, 0), &"leg_r": Vector3(0, 0, 0)}],
	],
	&"parry": [
		[0.0, {&"arm_r": Vector3(70, 40, 0), &"hand": Vector3(0, 70, 0), &"torso": Vector3(0, 10, 0)}],
		[0.35, {&"arm_r": Vector3(100, -20, 0), &"hand": Vector3(-40, 30, 0), &"torso": Vector3(0, -15, 0)}],
		[1.0, {&"arm_r": Vector3(70, 40, 0), &"hand": Vector3(0, 70, 0), &"torso": Vector3(0, 10, 0)}],
	],
	&"block_impact": [
		[0.0, {&"torso": Vector3(0, 10, 0), &"body_offset": Vector3.ZERO}],
		[0.3, {&"torso": Vector3(12, 10, 0), &"body_offset": Vector3(0, -0.04, 0.08)}],
		[1.0, {&"torso": Vector3(0, 10, 0), &"body_offset": Vector3.ZERO}],
	],
	&"roll_forward": [
		[0.0, {&"body": Vector3(0, 0, 0), &"body_offset": Vector3.ZERO, &"torso": Vector3(0, 0, 0), &"head": Vector3(0, 0, 0), &"leg_l": Vector3(0, 0, 0), &"leg_r": Vector3(0, 0, 0), &"arm_l": Vector3(0, 0, 0), &"arm_r": Vector3(10, 0, 5)}],
		[0.15, {&"body": Vector3(-40, 0, 0), &"body_offset": Vector3(0, -0.3, 0), &"torso": Vector3(-45, 0, 0), &"head": Vector3(-30, 0, 0), &"leg_l": Vector3(100, 0, 0), &"leg_r": Vector3(110, 0, 0), &"arm_l": Vector3(70, 0, 0), &"arm_r": Vector3(70, 0, 0)}],
		[0.5, {&"body": Vector3(-180, 0, 0), &"body_offset": Vector3(0, -0.4, 0), &"torso": Vector3(-55, 0, 0), &"head": Vector3(-35, 0, 0), &"leg_l": Vector3(115, 0, 0), &"leg_r": Vector3(115, 0, 0), &"arm_l": Vector3(80, 0, 0), &"arm_r": Vector3(80, 0, 0)}],
		[0.85, {&"body": Vector3(-330, 0, 0), &"body_offset": Vector3(0, -0.3, 0), &"torso": Vector3(-35, 0, 0), &"head": Vector3(-20, 0, 0), &"leg_l": Vector3(70, 0, 0), &"leg_r": Vector3(50, 0, 0), &"arm_l": Vector3(40, 0, 0), &"arm_r": Vector3(40, 0, 0)}],
		[1.0, {&"body": Vector3(-360, 0, 0), &"body_offset": Vector3.ZERO, &"torso": Vector3(0, 0, 0), &"head": Vector3(0, 0, 0), &"leg_l": Vector3(0, 0, 0), &"leg_r": Vector3(0, 0, 0), &"arm_l": Vector3(0, 0, 0), &"arm_r": Vector3(10, 0, 5)}],
	],
	&"roll_back": [
		[0.0, {&"body": Vector3(0, 0, 0), &"body_offset": Vector3.ZERO, &"torso": Vector3(0, 0, 0), &"head": Vector3(0, 0, 0), &"leg_l": Vector3(0, 0, 0), &"leg_r": Vector3(0, 0, 0), &"arm_l": Vector3(0, 0, 0), &"arm_r": Vector3(10, 0, 5)}],
		[0.15, {&"body": Vector3(40, 0, 0), &"body_offset": Vector3(0, -0.3, 0), &"torso": Vector3(-45, 0, 0), &"head": Vector3(-30, 0, 0), &"leg_l": Vector3(100, 0, 0), &"leg_r": Vector3(110, 0, 0), &"arm_l": Vector3(70, 0, 0), &"arm_r": Vector3(70, 0, 0)}],
		[0.5, {&"body": Vector3(180, 0, 0), &"body_offset": Vector3(0, -0.4, 0), &"torso": Vector3(-55, 0, 0), &"head": Vector3(-35, 0, 0), &"leg_l": Vector3(115, 0, 0), &"leg_r": Vector3(115, 0, 0), &"arm_l": Vector3(80, 0, 0), &"arm_r": Vector3(80, 0, 0)}],
		[0.85, {&"body": Vector3(330, 0, 0), &"body_offset": Vector3(0, -0.3, 0), &"torso": Vector3(-35, 0, 0), &"head": Vector3(-20, 0, 0), &"leg_l": Vector3(70, 0, 0), &"leg_r": Vector3(50, 0, 0), &"arm_l": Vector3(40, 0, 0), &"arm_r": Vector3(40, 0, 0)}],
		[1.0, {&"body": Vector3(360, 0, 0), &"body_offset": Vector3.ZERO, &"torso": Vector3(0, 0, 0), &"head": Vector3(0, 0, 0), &"leg_l": Vector3(0, 0, 0), &"leg_r": Vector3(0, 0, 0), &"arm_l": Vector3(0, 0, 0), &"arm_r": Vector3(10, 0, 5)}],
	],
	&"hurt": [
		[0.0, {&"torso": Vector3(0, 0, 0), &"head": Vector3(0, 0, 0), &"arm_l": Vector3(0, 0, 0), &"arm_r": Vector3(10, 0, 5)}],
		[0.25, {&"torso": Vector3(22, 0, -6), &"head": Vector3(18, 0, 0), &"arm_l": Vector3(-25, 0, -20), &"arm_r": Vector3(-15, 0, 25)}],
		[1.0, {&"torso": Vector3(0, 0, 0), &"head": Vector3(0, 0, 0), &"arm_l": Vector3(0, 0, 0), &"arm_r": Vector3(10, 0, 5)}],
	],
	&"enemy_windup": [
		[0.0, {&"arm_r": Vector3(10, 0, 5), &"hand": Vector3(0, 0, 0), &"torso": Vector3(0, 0, 0), &"arm_l": Vector3(0, 0, 0)}],
		[1.0, {&"arm_r": Vector3(130, -40, 0), &"hand": Vector3(-60, 0, 0), &"torso": Vector3(-5, 25, 0), &"arm_l": Vector3(30, 0, -20)}],
	],
	&"punch": [
		[0.0, {&"arm_r": Vector3(130, -40, 0), &"hand": Vector3(-60, 0, 0), &"torso": Vector3(-5, 25, 0), &"arm_l": Vector3(30, 0, -20)}],
		[0.35, {&"arm_r": Vector3(92, -8, 0), &"hand": Vector3(-90, 0, 0), &"torso": Vector3(-12, -25, 0), &"arm_l": Vector3(40, 0, -10)}],
		[1.0, {&"arm_r": Vector3(10, 0, 5), &"hand": Vector3(0, 0, 0), &"torso": Vector3(0, 0, 0), &"arm_l": Vector3(0, 0, 0)}],
	],
	&"death": [
		[0.0, {&"body": Vector3(0, 0, 0), &"body_offset": Vector3.ZERO, &"arm_l": Vector3(0, 0, 0), &"arm_r": Vector3(10, 0, 5), &"hand": Vector3(0, 0, 0), &"head": Vector3(0, 0, 0)}],
		[0.35, {&"body": Vector3(25, 0, 0), &"body_offset": Vector3(0, -0.2, 0), &"arm_l": Vector3(-30, 0, -40), &"arm_r": Vector3(-30, 0, 40), &"hand": Vector3(-60, 0, 0), &"head": Vector3(20, 0, 0)}],
		[1.0, {&"body": Vector3(88, 0, 0), &"body_offset": Vector3(0, -0.78, 0), &"arm_l": Vector3(-10, 0, -80), &"arm_r": Vector3(-10, 0, 80), &"hand": Vector3(-90, 0, 0), &"head": Vector3(10, 20, 0)}],
	],
}

var _speed: float = 0.0
var _sprinting: bool = false
var _on_floor: bool = true
var _stride_phase: float = 0.0
var _idle_time: float = 0.0
var _guard: bool = false
var _guard_weight: float = 0.0
var _action: StringName = &""
var _action_time: float = 0.0
var _action_duration: float = 1.0
var _action_hold: bool = false

@onready var _body: Node3D = $Body
@onready var _joints: Dictionary[StringName, Node3D] = {
	&"body": $Body,
	&"hips": $Body/Hips,
	&"torso": $Body/Hips/Torso,
	&"head": $Body/Hips/Torso/Head,
	&"arm_l": $Body/Hips/Torso/ArmL,
	&"arm_r": $Body/Hips/Torso/ArmR,
	&"hand": $Body/Hips/Torso/ArmR/Hand,
	&"leg_l": $Body/Hips/LegL,
	&"leg_r": $Body/Hips/LegR,
}


func _physics_process(delta: float) -> void:
	var pose: Dictionary[StringName, Vector3] = _locomotion_pose(delta)
	_guard_weight = move_toward(_guard_weight, 1.0 if _guard else 0.0, delta * 10.0)
	if _guard_weight > 0.0:
		_blend_into(pose, GUARD_POSE, _guard_weight)
	if _action != &"":
		_action_time += delta
		var progress: float = _action_time / _action_duration
		if progress >= 1.0 and not _action_hold:
			_action = &""
		else:
			_blend_into(pose, _sample(ACTIONS[_action], minf(progress, 1.0)), 1.0)
	_apply(pose, 1.0 - exp(-SMOOTHING * delta))


## Speed is the horizontal speed in metres per second.
func set_locomotion(speed: float, sprinting: bool, on_floor: bool) -> void:
	_speed = speed
	_sprinting = sprinting
	_on_floor = on_floor


## Holds the blocking pose while [param active] is true.
func set_guard(active: bool) -> void:
	_guard = active


## Plays a keyframed action from ACTIONS over [param duration] seconds. With
## [param hold_last_frame] the last pose stays until another action plays.
func play_action(action: StringName, duration: float, hold_last_frame: bool = false) -> void:
	if not ACTIONS.has(action):
		push_error("HumanoidModel has no action %s." % action)
		return
	_action = action
	_action_time = 0.0
	_action_duration = maxf(duration, 0.01)
	_action_hold = hold_last_frame


func stop_action() -> void:
	_action = &""


## Snaps straight back to the idle pose, for example after a respawn.
func reset_pose() -> void:
	_action = &""
	_guard = false
	_guard_weight = 0.0
	_apply({}, 1.0)


func _locomotion_pose(delta: float) -> Dictionary[StringName, Vector3]:
	var pose: Dictionary[StringName, Vector3] = {}
	_idle_time += delta
	if not _on_floor:
		pose[&"leg_l"] = Vector3(35, 0, 0)
		pose[&"leg_r"] = Vector3(-15, 0, 0)
		pose[&"arm_l"] = Vector3(-25, 0, -20)
		pose[&"arm_r"] = Vector3(30, 0, 20)
		pose[&"torso"] = Vector3(-5, 0, 0)
		return pose
	var amount: float = clampf(_speed / 4.5, 0.0, 1.6)
	_stride_phase = fmod(_stride_phase + delta * _speed * STRIDE_RATE, TAU)
	var swing: float = sin(_stride_phase)
	var leg_amplitude: float = 28.0 * amount
	var breathing: float = sin(_idle_time * 2.0) * 1.5 * (1.0 - minf(amount, 1.0))
	pose[&"leg_l"] = Vector3(swing * leg_amplitude, 0, 0)
	pose[&"leg_r"] = Vector3(-swing * leg_amplitude, 0, 0)
	pose[&"arm_l"] = Vector3(-swing * leg_amplitude * 0.8, 0, -4)
	pose[&"arm_r"] = Vector3(10.0 + swing * leg_amplitude * 0.6, 0, 5)
	pose[&"torso"] = Vector3(-6.0 * amount - (6.0 if _sprinting else 0.0) + breathing, 0, 0)
	pose[&"body_offset"] = Vector3(0, absf(swing) * 0.05 * minf(amount, 1.0), 0)
	return pose


## Overwrites joints in [param pose] with [param other], blended by [param weight].
func _blend_into(pose: Dictionary[StringName, Vector3], other: Dictionary, weight: float) -> void:
	for key: StringName in other:
		var target: Vector3 = other[key]
		pose[key] = pose.get(key, Vector3.ZERO).lerp(target, weight)


func _sample(keyframes: Array, progress: float) -> Dictionary:
	var index: int = 0
	while index < keyframes.size() - 2 and progress > float(keyframes[index + 1][0]):
		index += 1
	var from_time: float = keyframes[index][0]
	var to_time: float = keyframes[index + 1][0]
	var from_pose: Dictionary = keyframes[index][1]
	var to_pose: Dictionary = keyframes[index + 1][1]
	var local: float = clampf(inverse_lerp(from_time, to_time, progress), 0.0, 1.0)
	local = smoothstep(0.0, 1.0, local)
	var result: Dictionary = {}
	for key: StringName in to_pose:
		var start: Vector3 = from_pose.get(key, Vector3.ZERO)
		var end: Vector3 = to_pose[key]
		result[key] = start.lerp(end, local)
	return result


func _apply(pose: Dictionary, weight: float) -> void:
	for joint_name: StringName in _joints:
		var joint: Node3D = _joints[joint_name]
		var degrees: Vector3 = pose.get(joint_name, Vector3.ZERO)
		var target: Vector3 = Vector3(deg_to_rad(degrees.x), deg_to_rad(degrees.y), deg_to_rad(degrees.z))
		joint.rotation = Vector3(
			lerp_angle(joint.rotation.x, target.x, weight),
			lerp_angle(joint.rotation.y, target.y, weight),
			lerp_angle(joint.rotation.z, target.z, weight))
	var offset: Vector3 = pose.get(&"body_offset", Vector3.ZERO)
	_body.position = _body.position.lerp(BODY_BASE_POSITION + offset, weight)
