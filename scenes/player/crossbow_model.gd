class_name CrossbowModel
extends Node3D
## The crossbow from tools/models/gen_crossbow.py. The string runs from the
## two limb tips to where it sits: back at the nut when spanned, forward
## against the prod right after a shot. Spanning bends the limbs back; the
## bolt lies in the groove once the string is back at the nut.

## How far the limbs bend when spanned, in radians.
const LIMB_BEND: float = 0.22

## 0 is just shot (string forward, no bolt), 1 is spanned and loaded.
var draw: float = 1.0

@onready var _limbs: Array[Node3D] = [$LimbL, $LimbR]
@onready var _strings: Array[MeshInstance3D] = [$StringL, $StringR]
@onready var _drawn: Node3D = $Drawn
@onready var _released: Node3D = $Released
@onready var _bolt: Node3D = $LoadedBolt


## Where a shot bolt leaves the crossbow, in world space.
func get_muzzle() -> Vector3:
	return ($Muzzle as Node3D).global_position


func _physics_process(_delta: float) -> void:
	for i: int in 2:
		var side: float = -1.0 if i == 0 else 1.0
		_limbs[i].rotation.y = -side * LIMB_BEND * draw
	var point: Vector3 = _released.position.lerp(_drawn.position, draw)
	for i: int in 2:
		var limb: Node3D = _limbs[i]
		var tip: Vector3 = limb.transform * (limb.get_node("Tip") as Node3D).position
		var along: Vector3 = point - tip
		var string: MeshInstance3D = _strings[i]
		if along.length() < 0.001:
			continue
		var basis: Basis = Basis.looking_at(along.normalized(), Vector3.UP)
		string.transform = Transform3D(basis * Basis.from_scale(Vector3(1, 1, along.length())), tip + along * 0.5)
	_bolt.visible = draw >= 0.98
