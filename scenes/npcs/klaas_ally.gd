class_name KlaasAlly
extends CharacterBody3D
## Klaas as an ally in Amber's arena. Once he is ready (klaas_ready) he
## follows the player; in the fight he walks up to Amber and hits her, and
## she aims part of her attacks at him. Normal damage cannot kill him: he
## falls only in the scene where he saves the player, and lies there until
## the golden Tren syringe wakes him up: E next to him plays a short scene
## in which he gets up, and then the two of them go outside, where the end
## scene of the game plays (Ending, in the church square of Elst).

enum Mode { WAITING, FOLLOW, FIGHT, STAGGER, FALLEN, STANDING }

@export var ready_flag: StringName = &"klaas_ready"
@export var damage: int = 14
@export var attack_interval: float = 1.6
@export var walk_speed: float = 5.0
## How close to the middle of Amber he stands to hit her; she is big.
@export var reach: float = 5.0
## Where the two go after he wakes up: outside the church in Elst.
@export_file("*.tscn") var exit_scene: String = "res://scenes/world/Elst.tscn"
@export var exit_spawn: StringName = &"KerkExit"

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
@onready var _revive_spot: Interactable = $Revive


func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	_label.visible = false
	EventBus.flag_set.connect(_on_flag_set)
	_revive_spot.interacted.connect(_on_revive_used)
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
	_apply_presence()


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
	_revive_spot.enabled = mode == Mode.FALLEN


func _on_revive_used(player: Player) -> void:
	if not GameState.has_flag(&"tren_spuit_found"):
		EventBus.message_requested.emit("Je hebt de gouden Tren-spuit nodig. Amber liet hem vallen toen ze stierf.")
		return
	_revive_spot.enabled = false
	_play_revive(player)


## The player pushes the golden syringe into Klaas' arm; with a golden flash
## he gets up and flexes. Then the two go outside, where the end begins.
func _play_revive(player: Player) -> void:
	var scene: Cutscene = Cutscene.begin(get_parent() as Node3D)
	var side: Vector3 = global_basis.x.normalized()
	player.global_position = global_position + side * 1.3
	player.rotation.y = atan2(side.x, side.z)
	player.reset_physics_interpolation()
	scene.look(global_position + side * 3.6 - global_basis.z * 2.6 + Vector3.UP * 2.0, global_position + Vector3.UP * 0.4)
	await scene.say("", "Je drukt de gouden Tren-spuit in de arm van Klaas.", 2.4)
	player.model.play_action(&"punch", 0.6)
	var flash: OmniLight3D = OmniLight3D.new()
	flash.light_color = Color(1.0, 0.82, 0.3)
	flash.omni_range = 9.0
	flash.position = Vector3(0, 1.0, 0)
	add_child(flash)
	var glow: Tween = create_tween()
	glow.tween_property(flash, "light_energy", 8.0, 0.4).from(0.0)
	glow.tween_property(flash, "light_energy", 0.0, 1.2)
	glow.tween_callback(flash.queue_free)
	await scene.wait(0.9)
	revive()
	await scene.glide(global_position - global_basis.z * 3.2 + side * 1.5 + Vector3.UP * 1.9, global_position + Vector3.UP * 1.6, 1.0)
	await scene.say("Klaas", "...Tren?", 1.6)
	await scene.say("Klaas", "Zie je? Mijn bril is niet eens afgevallen.", 2.6)
	await scene.say("Klaas", "Amber is weg? Mooi. Kom, we gaan naar buiten. Elst wacht op ons.", 3.0)
	scene.finish()
	# The end scene plays outside the church; the flag makes it play again
	# after loading a save made before it was over.
	GameState.set_flag(&"ending_pending")
	GameState.set_flag(&"klaas_revived")
	EventBus.world_change_requested.emit(exit_scene, exit_spawn)


func _on_flag_set(flag: StringName) -> void:
	if flag == ready_flag and mode == Mode.WAITING:
		mode = Mode.FOLLOW
		_apply_presence()
		say("Achter me aan.")
