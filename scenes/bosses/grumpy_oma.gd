class_name GrumpyOma
extends CharacterBody3D
## Grumpy Oma, boss of the Bingo Club: a huge, fat grandma who fights like a
## hulk. She chases the player and slaps up close, jumps and slams the ground
## (a shockwave runs over the floor: jump over it), and spins through the
## arena like a tornado. After a slam or a tornado she is exhausted for a
## moment and takes full damage; otherwise her handbag blocks most of it.
## Below 30% health she gets faster. Saving is blocked and the gate is closed
## during the fight; once beaten a GameState flag keeps her beaten.

enum Mode { WAITING, CHASE, SLAP, JUMP, SPIN, EXHAUSTED, DEAD }

## Health, slap damage and loot.
@export var data: EnemyData
@export var defeated_flag: StringName = &"boss_grumpy_oma"
## StaticBody3D that closes the arena while the fight lasts.
@export var gate_path: NodePath
@export var start_radius: float = 13.0
@export var walk_speed: float = 4.2
@export var slap_range: float = 3.0
@export var slap_windup: float = 0.45
## Seconds of chasing before her next slam or tornado.
@export var special_interval: float = 3.5
@export var jump_time: float = 0.9
@export var jump_height: float = 5.0
@export var shockwave_scene: PackedScene
@export var shockwave_damage: int = 20
@export var spin_time: float = 3.0
@export var spin_speed: float = 6.5
@export var exhausted_time: float = 2.0
## Share of the damage that gets through while she is not exhausted.
@export_range(0.0, 1.0) var guarded_damage_factor: float = 0.25
@export_range(0.0, 1.0) var enrage_below: float = 0.3
@export var enrage_speed_factor: float = 1.35
@export_multiline var defeat_message: String = "Grumpy Oma is verslagen! De Bingo Club is bevrijd."

const SAVE_BLOCK: StringName = &"boss"
const CORPSE_TIME: float = 4.0
const SLAP_TIME: float = 0.9
const SPIN_HIT_EVERY: float = 0.7

var mode: Mode = Mode.WAITING
## How many slams and tornados she has done, for tests.
var specials_done: int = 0
var _timer: float = 0.0
var _special_timer: float = 0.0
var _next_is_slam: bool = true
var _swung: bool = false
var _jump_from: Vector3
var _jump_to: Vector3
var _start: Vector3
var _gate: StaticBody3D

@onready var model: HumanoidModel = $Model
@onready var health: HealthComponent = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _hitbox: Hitbox = $AttackHitbox
@onready var _loot_dropper: LootDropper = $LootDropper
@onready var _tired_label: Label3D = $TiredLabel


func _ready() -> void:
	_gate = get_node_or_null(gate_path) as StaticBody3D
	_set_gate(false)
	if GameState.has_flag(defeated_flag):
		queue_free()
		return
	health.reset(data.get_max_health())
	health.health_changed.connect(func(current: int, maximum: int) -> void: EventBus.boss_health_changed.emit(current, maximum))
	health.died.connect(_on_died)
	_hurtbox.hit_received.connect(_on_hit_received)
	_loot_dropper.loot = data.loot
	_start = global_position
	_tired_label.visible = false


func is_enraged() -> bool:
	return health.current_health <= health.max_health * enrage_below


func _speed_factor() -> float:
	return enrage_speed_factor if is_enraged() else 1.0


