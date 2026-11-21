class_name GrumpyOma
extends CharacterBody3D
## Grumpy Oma, boss of the Bingo Club: the number 1 bingo winner, a loyal
## follower of Amber and the messiah of the grandmas and grandpas. A huge,
## hunched beast of a grandma. She lumbers after the player and gives a slow,
## clearly visible slap with her handbag, after which she has to catch her
## breath; parrying the slap knocks the wind out of her. Every few seconds she
## jumps and slams the ground (a shockwave runs over the floor: jump over it)
## or spins through the arena like a tornado, during which hits bounce off.
## After a slam, a tornado or a parry she is exhausted and takes extra damage.
## At two thirds and one third of her health she roars BINGO! and her
## followers come to help, fired up. Below 30% health she gets faster and
## slams twice in a row. Her slap often comes with a quick second backhand,
## and a player who keeps away gets a fan of bingo cards thrown at them, so
## shooting her from a distance is no safe way to win.
## Saving is blocked and the gate is closed during the fight; once beaten a
## GameState flag keeps her beaten.

enum Mode { WAITING, CHASE, SLAP, JUMP, SPIN, EXHAUSTED, ROAR, DEAD, THROW }

## Health, slap damage and loot.
@export var data: EnemyData
@export var defeated_flag: StringName = &"boss_grumpy_oma"
## StaticBody3D that closes the arena while the fight lasts.
@export var gate_path: NodePath
@export var start_radius: float = 13.0
@export var walk_speed: float = 3.8
@export var slap_range: float = 3.4
## Seconds the slap is telegraphed before it hits.
@export var slap_windup: float = 0.8
## Seconds after the slap that she stands catching her breath.
@export var slap_recovery: float = 1.1
## Seconds of chasing before she slaps again.
@export var slap_cooldown: float = 0.3
## Chance of a quick second backhand after a slap (always when enraged).
@export_range(0.0, 1.0) var combo_chance: float = 0.5
## Seconds the backhand is telegraphed.
@export var combo_windup: float = 0.45
## Seconds of chasing before her next slam or tornado.
@export var special_interval: float = 4.0
@export var jump_crouch: float = 0.5
@export var jump_time: float = 1.0
@export var jump_height: float = 5.0
@export var shockwave_scene: PackedScene
@export var shockwave_damage: int = 18
@export var spin_time: float = 3.5
@export var spin_speed: float = 6.2
@export var spin_damage: int = 12
@export var exhausted_time: float = 1.8
## Damage multiplier while she is exhausted.
@export var exhausted_damage_factor: float = 1.35
@export_range(0.0, 1.0) var enrage_below: float = 0.3
@export var enrage_speed_factor: float = 1.3
## Health ratios at which she roars BINGO! and calls followers.
@export var call_at: Array[float] = [0.66, 0.33]
## Followers, two per call, in order.
@export var follower_scenes: Array[PackedScene] = []
## Where the followers come in, from where she started, two per call.
@export var follower_offsets: Array[Vector3] = []
@export var roar_time: float = 1.6
@export_group("Bingo cards")
## She throws cards at a player who stays further away than this.
@export var throw_distance: float = 4.5
## Seconds the player must stay out of reach before she throws.
@export var throw_patience: float = 1.2
@export var throw_cooldown: float = 4.0
@export var throw_windup: float = 0.6
@export var card_scene: PackedScene
@export var card_count: int = 5
@export var card_spread: float = 40.0
@export var card_damage: int = 10
@export_group("")
@export var follower_buff: float = 1.25
@export var follower_buff_time: float = 6.0
@export_multiline var intro_message: String = "Grumpy Oma: \"Ik ben de nummer 1 van de bingo! Voor Amber!\""
@export_multiline var roar_message: String = "Grumpy Oma: \"BINGO! Volgelingen, helpt uw kampioen!\""
@export_multiline var defeat_message: String = "Grumpy Oma is verslagen! De Bingo Club is bevrijd."

const SAVE_BLOCK: StringName = &"boss"
const CORPSE_TIME: float = 4.0
const SPIN_HIT_EVERY: float = 0.7

var mode: Mode = Mode.WAITING
## How many slams and tornados she has done, for tests.
var specials_done: int = 0
## How many fans of cards she threw, for tests.
var throws: int = 0
## How many times she called her followers, for tests.
var followers_called: int = 0
var _timer: float = 0.0
var _special_timer: float = 0.0
var _slap_wait: float = 0.0
var _next_is_slam: bool = true
var _swung: bool = false
var _panting: bool = false
var _jumped: bool = false
var _jump_from: Vector3
var _jump_to: Vector3
var _start: Vector3
var _combo: bool = false
var _second_jump: bool = false
var _far_time: float = 0.0
var _throw_wait: float = 0.0
var _gate: StaticBody3D

