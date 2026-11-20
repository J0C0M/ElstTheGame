class_name Enemy
extends CharacterBody3D
## Base for the human enemies. Stats, body and loot come from its EnemyData.
## The states under StateMachine decide what happens: idle, patrol, chase,
## attack, retreat, stagger and dead. This script holds the senses, walking
## on the navigation mesh, getting hit and dying.

## Seconds between two looks for the player.
const PERCEPTION_INTERVAL: float = 0.2
## Seconds between two path updates while following something.
const REPATH_INTERVAL: float = 0.25
const KNOCKBACK_SPEED: float = 2.5
## Seconds a body stays before it sinks into the ground.
const CORPSE_TIME: float = 4.0

@export var data: EnemyData

## Where the enemy belongs. It patrols around here and returns after a chase.
var home: Vector3 = Vector3.ZERO
var attack_cooldown_left: float = 0.0
## True while the enemy knows where the player is; widens its view to all sides.
var aware: bool = false
## Result of the last look for the player.
var player_detected: bool = false
## Seconds since the enemy last noticed the player.
var time_since_seen: float = INF
## True once this enemy has warned its pack in the current fight; it warns
## again only after it calmed down (Idle).
var pack_warned: bool = false
## Side (1 or -1) this enemy circles round to when it flanks.
var flank_side: float = 1.0
## Seconds until a leaping enemy may leap again.
var leap_cooldown_left: float = 0.0
## Seconds a patient enemy keeps fighting up close without being hit.
var patience_left: float = INF
var model: HumanoidModel

var _gravity: float = 0.0
var _perception_wait: float = 0.0
var _repath_wait: float = 0.0
var _safe_velocity: Vector3 = Vector3.ZERO
var _has_safe_velocity: bool = false
var _knockback: Vector3 = Vector3.ZERO

## Multiplies the damage of attacks while a buff lasts.
var damage_multiplier: float = 1.0
var _buff_left: float = 0.0
var _buff_label: Label3D

@onready var health: HealthComponent = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var attack_hitbox: Hitbox = $AttackHitbox
@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var state_machine: StateMachine = $StateMachine
@onready var _health_bar: HealthBar3D = $HealthBar
@onready var _loot_dropper: LootDropper = $LootDropper
@onready var _collision: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	home = global_position
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	model = data.model_scene.instantiate() as HumanoidModel
	model.name = "Model"
	add_child(model)
	health.reset(data.get_max_health())
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	hurtbox.hit_received.connect(_on_hit_received)
	attack_hitbox.parried.connect(_on_parried)
	_loot_dropper.loot = data.loot
	agent.max_speed = data.run_speed
	agent.velocity_computed.connect(_on_velocity_computed)
	_health_bar.set_ratio(1.0)
	_perception_wait = randf() * PERCEPTION_INTERVAL
	flank_side = 1.0 if randf() < 0.5 else -1.0


func _physics_process(delta: float) -> void:
	attack_cooldown_left = maxf(attack_cooldown_left - delta, 0.0)
	leap_cooldown_left = maxf(leap_cooldown_left - delta, 0.0)
	_update_buff(delta)
	_update_perception(delta)
	state_machine.physics_update(delta)
	if health.is_dead():
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta
	velocity += _knockback
	move_and_slide()
	velocity -= _knockback
	_knockback = _knockback.move_toward(Vector3.ZERO, 12.0 * delta)
	var speed: float = Vector2(velocity.x, velocity.z).length()
	model.set_locomotion(speed, speed > data.walk_speed + 0.5, is_on_floor())


func get_player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func get_forward() -> Vector3:
	return -global_basis.z


func distance_to_player() -> float:
	var player: Player = get_player()
	return global_position.distance_to(player.global_position) if player != null else INF


## Walks towards [param target] along the navigation mesh at [param speed].
## Without a navigation mesh it walks straight there.
func move_towards(target: Vector3, speed: float, delta: float) -> void:
	_repath_wait -= delta
	if _repath_wait <= 0.0 or agent.target_position.distance_to(target) > 2.0:
		_repath_wait = REPATH_INTERVAL
		agent.target_position = target
	var next: Vector3 = agent.get_next_path_position()
	var to_target: Vector3 = target - global_position
	to_target.y = 0.0
	# No mesh yet, or the agent thinks it is done while still far away.
	if agent.is_navigation_finished() and to_target.length() > agent.target_desired_distance + 0.5:
		next = target
	var direction: Vector3 = next - global_position
	direction.y = 0.0
	var desired: Vector3 = direction.normalized() * speed if direction.length() > 0.05 else Vector3.ZERO
	agent.velocity = desired
	if _has_safe_velocity and desired != Vector3.ZERO:
		desired = _safe_velocity
	velocity.x = desired.x
	velocity.z = desired.z
	turn_towards(desired, delta)


func stop_moving(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
	agent.velocity = Vector3.ZERO


func turn_towards(direction: Vector3, delta: float, turn_speed: float = 8.0) -> void:
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return
	var target_yaw: float = atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-turn_speed * delta))


func face_player(delta: float, turn_speed: float = 8.0) -> void:
	var player: Player = get_player()
	if player != null:
		turn_towards(player.global_position - global_position, delta, turn_speed)


## Makes the enemy notice the player, for example when hit or warned. With
## [param warn_others] off it does not pass the warning on.
func notice_player(warn_others: bool = true) -> void:
	if health.is_dead():
		return
	time_since_seen = 0.0
	if state_machine.get_state_name() in [&"Idle", &"Patrol", &"Retreat"]:
		if not warn_others:
			pack_warned = true
		state_machine.transition_to(&"Chase")


