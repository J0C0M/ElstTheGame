class_name Dragonling
extends CharacterBody3D
## A little dragon of Amber with a driller on its back, in the church.
## It flies a few metres up (lower under a low ceiling), circles the player
## and spits fireballs. Now and then it dives to bite while its rider swings
## his plank: only then can a sword reach it. A crossbow bolt reaches it
## anywhere. When the dragon falls, its rider tumbles off and fights on on
## foot.

enum Mode { HOVER, CIRCLE, DIVE, DEAD }

## Health, damage, senses and loot.
@export var data: EnemyData
@export var fireball_scene: PackedScene
## The enemy the rider becomes on foot when the dragon falls.
@export var rider_scene: PackedScene
@export var hover_height: float = 3.6
@export var circle_radius: float = 7.0
@export var fly_speed: float = 5.0
@export var shoot_interval: float = 2.6
@export var dive_interval: float = 7.0
@export var dive_time: float = 1.4

## Wing beats per second.
const FLAP_RATE: float = 2.4
const CORPSE_TIME: float = 3.0
## Room the dragon and its rider need under the ceiling.
const HEADROOM: float = 2.2
const MIN_HOVER: float = 2.2

var mode: Mode = Mode.HOVER
var home: Vector3
## The driller that fell off, for tests.
var fallen_rider: Node3D
var _shoot_wait: float = 0.0
var _dive_wait: float = 0.0
var _timer: float = 0.0
var _angle: float = 0.0
var _time: float = 0.0
var _flap: float = 0.0
var _jaw_open: float = 0.0
var _gravity: float = 9.8
var _wings: Array[DragonWingRig] = []

@onready var health: HealthComponent = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var _bite: Hitbox = $BiteHitbox
@onready var _loot_dropper: LootDropper = $LootDropper
@onready var _model: Node3D = $Model
@onready var _body: Node3D = $Model/Body
@onready var _neck: Node3D = $Model/Body/Neck
@onready var _jaw: Node3D = $Model/Body/Neck/Head/Jaw
@onready var _tails: Array[Node3D] = [$Model/Body/Tail, $Model/Body/Tail/Tail2, $Model/Body/Tail/Tail2/Tail3]
@onready var _rider: HumanoidModel = $Model/Body/Rider
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
	_flap = randf()
	_wings = [DragonWingRig.new($Model/Body/WingL, -1.0), DragonWingRig.new($Model/Body/WingR, 1.0)]
	_fit_under_ceiling.call_deferred()


## Makes the dragonling notice the player, for example when hit.
func notice_player(_warn_others: bool = true) -> void:
	if mode == Mode.HOVER:
		mode = Mode.CIRCLE


func _physics_process(delta: float) -> void:
	_time += delta
	_animate(delta)
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
			_fly_to(Vector3(player.global_position.x, home.y, player.global_position.z) + around + Vector3.UP * hover_height, fly_speed, delta)
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
				_rider.play_action(&"swing_light_1", 0.6)
		Mode.DIVE:
			_timer -= delta
			if player != null:
				_fly_to(player.global_position + Vector3.UP * 1.3, fly_speed * 1.8, delta)
				_face(player.global_position)
			if _timer <= 0.0:
				_bite.deactivate()
				_dive_wait = dive_interval
				mode = Mode.CIRCLE


## Wings beat (folded back in a dive, limp when dead), the body bobs with
## each beat, the tail sways and the jaw opens to spit.
func _animate(delta: float) -> void:
	var weight: float = 1.0 - exp(-14.0 * delta)
	var fold: float = 0.0
	var lift: float = 0.0
	var flex: float = 0.0
	match mode:
		Mode.DIVE:
			fold = 0.55
			lift = 0.35
		Mode.DEAD:
			fold = 0.5
			lift = -0.5
		_:
			_flap = fmod(_flap + delta * FLAP_RATE, 1.0)
			var down: bool = _flap < 0.4
			var t: float = _flap / 0.4 if down else (_flap - 0.4) / 0.6
			lift = lerpf(1.0, -0.7, t * t * (3.0 - 2.0 * t)) if down else lerpf(-0.7, 1.0, t * t * (3.0 - 2.0 * t))
			flex = 0.0 if down else sin(t * PI) * 0.9
	for wing: DragonWingRig in _wings:
		wing.apply(fold, lift, flex, weight)
	var bob: float = sin(_flap * TAU + 0.9) * 0.12 if mode in [Mode.HOVER, Mode.CIRCLE] else 0.0
	_body.position.y = lerpf(_body.position.y, bob, weight)
	_body.rotation.x = lerp_angle(_body.rotation.x, -0.35 if mode == Mode.DIVE else 0.05, weight)
	_neck.rotation.x = lerp_angle(_neck.rotation.x, 0.15 if mode == Mode.DIVE else 0.55 + sin(_time * 1.7) * 0.06, weight)
	_jaw_open = maxf(_jaw_open - delta * 2.5, 0.0)
	_jaw.rotation.x = lerp_angle(_jaw.rotation.x, -0.6 * minf(_jaw_open, 1.0) - (0.4 if mode == Mode.DIVE else 0.0), weight)
	for i: int in _tails.size():
		_tails[i].rotation.y = lerp_angle(_tails[i].rotation.y, sin(_time * 2.5 - float(i) * 0.7) * 0.25, weight)
		_tails[i].rotation.x = lerp_angle(_tails[i].rotation.x, -0.1 if mode == Mode.DEAD else 0.05, weight)


## Flies lower when the ceiling is low, so the rider keeps his head.
func _fit_under_ceiling() -> void:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		home + Vector3.UP * 0.5, home + Vector3.UP * (hover_height + HEADROOM + 1.0), PhysicsLayers.WORLD, [get_rid()])
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var room: float = (hit["position"] as Vector3).y - home.y
		hover_height = clampf(room - HEADROOM, MIN_HOVER, hover_height)


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
	var origin: Vector3 = ($Model/Body/Neck/Head/Mouth as Node3D).global_position
	fireball.call(&"launch", origin, player.global_position + Vector3.UP * 1.1 - origin, data.damage, self)
	_jaw_open = 1.0
	AudioManager.play_sfx_at(&"vape_puff", global_position, self, -4.0, 0.2)


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
	_drop_rider.call_deferred()
	await get_tree().create_timer(CORPSE_TIME, false).timeout
	var tween: Tween = create_tween()
	tween.tween_property(_model, "scale", Vector3.ONE * 0.01, 0.6)
	tween.tween_callback(queue_free)


## The rider tumbles off onto the floor below and fights on.
func _drop_rider() -> void:
	_rider.visible = false
	if rider_scene == null:
		return
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		global_position, global_position + Vector3.DOWN * 20.0, PhysicsLayers.WORLD, [get_rid()])
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	var spot: Vector3 = hit["position"] as Vector3 if not hit.is_empty() else global_position
	var parent: Node3D = get_parent() as Node3D
	var driller: Node3D = rider_scene.instantiate() as Node3D
	# Placed before it enters the tree, so the spot becomes its home.
	driller.position = parent.to_local(spot)
	driller.rotation.y = rotation.y
	parent.add_child(driller)
	driller.call(&"notice_player")
	fallen_rider = driller
