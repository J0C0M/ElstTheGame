class_name Villager
extends CharacterBody3D
## A cheerful villager in a liberated area. Wanders around where it stands,
## and when the player comes close it stops, waves and says a short line.
## Shirt, trousers, skin and hat come from [member look_seed], so every
## villager looks a little different.

## Lines the villager says, one at random each time.
@export var lines: PackedStringArray = PackedStringArray(["Dank je wel!", "Elst is weer van ons!"])
## How far from its starting spot the villager wanders.
@export var wander_radius: float = 4.0
@export var walk_speed: float = 1.3
## Seed for the colours and the hat.
@export var look_seed: int = 0

const TALK_DISTANCE: float = 3.5
const TALK_COOLDOWN: float = 8.0
const SPEECH_TIME: float = 3.0
const GRAVITY: float = 20.0
const SHIRTS: Array[Color] = [Color(0.85, 0.3, 0.3), Color(0.3, 0.55, 0.85), Color(0.95, 0.75, 0.25), Color(0.4, 0.7, 0.4),
		Color(0.8, 0.5, 0.8), Color(0.95, 0.95, 0.9), Color(0.95, 0.55, 0.2)]
const TROUSERS: Array[Color] = [Color(0.2, 0.25, 0.4), Color(0.35, 0.3, 0.25), Color(0.15, 0.15, 0.17), Color(0.5, 0.45, 0.35)]
const SKINS: Array[Color] = [Color(0.92, 0.76, 0.62), Color(0.78, 0.6, 0.46), Color(0.55, 0.38, 0.28)]
const HATS: Array[Color] = [Color(0.9, 0.2, 0.2), Color(0.2, 0.4, 0.8), Color(0.95, 0.85, 0.3), Color(0.3, 0.6, 0.35)]

var _home: Vector3
var _target: Vector3
var _wait: float = 0.0
var _talk_cooldown: float = 0.0
var _speech_left: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var model: HumanoidModel = $Model
@onready var _speech: Label3D = $Speech


func _ready() -> void:
	_home = global_position
	_rng.seed = look_seed
	_apply_look()
	_speech.visible = false
	_wait = _rng.randf_range(0.0, 3.0)
	_pick_target()


func _physics_process(delta: float) -> void:
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	_talk_cooldown -= delta
	_speech_left -= delta
	if _speech_left <= 0.0:
		_speech.visible = false
	var player: Node3D = get_tree().get_first_node_in_group(&"player") as Node3D
	var planar: Vector3 = Vector3.ZERO
	if player != null and global_position.distance_to(player.global_position) < TALK_DISTANCE:
		_face(player.global_position)
		if _talk_cooldown <= 0.0:
			_say()
	elif _wait > 0.0:
		_wait -= delta
	else:
		var to_target: Vector3 = _target - global_position
		to_target.y = 0.0
		if to_target.length() < 0.4:
			_wait = _rng.randf_range(2.0, 5.0)
			_pick_target()
		else:
			planar = to_target.normalized() * walk_speed
			_face(_target)
	velocity.x = planar.x
	velocity.z = planar.z
	move_and_slide()
	# Walked into a wall or a house: try somewhere else.
	if planar.length() > 0.0 and get_real_velocity().length() < walk_speed * 0.3:
		_pick_target()
	model.set_locomotion(Vector2(velocity.x, velocity.z).length(), false, is_on_floor())


func _say() -> void:
	_talk_cooldown = TALK_COOLDOWN
	_speech_left = SPEECH_TIME
	model.play_action(&"wave", 1.4)
	if not lines.is_empty():
		_speech.text = lines[_rng.randi() % lines.size()]
		_speech.visible = true


func _pick_target() -> void:
	var angle: float = _rng.randf() * TAU
	_target = _home + Vector3(cos(angle), 0.0, sin(angle)) * _rng.randf_range(1.0, wander_radius)


func _face(target: Vector3) -> void:
	var offset: Vector3 = target - global_position
	if Vector2(offset.x, offset.z).length() > 0.1:
		rotation.y = atan2(-offset.x, -offset.z)


func _apply_look() -> void:
	var shirt: Color = SHIRTS[_rng.randi() % SHIRTS.size()]
	var trousers: Color = TROUSERS[_rng.randi() % TROUSERS.size()]
	var skin: Color = SKINS[_rng.randi() % SKINS.size()]
	var hat: Color = HATS[_rng.randi() % HATS.size()]
	var colours: Dictionary[String, Color] = {"Chest": shirt, "Sleeve": shirt, "Leg": trousers, "Face": skin, "Fist": skin, "Beanie": hat}
	for part: Node in model.find_children("*", "MeshInstance3D", true, false):
		if colours.has(part.name):
			var material: StandardMaterial3D = StandardMaterial3D.new()
			material.albedo_color = colours[part.name]
			(part as MeshInstance3D).material_override = material
	model.get_node(^"Body/Hips/Torso/Head/Beanie").visible = _rng.randf() < 0.6
