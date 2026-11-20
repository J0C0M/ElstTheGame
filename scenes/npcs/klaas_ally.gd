class_name KlaasAlly
extends CharacterBody3D
## Klaas as an ally in Amber's arena. Once he is ready (klaas_ready) he
## follows the player; in the fight he walks up to Amber and hits her, and
## she aims part of her attacks at him. Normal damage cannot kill him: he
## falls only in the scene where he saves the player, and lies there until
## the golden Tren syringe wakes him up.

enum Mode { WAITING, FOLLOW, FIGHT, STAGGER, FALLEN, STANDING }

@export var ready_flag: StringName = &"klaas_ready"
@export var damage: int = 14
@export var attack_interval: float = 1.6
@export var walk_speed: float = 5.0
## How close to the middle of Amber he stands to hit her; she is big.
@export var reach: float = 5.0

const FOLLOW_DISTANCE: float = 3.5
const SAY_TIME: float = 2.5
const HIT_LINES: Array[String] = ["Is dat alles, hagedis?", "Au. Nee hoor.", "Mijn bril zit nog. Gaat goed."]

var mode: Mode = Mode.WAITING
## Amber, from the moment the fight starts.
var amber: Node3D
var _attack_wait: float = 0.0
var _timer: float = 0.0
var _say_left: float = 0.0
var _told_crossbow: bool = false
var _gravity: float = 9.8

@onready var model: HumanoidModel = $Model
@onready var _label: Label3D = $Say
@onready var _collision: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	_label.visible = false
	EventBus.flag_set.connect(_on_flag_set)
	if GameState.has_flag(&"klaas_revived"):
		mode = Mode.STANDING
	elif GameState.has_flag(&"boss_amber"):
		mode = Mode.FALLEN
		model.play_action(&"death", 0.05, true)
	elif GameState.has_flag(ready_flag):
		mode = Mode.FOLLOW
	_apply_presence()


func is_fighting() -> bool:
	return mode in [Mode.FIGHT, Mode.STAGGER]


## Amber calls him into the fight.
func join_fight(boss: Node3D) -> void:
	amber = boss
	if mode in [Mode.WAITING, Mode.FOLLOW]:
		mode = Mode.FIGHT
		_apply_presence()
		say("Voor Elst!")


## Amber hit him: he staggers and grumbles, but does not fall.
func take_hit() -> void:
	if mode != Mode.FIGHT:
		return
	mode = Mode.STAGGER
	_timer = 0.8
	model.play_action(&"hurt", 0.5)
	say(HIT_LINES.pick_random())


## In the scene he takes the blow that was meant for the player.
func fall() -> void:
	mode = Mode.FALLEN
	velocity = Vector3.ZERO
	model.play_action(&"death", 1.2, true)


## The golden Tren syringe wakes him up again.
func revive() -> void:
	mode = Mode.STANDING
	model.reset_pose()
	model.play_action(&"flex", 1.4)


func say(text: String) -> void:
	_label.text = text
	_label.visible = true
	_say_left = SAY_TIME


func _physics_process(delta: float) -> void:
	_say_left -= delta
	if _say_left <= 0.0:
		_label.visible = false
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	var planar: Vector3 = Vector3.ZERO
	match mode:
		Mode.FOLLOW:
			if player != null:
				var to_player: Vector3 = _flat(player.global_position - global_position)
				if to_player.length() > FOLLOW_DISTANCE:
					planar = to_player.normalized() * walk_speed
				_face(to_player)
		Mode.FIGHT:
			planar = _fight(delta)
		Mode.STAGGER:
			_timer -= delta
			if _timer <= 0.0:
				mode = Mode.FIGHT
	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity.y -= _gravity * delta
	move_and_slide()
	model.set_locomotion(planar.length(), planar.length() > walk_speed - 0.5, is_on_floor())


func _fight(delta: float) -> Vector3:
	if amber == null or not is_instance_valid(amber):
		return Vector3.ZERO
	var to_amber: Vector3 = _flat(amber.global_position - global_position)
	_face(to_amber)
	if amber.call(&"is_flying"):
		if not _told_crossbow:
			_told_crossbow = true
			say("Pak je kruisboog!")
		return Vector3.ZERO
	_told_crossbow = false
	if to_amber.length() > reach:
		return to_amber.normalized() * walk_speed
	_attack_wait -= delta
	if _attack_wait <= 0.0:
		_attack_wait = attack_interval
		model.play_action(&"punch", 0.5)
		amber.call(&"take_ally_hit", damage)
	return Vector3.ZERO


func _face(direction: Vector3) -> void:
	if direction.length() > 0.1:
		rotation.y = atan2(-direction.x, -direction.z)


func _flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)


func _apply_presence() -> void:
	visible = mode != Mode.WAITING
	_collision.set_deferred(&"disabled", mode == Mode.WAITING)


func _on_flag_set(flag: StringName) -> void:
	if flag == ready_flag and mode == Mode.WAITING:
		mode = Mode.FOLLOW
		_apply_presence()
		say("Achter me aan.")
