class_name VapeKing
extends Node3D
## The Vape-koning, boss of Westeraam. He hides in one of the vape clouds of
## his arena and blows vape puffs at the player from it, three at a time below
## half health. Walk into his cloud and he is exposed for a few seconds, then
## he flees to another cloud, and thick vape fills the palace until he sits in
## it, so the player cannot see where he went. Saving is blocked during the fight. Once beaten
## a GameState flag keeps him beaten and Westeraam liberated.

enum Mode { WAITING, HIDDEN, EXPOSED, FLEEING, DEAD }

## Health, damage, loot and the puff he fires.
@export var data: EnemyData
## GameState flag set when he is beaten.
@export var defeated_flag: StringName = &"boss_vape_koning"
## Node whose VapeHideout children are the clouds he hides in.
@export var hideouts_path: NodePath
## The fight starts when the player comes this close to the middle of the clouds.
@export var start_radius: float = 13.0
## Seconds between puffs, and below half health.
@export var fire_interval: float = 2.0
@export var fire_interval_enraged: float = 1.5
## Spread in degrees of the three puffs below half health.
@export var enraged_spread: float = 18.0
## Within this distance of his cloud he is exposed.
@export var expose_radius: float = 3.2
@export var exposed_time: float = 4.0
@export var flee_speed: float = 11.0
@export_multiline var defeat_message: String = "De Vape-koning is verslagen! Westeraam is bevrijd."

@export_group("Vape fog")
## Fog that fills the palace while he flees.
@export var flee_fog_color: Color = Color(0.82, 0.78, 0.94)
@export var flee_fog_density: float = 0.22
## Seconds the fog takes to come up, and to clear once he is hidden again.
@export var fog_fade_in: float = 0.25
@export var fog_fade_out: float = 1.0

const SAVE_BLOCK: StringName = &"boss"
const CORPSE_TIME: float = 4.0

var mode: Mode = Mode.WAITING
var hideouts: Node3D
var _cloud_index: int = 0
var _timer: float = 0.0
var _arena_center: Vector3
var _environment: Environment
var _fog_tween: Tween

@onready var model: HumanoidModel = $Model
@onready var health: HealthComponent = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _loot_dropper: LootDropper = $LootDropper


func _ready() -> void:
	hideouts = get_node(hideouts_path) as Node3D
	if GameState.has_flag(defeated_flag):
		hideouts.queue_free()
		queue_free()
		return
	health.reset(data.get_max_health())
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	_hurtbox.hit_received.connect(_on_hit_received)
	_loot_dropper.loot = data.loot
	_arena_center = Vector3.ZERO
	for cloud: VapeHideout in get_hideouts():
		_arena_center += cloud.global_position / get_hideouts().size()
	_setup_fog()
	_hide_in(0)


func get_hideouts() -> Array[VapeHideout]:
	var clouds: Array[VapeHideout] = []
	for child: Node in hideouts.get_children():
		if child is VapeHideout:
			clouds.append(child as VapeHideout)
	return clouds


func is_enraged() -> bool:
	return health.current_health * 2 <= health.max_health


func _physics_process(delta: float) -> void:
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	if player == null or mode == Mode.DEAD:
		return
	match mode:
		Mode.WAITING:
			if player.global_position.distance_to(_arena_center) <= start_radius:
				_start_fight()
		Mode.HIDDEN:
			_face(player.global_position)
			_timer -= delta
			if _timer <= 0.0 and not player.health.is_dead():
				_shoot(player)
				_timer = fire_interval_enraged if is_enraged() else fire_interval
			var to_player: Vector3 = player.global_position - global_position
			if Vector2(to_player.x, to_player.z).length() <= expose_radius:
				_expose()
		Mode.EXPOSED:
			_face(player.global_position)
			_timer -= delta
			if _timer <= 0.0:
				_flee()
		Mode.FLEEING:
			var target: Vector3 = get_hideouts()[_cloud_index].global_position
			var offset: Vector3 = target - global_position
			offset.y = 0.0
			var step: float = flee_speed * delta
			if offset.length() <= step:
				global_position = Vector3(target.x, global_position.y, target.z)
				_hide_in(_cloud_index)
			else:
				global_position += offset.normalized() * step
				_face(target)
				model.set_locomotion(flee_speed, true, true)