@onready var model: HumanoidModel = $Model
@onready var health: HealthComponent = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _hitbox: Hitbox = $AttackHitbox
@onready var _loot_dropper: LootDropper = $LootDropper
@onready var _tired_label: Label3D = $TiredLabel
@onready var _shout_label: Label3D = $ShoutLabel


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
	_hitbox.parried.connect(_on_parried)
	_loot_dropper.loot = data.loot
	_start = global_position
	_tired_label.visible = false
	_shout_label.visible = false


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
			_chase(to_player, player.global_position, delta)
		Mode.SLAP:
			_slap(to_player, delta)
		Mode.JUMP:
			_jump(delta)
		Mode.SPIN:
			_timer -= delta
			model.rotation.y += 16.0 * delta
			_move(to_player.normalized() * spin_speed * _speed_factor())
			if fmod(_timer, SPIN_HIT_EVERY) < delta:
				_hitbox.activate(spin_damage)
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
		Mode.ROAR:
			_timer -= delta
			_face(to_player)
			if _timer <= 0.0:
				_shout_label.visible = false
				mode = Mode.CHASE
		Mode.THROW:
			_throw(to_player, player, delta)


func _chase(to_player: Vector3, player_position: Vector3, delta: float) -> void:
	_face(to_player)
	if followers_called < call_at.size() and health.get_ratio() <= call_at[followers_called]:
		_roar()
		return
	_special_timer -= delta * _speed_factor()
	_slap_wait -= delta
	_throw_wait -= delta
	# Time the player has stayed out of reach; it resets once she gets close.
	if to_player.length() > throw_distance:
		_far_time += delta
	elif to_player.length() <= slap_range:
		_far_time = 0.0
	if _special_timer <= 0.0:
		if _next_is_slam:
			_begin_jump(player_position)
		else:
			_begin_spin()
		_next_is_slam = not _next_is_slam
	elif _far_time >= throw_patience and _throw_wait <= 0.0 and card_scene != null:
		_begin_throw()
	elif to_player.length() <= slap_range:
		if _slap_wait <= 0.0:
			_begin_slap()
		else:
			_move(Vector3.ZERO)
	else:
		_move(to_player.normalized() * walk_speed * _speed_factor())


func _slap(to_player: Vector3, delta: float) -> void:
	_timer += delta * _speed_factor()
	if not _swung:
		# She only aims during the first half of the windup, so a dodge works.
		if _timer < slap_windup * 0.5:
			_face(to_player)
		if _timer >= slap_windup:
			_swung = true
			_hitbox.activate(data.damage)
			model.play_action(&"punch", 0.4)
			AudioManager.play_sfx_at(&"sword_heavy", global_position, self)
		return
	if _timer >= slap_windup + 0.25:
		_hitbox.deactivate()
	if _combo and _timer >= slap_windup + 0.3:
		# A quick backhand right after the slap.
		_combo = false
		_swung = false
		_timer = slap_windup - combo_windup
		model.play_action(&"enemy_windup", combo_windup, true)
		return
	if _timer >= slap_windup + 0.4 and not _panting:
		_panting = true
		model.play_action(&"cough", slap_recovery - 0.4)
	if _timer >= slap_windup + slap_recovery:
		_slap_wait = slap_cooldown
		mode = Mode.CHASE


func _jump(delta: float) -> void:
	_timer += delta
	if not _jumped:
		if _timer >= jump_crouch:
			_jumped = true
			_timer = 0.0
		return
	var t: float = clampf(_timer / jump_time, 0.0, 1.0)
	global_position = _jump_from.lerp(_jump_to, t) + Vector3.UP * jump_height * 4.0 * t * (1.0 - t)
	if t >= 1.0:
		_land()


func _start_fight() -> void:
	GameState.block_saving(SAVE_BLOCK)
	EventBus.boss_started.emit(data.display_name, health.max_health)
	EventBus.message_requested.emit(intro_message)
	_set_gate(true)
	_special_timer = special_interval
	mode = Mode.CHASE


func _begin_slap() -> void:
	mode = Mode.SLAP
	_timer = 0.0
	_swung = false
	_panting = false
	_combo = is_enraged() or randf() < combo_chance
	model.play_action(&"enemy_windup", slap_windup, true)


