class_name Dragonling
extends CharacterBody3D
## A little dragon of Amber, in the church. It flies a few metres up,
## circles the player and spits fireballs. Now and then it dives to bite:
## only then can a sword reach it. A crossbow bolt reaches it anywhere.

enum Mode { HOVER, CIRCLE, DIVE, DEAD }

## Health, damage, senses and loot.
@export var data: EnemyData
@export var fireball_scene: PackedScene
@export var hover_height: float = 3.6
@export var circle_radius: float = 7.0
@export var fly_speed: float = 5.0
@export var shoot_interval: float = 2.6
@export var dive_interval: float = 7.0
@export var dive_time: float = 1.4

const FLAP_SPEED: float = 14.0
const CORPSE_TIME: float = 3.0

var mode: Mode = Mode.HOVER
var home: Vector3
var _shoot_wait: float = 0.0
var _dive_wait: float = 0.0
var _timer: float = 0.0
var _angle: float = 0.0
var _time: float = 0.0
var _gravity: float = 9.8

@onready var health: HealthComponent = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var _bite: Hitbox = $BiteHitbox
@onready var _loot_dropper: LootDropper = $LootDropper
@onready var _model: Node3D = $Model
@onready var _wing_l: Node3D = $Model/WingL
@onready var _wing_r: Node3D = $Model/WingR
@onready var _health_bar: HealthBar3D = $HealthBar


func _ready() -> void:
	home = global_position
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	health.reset(data.get_max_health())
	health.health_changed.connect(func(_current: int, _maximum: int) -> void: _health_bar.set_ratio(health.get_ratio()))
	health.died.connect(_on_died)
	hurtbox.hit_received.connect(_on_hit_received)
	_loot_dropper.loot = data.loot
	_health_bar.set_ratio(1.0)
	_shoot_wait = randf_range(1.0, shoot_interval)
	_dive_wait = dive_interval * randf_range(0.6, 1.0)
	_angle = randf() * TAU


## Makes the dragonling notice the player, for example when hit.
func notice_player(_warn_others: bool = true) -> void:
	if mode == Mode.HOVER:
		mode = Mode.CIRCLE


func _physics_process(delta: float) -> void:
	_time += delta
	var flap: float = sin(_time * FLAP_SPEED) * 0.7
	_wing_l.rotation.z = flap
	_wing_r.rotation.z = -flap
	if mode == Mode.DEAD:
		velocity.x = move_toward(velocity.x, 0.0, 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 4.0 * delta)
		velocity.y -= _gravity * delta
		move_and_slide()
		return
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	match mode:
		Mode.HOVER:
			_fly_to(home + Vector3.UP * (hover_height + sin(_time * 2.0) * 0.3), fly_speed * 0.5, delta)
			if player != null and _sees(player):
				mode = Mode.CIRCLE
		Mode.CIRCLE:
			if player == null or player.health.is_dead() or global_position.distance_to(home) > data.leash_range:
				mode = Mode.HOVER
				return
			_angle += delta * 0.6
			var around: Vector3 = Vector3(cos(_angle), 0.0, sin(_angle)) * circle_radius
			_fly_to(player.global_position + around + Vector3.UP * hover_height, fly_speed, delta)
			_face(player.global_position)
			_shoot_wait -= delta
			if _shoot_wait <= 0.0:
				_shoot_wait = shoot_interval
				_shoot(player)
			_dive_wait -= delta
			if _dive_wait <= 0.0:
				mode = Mode.DIVE
				_timer = dive_time
				_bite.activate(data.damage)
		Mode.DIVE:
			_timer -= delta
			if player != null:
				_fly_to(player.global_position + Vector3.UP * 1.3, fly_speed * 1.8, delta)
				_face(player.global_position)
			if _timer <= 0.0:
				_bite.deactivate()
				_dive_wait = dive_interval
				mode = Mode.CIRCLE


func _fly_to(target: Vector3, speed: float, delta: float) -> void:
	var wanted: Vector3 = (target - global_position).limit_length(speed)
	velocity = velocity.lerp(wanted, 1.0 - exp(-4.0 * delta))
	move_and_slide()


func _face(target: Vector3) -> void:
	var to: Vector3 = target - global_position
	to.y = 0.0
	if to.length() > 0.1:
		rotation.y = atan2(-to.x, -to.z)


func _sees(player: Player) -> bool:
	if global_position.distance_to(player.global_position) > data.sight_range:
		return false
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		global_position, player.global_position + Vector3.UP * 1.2, PhysicsLayers.WORLD, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _shoot(player: Player) -> void:
	if fireball_scene == null:
		return
	var fireball: Node3D = fireball_scene.instantiate() as Node3D
	# Into the world itself, not among the enemies.
	(owner if owner != null else get_parent()).add_child(fireball)
	var origin: Vector3 = global_position - global_basis.z * 0.7
	fireball.call(&"launch", origin, player.global_position + Vector3.UP * 1.1 - origin, data.damage, self)


func _on_hit_received(hit: HitData) -> void:
	if health.is_dead():
		return
	health.take_damage(hit.damage)
	notice_player()


func _on_died() -> void:
	mode = Mode.DEAD
	_bite.deactivate()
	hurtbox.set_enabled(false)
	_health_bar.visible = false
	remove_from_group(&"enemies")
	_loot_dropper.drop()
	EventBus.enemy_killed.emit(data.id)
	await get_tree().create_timer(CORPSE_TIME, false).timeout
	var tween: Tween = create_tween()
	tween.tween_property(_model, "scale", Vector3.ONE * 0.01, 0.6)
	tween.tween_callback(queue_free)