func _physics_process(delta: float) -> void:
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	if player == null or mode == Mode.DEAD:
		return
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	match mode:
		Mode.WAITING:
			if to_player.length() <= start_radius:
				_start_fight()
		Mode.CHASE:
			_face(to_player)
			_special_timer -= delta * _speed_factor()
			if to_player.length() <= slap_range:
				_begin_slap()
			elif _special_timer <= 0.0:
				if _next_is_slam:
					_begin_jump(player.global_position)
				else:
					_begin_spin()
				_next_is_slam = not _next_is_slam
			else:
				_move(to_player.normalized() * walk_speed * _speed_factor())
		Mode.SLAP:
			_timer += delta * _speed_factor()
			if not _swung and _timer >= slap_windup:
				_swung = true
				_hitbox.activate(data.damage)
				model.play_action(&"punch", 0.4)
			elif _timer >= slap_windup + 0.25:
				_hitbox.deactivate()
			if _timer >= SLAP_TIME:
				mode = Mode.CHASE
		Mode.JUMP:
			_timer -= delta
			var t: float = clampf(1.0 - _timer / jump_time, 0.0, 1.0)
			global_position = _jump_from.lerp(_jump_to, t) + Vector3.UP * jump_height * 4.0 * t * (1.0 - t)
			if _timer <= 0.0:
				_land()
		Mode.SPIN:
			_timer -= delta
			model.rotation.y += 18.0 * delta
			_move(to_player.normalized() * spin_speed * _speed_factor())
			if fmod(_timer, SPIN_HIT_EVERY) < delta:
				_hitbox.activate(data.damage)
			if _timer <= 0.0:
				_hitbox.deactivate()
				model.rotation.y = 0.0
				_exhaust()
		Mode.EXHAUSTED:
			_timer -= delta
			if _timer <= 0.0:
				_tired_label.visible = false
				_special_timer = special_interval
				mode = Mode.CHASE


func _start_fight() -> void:
	GameState.block_saving(SAVE_BLOCK)
	EventBus.boss_started.emit(data.display_name, health.max_health)
	_set_gate(true)
	_special_timer = special_interval
	mode = Mode.CHASE


func _begin_slap() -> void:
	mode = Mode.SLAP
	_timer = 0.0
	_swung = false
	model.play_action(&"enemy_windup", slap_windup, true)


func _begin_jump(target: Vector3) -> void:
	mode = Mode.JUMP
	specials_done += 1
	_timer = jump_time
	_jump_from = global_position
	_jump_to = Vector3(target.x, _start.y, target.z)


func _land() -> void:
	global_position = _jump_to
	if shockwave_scene != null:
		var wave: Node3D = shockwave_scene.instantiate() as Node3D
		get_parent().add_child(wave)
		wave.global_position = global_position
		wave.call(&"start", shockwave_damage, self)
	_exhaust()


func _begin_spin() -> void:
	mode = Mode.SPIN
	specials_done += 1
	_timer = spin_time
	_hitbox.activate(data.damage)


func _exhaust() -> void:
	mode = Mode.EXHAUSTED
	_timer = exhausted_time
	_tired_label.visible = true
	model.play_action(&"cough", exhausted_time)


func _move(planar: Vector3) -> void:
	velocity = planar
	move_and_slide()
	model.set_locomotion(planar.length(), planar.length() > 5.0, true)


func _face(direction: Vector3) -> void:
	if direction.length() > 0.1:
		rotation.y = atan2(-direction.x, -direction.z)


func _set_gate(closed: bool) -> void:
	if _gate == null:
		return
	_gate.visible = closed
	for child: Node in _gate.get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).set_deferred(&"disabled", not closed)


func _on_hit_received(hit: HitData) -> void:
	if mode == Mode.WAITING or mode == Mode.DEAD:
		return
	var factor: float = 1.0 if mode == Mode.EXHAUSTED else guarded_damage_factor
	health.take_damage(maxi(roundi(hit.damage * factor), 1))


func _on_died() -> void:
	mode = Mode.DEAD
	_hitbox.deactivate()
	_hurtbox.set_enabled(false)
	_tired_label.visible = false
	model.rotation.y = 0.0
	model.play_action(&"death", 1.0, true)
	_loot_dropper.drop()
	GameState.set_flag(defeated_flag)
	EventBus.enemy_killed.emit(data.id)
	_end_fight()
	EventBus.message_requested.emit(defeat_message)
	SaveManager.request_autosave()
	await get_tree().create_timer(CORPSE_TIME, false).timeout
	var sink: Tween = create_tween()
	sink.tween_property(model, "position:y", -3.0, 1.5)
	sink.tween_callback(queue_free)


func _end_fight() -> void:
	GameState.unblock_saving(SAVE_BLOCK)
	EventBus.boss_ended.emit()
	_set_gate(false)


func _exit_tree() -> void:
	# Leaving mid-fight (the player died and a save loads) ends the fight too.
	if mode not in [Mode.WAITING, Mode.DEAD]:
		_end_fight()