func _begin_jump(target: Vector3) -> void:
	mode = Mode.JUMP
	specials_done += 1
	_timer = 0.0
	_jumped = false
	_jump_from = global_position
	_jump_to = Vector3(target.x, _start.y, target.z)
	model.play_action(&"enemy_windup", jump_crouch, true)


func _land() -> void:
	global_position = _jump_to
	AudioManager.play_sfx_at(&"shockwave", global_position, self, 2.0)
	if shockwave_scene != null:
		var wave: Node3D = shockwave_scene.instantiate() as Node3D
		get_parent().add_child(wave)
		wave.global_position = global_position
		wave.call(&"start", shockwave_damage, self)
	# Enraged, she jumps at the player once more before she is out of breath.
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	if is_enraged() and not _second_jump and player != null:
		_second_jump = true
		_begin_jump(player.global_position)
		return
	_second_jump = false
	_exhaust()


func _begin_throw() -> void:
	mode = Mode.THROW
	_timer = 0.0
	_swung = false
	_throw_wait = throw_cooldown
	_shout_label.text = "BINGO-KAARTEN!"
	_shout_label.visible = true
	model.play_action(&"enemy_windup", throw_windup, true)


## Throws a fan of bingo cards at the player, then goes on.
func _throw(to_player: Vector3, player: Player, delta: float) -> void:
	_timer += delta * _speed_factor()
	if not _swung:
		_face(to_player)
		if _timer >= throw_windup:
			_swung = true
			throws += 1
			AudioManager.play_sfx_at(&"kick", global_position, self)
			model.play_action(&"punch", 0.4)
			var origin: Vector3 = global_position + Vector3.UP * 2.0 - global_basis.z * 1.0
			var aim: Vector3 = player.global_position + Vector3.UP * 1.1 - origin
			for n: int in card_count:
				var angle: float = deg_to_rad(lerpf(-card_spread, card_spread, float(n) / maxf(card_count - 1, 1)) * 0.5)
				var card: Node3D = card_scene.instantiate() as Node3D
				get_parent().add_child(card)
				card.call(&"launch", origin, aim.rotated(Vector3.UP, angle), card_damage, self)
		return
	if _timer >= throw_windup + 0.5:
		_shout_label.visible = false
		_far_time = 0.0
		mode = Mode.CHASE


func _begin_spin() -> void:
	mode = Mode.SPIN
	specials_done += 1
	_timer = spin_time
	_hitbox.activate(spin_damage)


func _exhaust() -> void:
	mode = Mode.EXHAUSTED
	_timer = exhausted_time
	_tired_label.visible = true
	model.play_action(&"cough", exhausted_time)


## Roars BINGO! and calls the next two followers; every bingo enemy nearby
## gets fired up.
func _roar() -> void:
	mode = Mode.ROAR
	_timer = roar_time
	_shout_label.text = "BINGO!!"
	AudioManager.play_sfx_at(&"bingo", global_position, self, 2.0)
	_shout_label.visible = true
	model.play_action(&"flex", roar_time)
	EventBus.message_requested.emit(roar_message)
	var parent: Node3D = get_parent() as Node3D
	for i: int in [followers_called * 2, followers_called * 2 + 1]:
		if i >= follower_scenes.size() or i >= follower_offsets.size():
			continue
		var follower: Node3D = follower_scenes[i].instantiate() as Node3D
		# Placed before it enters the tree, so the spot becomes its home.
		follower.position = parent.to_local(_start + follower_offsets[i])
		parent.add_child(follower)
		follower.call(&"notice_player")
	followers_called += 1
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var other: Enemy = node as Enemy
		if other != null and other.data.faction == data.faction and other.global_position.distance_to(global_position) <= 30.0:
			other.buff_damage(follower_buff, follower_buff_time, "WOEST!")


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
	if mode in [Mode.WAITING, Mode.DEAD, Mode.SPIN, Mode.JUMP]:
		return
	var factor: float = exhausted_damage_factor if mode == Mode.EXHAUSTED else 1.0
	health.take_damage(roundi(hit.damage * factor))


func _on_parried() -> void:
	if mode == Mode.SLAP:
		_hitbox.deactivate()
		_exhaust()


func _on_died() -> void:
	mode = Mode.DEAD
	_hitbox.deactivate()
	_hurtbox.set_enabled(false)
	_tired_label.visible = false
	_shout_label.visible = false
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
