class_name DragonWingRig
extends RefCounted
## Moves one bat wing of a dragon model (built by tools/models): the
## shoulder lifts and flaps, the elbow and wrist fold the wing along the body,
## and the fingers close their fan when folded. Used by Amber and the
## dragonlings, whose wings have the same joints:
## Wing{L,R} / Fore / Hand / Finger1..4 (each with a Tip marker).

## Rotations of a fully folded left wing (shoulder, forearm, hand); the right
## wing mirrors them.
const SHOULDER_FOLD: Vector3 = Vector3(0, 1.1, -0.75)
const FORE_FOLD: Vector3 = Vector3(0, 0.74, 1.055)
const HAND_FOLD: Vector3 = Vector3(0, -0.785, -0.157)
## Spread between the closed fingers, in radians.
const CLOSED_SPREAD: float = 0.07

var _side: float
var _shoulder: Node3D
var _fore: Node3D
var _hand: Node3D
var _fingers: Array[Node3D] = []
var _finger_angles: Array[float] = []


## [param side] is -1 for the left wing and 1 for the right one.
func _init(wing: Node3D, side: float) -> void:
	_side = side
	_shoulder = wing
	_fore = wing.get_node("Fore") as Node3D
	_hand = _fore.get_node("Hand") as Node3D
	for n: int in range(1, 5):
		var finger: Node3D = _hand.get_node_or_null("Finger%d" % n) as Node3D
		if finger == null:
			break
		_fingers.append(finger)
		var tip: Vector3 = (finger.get_node("Tip") as Node3D).position
		_finger_angles.append(atan2(tip.x, tip.z))


## Sets the wing: [param fold] 0 is spread and 1 folded; [param lift] turns
## the spread wing up (positive) or down at the shoulder; [param flex] bends
## elbow and wrist back, as in an upstroke. [param weight] smooths it.
func apply(fold: float, lift: float, flex: float, weight: float) -> void:
	var shoulder: Vector3 = Vector3(0, SHOULDER_FOLD.y * fold, SHOULDER_FOLD.z * fold - lift * (1.0 - fold))
	_shoulder.rotation = _shoulder.rotation.lerp(_mirrored(shoulder), weight)
	_fore.rotation = _fore.rotation.lerp(_mirrored(FORE_FOLD * fold + Vector3(0, 0.55 * flex, 0)), weight)
	_hand.rotation = _hand.rotation.lerp(_mirrored(HAND_FOLD * fold + Vector3(0, 0.35 * flex, 0)), weight)
	if _fingers.is_empty():
		return
	var middle: float = _finger_angles[mini(1, _finger_angles.size() - 1)]
	for n: int in _fingers.size():
		var closed: float = middle - _finger_angles[n] + CLOSED_SPREAD * float(n - 1) * signf(middle)
		_fingers[n].rotation.y = lerpf(_fingers[n].rotation.y, closed * fold, weight)


## The values above are for the left wing (side -1); the right one mirrors
## the turns about Y and Z.
func _mirrored(left: Vector3) -> Vector3:
	return left if _side < 0.0 else Vector3(left.x, -left.y, -left.z)