## Fires the projectile from EnemyData at the player's chest, turned by
## [param spread_degrees] to the side; a miss (see EnemyData.accuracy) goes
## further wide. Returns the projectile.
func fire_projectile(spread_degrees: float = 0.0) -> Node3D:
	var projectile: Node3D = data.projectile_scene.instantiate() as Node3D
	get_parent().add_child(projectile)
	var origin: Vector3 = global_position + Vector3.UP * 1.45 + get_forward() * 0.6
	var target: Vector3 = get_player().global_position + Vector3.UP * 1.1 if get_player() != null else origin + get_forward()
	if randf() > data.accuracy:
		spread_degrees += data.miss_angle * (1.0 if randf() < 0.5 else -1.0)
	var direction: Vector3 = (target - origin).rotated(Vector3.UP, deg_to_rad(spread_degrees))
	projectile.call(&"launch", origin, direction, get_damage(), self)
	return projectile


## Pushes the enemy away, such as the recoil of a shot.
func apply_knockback(push: Vector3) -> void:
	_knockback = push


## Damage of the next attack, with any buff.
func get_damage() -> int:
	return roundi(data.damage * damage_multiplier)


## Lets the enemy hit harder for [param seconds], such as after a bingo-opa's
## Grumpy Oma's BINGO!. A red word above its head shows it.
func buff_damage(factor: float, seconds: float, word: String) -> void:
	damage_multiplier = factor
	_buff_left = seconds
	if _buff_label == null:
		_buff_label = Label3D.new()
		_buff_label.position = Vector3(0, 2.6, 0)
		_buff_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_buff_label.pixel_size = 0.008
		_buff_label.font_size = 48
		_buff_label.outline_size = 10
		_buff_label.modulate = Color(1, 0.25, 0.2)
		add_child(_buff_label)
	_buff_label.text = word
	_buff_label.visible = true


func _update_buff(delta: float) -> void:
	if _buff_left <= 0.0:
		return
	_buff_left -= delta
	if _buff_left <= 0.0:
		damage_multiplier = 1.0
		_buff_label.visible = false


## Warns nearby enemies of the same faction that the player is here, once
## per fight. They pass it on only with EnemyData.alert_chain.
func alert_pack() -> void:
	pack_warned = true
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var other: Enemy = node as Enemy
		if other != null and other != self and other.data.faction == data.faction \
				and global_position.distance_to(other.global_position) <= data.alert_radius:
			other.notice_player(data.alert_chain)


## Falls over, drops loot and sinks away after a while.
func die() -> void:
	attack_hitbox.deactivate()
	hurtbox.set_enabled(false)
	_collision.set_deferred("disabled", true)
	agent.avoidance_enabled = false
	_health_bar.visible = false
	remove_from_group(&"enemies")
	model.play_action(&"death", 1.0, true)
	_loot_dropper.drop()
	EventBus.enemy_killed.emit(data.id)
	await get_tree().create_timer(CORPSE_TIME, false).timeout
	var tween: Tween = create_tween()
	tween.tween_property(model, "position:y", -1.5, 1.5)
	tween.tween_callback(queue_free)


func _update_perception(delta: float) -> void:
	time_since_seen += delta
	_perception_wait -= delta
	if _perception_wait > 0.0:
		return
	_perception_wait = PERCEPTION_INTERVAL
	player_detected = _can_detect_player()
	if player_detected:
		time_since_seen = 0.0


func _can_detect_player() -> bool:
	var player: Player = get_player()
	if player == null or player.health.is_dead() or health.is_dead():
		return false
	var to_player: Vector3 = player.global_position - global_position
	var distance: float = to_player.length()
	if distance <= data.hearing_range:
		return true
	if distance > data.sight_range:
		return false
	# Up close the corner of the eye counts too.
	var view_angle: float = data.sight_angle_degrees if distance > data.sight_range * 0.5 else maxf(data.sight_angle_degrees, 160.0)
	var flat: Vector3 = Vector3(to_player.x, 0.0, to_player.z)
	if not aware and get_forward().angle_to(flat) > deg_to_rad(view_angle * 0.5):
		return false
	# The head or the chest of the player: a bench or a fence hides only one.
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	for height: float in [1.2, 1.7]:
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			global_position + Vector3.UP * 1.6, player.global_position + Vector3.UP * height, PhysicsLayers.WORLD, [get_rid()])
		if space.intersect_ray(query).is_empty():
			return true
	return false


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	_safe_velocity = safe_velocity
	_has_safe_velocity = true


func _on_health_changed(_current: int, _maximum: int) -> void:
	_health_bar.set_ratio(health.get_ratio())


func _on_hit_received(hit: HitData) -> void:
	if health.is_dead():
		return
	health.take_damage(hit.damage)
	if health.is_dead():
		return
	if data.patience > 0.0:
		patience_left = data.patience
	var away: Vector3 = global_position - hit.source.global_position
	away.y = 0.0
	_knockback = away.normalized() * KNOCKBACK_SPEED
	if state_machine.get_state_name() != &"Attack":
		model.play_action(&"hurt", 0.3)
	notice_player()


func _on_parried() -> void:
	attack_hitbox.deactivate()
	state_machine.transition_to(&"Stagger")


func _on_died() -> void:
	state_machine.transition_to(&"Dead")