func _start_fight() -> void:
	GameState.block_saving(SAVE_BLOCK)
	EventBus.boss_started.emit(data.display_name, health.max_health)
	mode = Mode.HIDDEN
	_timer = 1.0


func _shoot(player: Player) -> void:
	var origin: Vector3 = global_position + Vector3.UP * 1.7
	var direction: Vector3 = player.global_position + Vector3.UP * 1.1 - origin
	var spreads: Array[float] = [0.0]
	if is_enraged():
		spreads = [-enraged_spread, 0.0, enraged_spread]
	for spread: float in spreads:
		var puff: Node3D = data.projectile_scene.instantiate() as Node3D
		get_parent().add_child(puff)
		puff.call(&"launch", origin, direction.rotated(Vector3.UP, deg_to_rad(spread)), data.damage, self)


func _expose() -> void:
	mode = Mode.EXPOSED
	_timer = exposed_time
	model.visible = true
	model.play_action(&"cough", exposed_time)
	_hurtbox.set_enabled(true)
	get_hideouts()[_cloud_index].set_occupied(false)


func _flee() -> void:
	mode = Mode.FLEEING
	_hurtbox.set_enabled(false)
	model.stop_action()
	var count: int = get_hideouts().size()
	_cloud_index = (_cloud_index + randi_range(1, count - 1)) % count
	_set_fog(flee_fog_density, fog_fade_in)


func _hide_in(index: int) -> void:
	_cloud_index = index
	global_position = Vector3(get_hideouts()[index].global_position.x, global_position.y, get_hideouts()[index].global_position.z)
	model.visible = false
	model.set_locomotion(0.0, false, true)
	_hurtbox.set_enabled(false)
	get_hideouts()[index].set_occupied(true)
	if mode != Mode.WAITING:
		mode = Mode.HIDDEN
		_timer = 0.8
		_set_fog(0.0, fog_fade_out)


## Gives the world its own copy of the environment, with fog that is off for now.
func _setup_fog() -> void:
	var node: Node = get_parent()
	while node != null:
		var world_environment: WorldEnvironment = node.get_node_or_null(^"WorldEnvironment") as WorldEnvironment
		if world_environment != null:
			_environment = world_environment.environment.duplicate() as Environment
			_environment.fog_enabled = true
			_environment.fog_density = 0.0
			_environment.fog_light_color = flee_fog_color
			_environment.fog_light_energy = 1.2
			world_environment.environment = _environment
			return
		node = node.get_parent()


func _set_fog(density: float, duration: float) -> void:
	if _environment == null:
		return
	if _fog_tween != null:
		_fog_tween.kill()
	_fog_tween = create_tween()
	_fog_tween.tween_property(_environment, "fog_density", density, duration)


func _face(target: Vector3) -> void:
	var offset: Vector3 = target - global_position
	if Vector2(offset.x, offset.z).length() > 0.1:
		rotation.y = atan2(-offset.x, -offset.z)


func _on_hit_received(hit: HitData) -> void:
	if mode == Mode.EXPOSED:
		health.take_damage(hit.damage)


func _on_health_changed(current: int, maximum: int) -> void:
	EventBus.boss_health_changed.emit(current, maximum)


func _on_died() -> void:
	mode = Mode.DEAD
	_hurtbox.set_enabled(false)
	model.visible = true
	model.play_action(&"death", 1.0, true)
	_loot_dropper.drop()
	_set_fog(0.0, fog_fade_out)
	GameState.set_flag(defeated_flag)
	EventBus.enemy_killed.emit(data.id)
	_end_fight()
	EventBus.message_requested.emit(defeat_message)
	SaveManager.request_autosave()
	var fade: Tween = create_tween()
	fade.tween_property(hideouts, "scale", Vector3.ONE * 0.01, 1.5)
	fade.tween_callback(hideouts.queue_free)
	await get_tree().create_timer(CORPSE_TIME, false).timeout
	var sink: Tween = create_tween()
	sink.tween_property(model, "position:y", -1.5, 1.5)
	sink.tween_callback(queue_free)


func _end_fight() -> void:
	GameState.unblock_saving(SAVE_BLOCK)
	EventBus.boss_ended.emit()


func _exit_tree() -> void:
	# Leaving mid-fight (the player died and a save loads) ends the fight too.
	if mode in [Mode.HIDDEN, Mode.EXPOSED, Mode.FLEEING]:
		_end_fight()
