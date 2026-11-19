class_name FatbikeKid
extends CharacterBody3D
## Het fatbike-kindje, boss of OBC Elst Fort: a tiny kid on a far too big,
## souped-up fatbike. He revs up while a red line on the ground shows where he
## will go, then charges in a straight line; below half health twice in a row.
## When he crashes into a wall he is dazed for a few seconds, and only then can
## the player hurt him. Saving is blocked and the arena gate is closed during
## the fight. Once beaten a GameState flag keeps him beaten and OBC liberated.

enum Mode { WAITING, AIMING, CHARGING, DAZED, DEAD }

## Health, charge damage and loot.
@export var data: EnemyData
## GameState flag set when he is beaten.
@export var defeated_flag: StringName = &"boss_fatbike_kindje"
## StaticBody3D that closes the arena while the fight lasts.
@export var gate_path: NodePath
## The fight starts when the player comes this close to where he waits.
@export var start_radius: float = 14.0
## Seconds he revs up before a charge, and before a second charge in a row.
@export var aim_time: float = 1.4
@export var aim_time_quick: float = 0.7
@export var charge_speed: float = 16.0
@export var dazed_time: float = 3.0
@export_multiline var defeat_message: String = "Het fatbike-kindje is verslagen! Het OBC is bevrijd."

const SAVE_BLOCK: StringName = &"boss"
const CORPSE_TIME: float = 4.0
const TURN_SPEED: float = 5.0

var mode: Mode = Mode.WAITING
## How many charges he has made since the fight started, for tests.
var charge_count: int = 0
var _timer: float = 0.0
var _charges_left: int = 0
var _direction: Vector3 = Vector3.FORWARD
var _start: Vector3
var _gate: StaticBody3D

@onready var model: Node3D = $Model
@onready var health: HealthComponent = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _hitbox: Hitbox = $ChargeHitbox
@onready var _loot_dropper: LootDropper = $LootDropper
@onready var _aim_line: MeshInstance3D = $AimLine
@onready var _rev_label: Label3D = $RevLabel
@onready var _dazed_label: Label3D = $DazedLabel


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
	_hurtbox.set_enabled(false)
	_loot_dropper.loot = data.loot
	_start = global_position
	_aim_line.visible = false
	_rev_label.visible = false
	_dazed_label.visible = false


func is_enraged() -> bool:
	return health.current_health * 2 <= health.max_health


func _physics_process(delta: float) -> void:
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	if player == null or mode == Mode.DEAD:
		return
	match mode:
		Mode.WAITING:
			if player.global_position.distance_to(_start) <= start_radius:
				_start_fight()
		Mode.AIMING:
			_face(player.global_position, delta)
			_timer -= delta
			# The engine shakes the whole bike while he revs.
			model.position.x = sin(_timer * 70.0) * 0.05
			if _timer <= 0.0:
				_charge()
		Mode.CHARGING:
			velocity = _direction * charge_speed
			move_and_slide()
			for i: int in get_slide_collision_count():
				if get_slide_collision(i).get_normal().dot(_direction) < -0.5:
					_crash()
					break
		Mode.DAZED:
			_timer -= delta
			if _timer <= 0.0:
				_recover()


func _start_fight() -> void:
	GameState.block_saving(SAVE_BLOCK)
	EventBus.boss_started.emit(data.display_name, health.max_health)
	_set_gate(true)
	_charges_left = 0
	_aim(aim_time)


func _aim(duration: float) -> void:
	mode = Mode.AIMING
	_timer = duration
	_aim_line.visible = true
	_rev_label.visible = true


func _charge() -> void:
	mode = Mode.CHARGING
	charge_count += 1
	_direction = -global_basis.z
	_direction.y = 0.0
	_direction = _direction.normalized()
	model.position.x = 0.0
	_aim_line.visible = false
	_rev_label.visible = false
	_hitbox.activate(data.damage)


func _crash() -> void:
	velocity = Vector3.ZERO
	_hitbox.deactivate()
	if _charges_left > 0:
		_charges_left -= 1
		_aim(aim_time_quick)
		return
	mode = Mode.DAZED
	_timer = dazed_time
	_hurtbox.set_enabled(true)
	_dazed_label.visible = true
	model.rotation.z = 0.3


func _recover() -> void:
	_hurtbox.set_enabled(false)
	_dazed_label.visible = false
	model.rotation.z = 0.0
	_charges_left = 1 if is_enraged() else 0
	_aim(aim_time)


func _face(target: Vector3, delta: float) -> void:
	var offset: Vector3 = target - global_position
	if Vector2(offset.x, offset.z).length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-offset.x, -offset.z), TURN_SPEED * delta)


func _set_gate(closed: bool) -> void:
	if _gate == null:
		return
	_gate.visible = closed
	for child: Node in _gate.get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).set_deferred(&"disabled", not closed)


func _on_hit_received(hit: HitData) -> void:
	if mode == Mode.DAZED:
		health.take_damage(hit.damage)


func _on_died() -> void:
	mode = Mode.DEAD
	_hurtbox.set_enabled(false)
	_hitbox.deactivate()
	_aim_line.visible = false
	_rev_label.visible = false
	_dazed_label.visible = false
	_loot_dropper.drop()
	GameState.set_flag(defeated_flag)
	EventBus.enemy_killed.emit(data.id)
	_end_fight()
	EventBus.message_requested.emit(defeat_message)
	SaveManager.request_autosave()
	var tumble: Tween = create_tween()
	tumble.tween_property(model, "rotation:z", 1.5, 0.6)
	await get_tree().create_timer(CORPSE_TIME, false).timeout
	var sink: Tween = create_tween()
	sink.tween_property(model, "position:y", -1.5, 1.5)
	sink.tween_callback(queue_free)


func _end_fight() -> void:
	GameState.unblock_saving(SAVE_BLOCK)
	EventBus.boss_ended.emit()
	_set_gate(false)


func _exit_tree() -> void:
	# Leaving mid-fight (the player died and a save loads) ends the fight too.
	if mode in [Mode.AIMING, Mode.CHARGING, Mode.DAZED]:
		_end_fight()
