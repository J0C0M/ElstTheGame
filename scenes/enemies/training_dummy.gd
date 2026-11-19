class_name TrainingDummy
extends StaticBody3D
## Straw training dummy for the test arena. It wobbles when hit, falls apart
## at 0 HP and stands up again after a few seconds. With attack_enabled it
## turns towards the player and swings a club, which the player can block,
## parry or dodge. A parry knocks it off balance for a moment.

enum Mode { IDLE, WINDUP, STRIKE, RECOVER, STAGGERED, BROKEN }

const STRIKE_TIME: float = 0.18
const RECOVER_TIME: float = 0.45
const TURN_SPEED: float = 4.0
const WOBBLE_STIFFNESS: float = 90.0
const WOBBLE_DAMPING: float = 7.0
const MAX_WOBBLE: float = 0.6
## Club rotation in degrees while raised and at the end of a strike.
const CLUB_RAISED: float = 150.0
const CLUB_STRUCK: float = 75.0
const TELEGRAPH_COLOR: Color = Color(1.0, 0.2, 0.15)
const PIECE_GRAVITY: float = 12.0

@export var data: EnemyData
@export var attack_enabled: bool = false
## Seconds until a broken dummy stands up again.
@export var respawn_delay: float = 4.0
## Colour of the band around the sack, to tell dummies apart.
@export var band_color: Color = Color(0.85, 0.7, 0.3)

var _mode: Mode = Mode.IDLE
var _mode_time: float = 0.0
var _cooldown: float = 0.0
var _flash: float = 0.0
## Tilt around the local X and Z axes, in radians, and its speed.
var _wobble: Vector2 = Vector2.ZERO
var _wobble_velocity: Vector2 = Vector2.ZERO
var _pieces: Array[MeshInstance3D] = []
var _piece_rest: Array[Transform3D] = []
var _piece_velocity: Array[Vector3] = []
var _piece_spin: Array[Vector3] = []
var _sack_material: StandardMaterial3D
var _sack_color: Color

@onready var _model: Node3D = $Model
@onready var _club_arm: Node3D = $Model/ClubArm
@onready var _health: HealthComponent = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _attack_hitbox: Hitbox = $AttackHitbox
@onready var _health_bar: HealthBar3D = $HealthBar
@onready var _collision: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	_health.reset(data.max_health)
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)
	_hurtbox.hit_received.connect(_on_hit_received)
	_attack_hitbox.parried.connect(_on_parried)
	_club_arm.visible = attack_enabled
	_sack_material = _own_material($Model/Sack)
	_sack_color = _sack_material.albedo_color
	_own_material($Model/Band).albedo_color = band_color
	for node: Node in _model.find_children("*", "MeshInstance3D"):
		var piece: MeshInstance3D = node as MeshInstance3D
		_pieces.append(piece)
		_piece_rest.append(piece.transform)
	_health_bar.set_ratio(1.0)
	_cooldown = data.attack_cooldown


func _physics_process(delta: float) -> void:
	_mode_time += delta
	match _mode:
		Mode.BROKEN:
			_update_pieces(delta)
			return
		Mode.IDLE:
			_update_idle(delta)
		Mode.WINDUP:
			_face_player(delta * 0.5)
			if _mode_time >= data.attack_windup:
				_set_mode(Mode.STRIKE)
				_attack_hitbox.activate(data.damage)
		Mode.STRIKE:
			if _mode_time >= STRIKE_TIME:
				_attack_hitbox.deactivate()
				_set_mode(Mode.RECOVER)
		Mode.RECOVER:
			if _mode_time >= RECOVER_TIME:
				_cooldown = data.attack_cooldown
				_set_mode(Mode.IDLE)
		Mode.STAGGERED:
			if _mode_time >= data.parry_stagger_duration:
				_cooldown = data.attack_cooldown * 0.5
				_set_mode(Mode.IDLE)
	_update_wobble(delta)
	_update_club(delta)
	_update_color(delta)


func _update_idle(delta: float) -> void:
	if not attack_enabled:
		return
	var player: Player = _find_player()
	if player == null or player.health.is_dead():
		return
	_face_player(delta)
	_cooldown -= delta
	if _cooldown <= 0.0 and global_position.distance_to(player.global_position) <= data.attack_range:
		_set_mode(Mode.WINDUP)


func _face_player(delta: float) -> void:
	var player: Player = _find_player()
	if player == null:
		return
	var to_player: Vector3 = player.global_position - global_position
	if to_player.length_squared() < 0.01:
		return
	var target_yaw: float = atan2(-to_player.x, -to_player.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-TURN_SPEED * delta))


func _find_player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _set_mode(mode: Mode) -> void:
	_mode = mode
	_mode_time = 0.0


func _update_wobble(delta: float) -> void:
	var acceleration: Vector2 = -_wobble * WOBBLE_STIFFNESS - _wobble_velocity * WOBBLE_DAMPING
	_wobble_velocity += acceleration * delta
	_wobble = (_wobble + _wobble_velocity * delta).limit_length(MAX_WOBBLE)
	if _mode == Mode.STAGGERED:
		# Off balance: keep rocking a little.
		_wobble.y += sin(_mode_time * 14.0) * 0.01
	_model.rotation = Vector3(_wobble.x, 0.0, _wobble.y)


func _update_club(delta: float) -> void:
	if not attack_enabled:
		return
	var target: float = 0.0
	var speed: float = 8.0
	match _mode:
		Mode.WINDUP:
			target = CLUB_RAISED
			speed = 6.0
		Mode.STRIKE:
			target = CLUB_STRUCK
			speed = 30.0
		Mode.STAGGERED:
			target = 20.0
	var current: float = rad_to_deg(_club_arm.rotation.x)
	_club_arm.rotation.x = deg_to_rad(lerpf(current, target, 1.0 - exp(-speed * delta)))


func _update_color(delta: float) -> void:
	_flash = maxf(_flash - delta * 6.0, 0.0)
	var color: Color = _sack_color
	if _mode == Mode.WINDUP:
		# Telegraph: the sack glows red while the club goes up.
		color = color.lerp(TELEGRAPH_COLOR, clampf(_mode_time / data.attack_windup, 0.0, 1.0) * 0.7)
	_sack_material.albedo_color = color.lerp(Color.WHITE, _flash)


func _update_pieces(delta: float) -> void:
	var floor_height: float = global_position.y + 0.05
	for i: int in _pieces.size():
		var piece: MeshInstance3D = _pieces[i]
		_piece_velocity[i].y -= PIECE_GRAVITY * delta
		var piece_transform: Transform3D = piece.global_transform
		piece_transform.origin += _piece_velocity[i] * delta
		if piece_transform.origin.y < floor_height:
			piece_transform.origin.y = floor_height
			_piece_velocity[i] = Vector3(_piece_velocity[i].x * 0.6, absf(_piece_velocity[i].y) * 0.3, _piece_velocity[i].z * 0.6)
			_piece_spin[i] *= 0.6
		var spin: Vector3 = _piece_spin[i] * delta
		piece_transform.basis = Basis.from_euler(spin) * piece_transform.basis
		piece.global_transform = piece_transform


func _on_health_changed(_current: int, _maximum: int) -> void:
	_health_bar.set_ratio(_health.get_ratio())


func _on_hit_received(hit: HitData) -> void:
	if _mode == Mode.BROKEN:
		return
	_health.take_damage(hit.damage)
	_flash = 1.0
	# Tilt away from the attacker; harder hits tilt further.
	var push: Vector3 = global_position - hit.source.global_position
	push.y = 0.0
	var local_push: Vector3 = global_basis.inverse() * push.normalized()
	_wobble_velocity += Vector2(local_push.z, -local_push.x) * (3.0 + hit.damage * 0.15)


func _on_parried() -> void:
	_attack_hitbox.deactivate()
	_set_mode(Mode.STAGGERED)
	_wobble_velocity += Vector2(6.0, 0.0)


func _on_died() -> void:
	_set_mode(Mode.BROKEN)
	_attack_hitbox.deactivate()
	_collision.set_deferred("disabled", true)
	_hurtbox.set_enabled(false)
	_model.rotation = Vector3.ZERO
	_piece_velocity.clear()
	_piece_spin.clear()
	var center: Vector3 = global_position + Vector3.UP
	for piece: MeshInstance3D in _pieces:
		var outward: Vector3 = piece.global_position - center
		outward.y = 0.0
		if outward.length_squared() < 0.01:
			outward = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
		_piece_velocity.append(outward.normalized() * randf_range(2.0, 4.0) + Vector3.UP * randf_range(3.0, 5.0))
		_piece_spin.append(Vector3(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0), randf_range(-8.0, 8.0)))
	get_tree().create_timer(respawn_delay).timeout.connect(_rebuild)


func _rebuild() -> void:
	for i: int in _pieces.size():
		_pieces[i].transform = _piece_rest[i]
	_wobble = Vector2.ZERO
	_wobble_velocity = Vector2.ZERO
	_model.rotation = Vector3.ZERO
	_club_arm.rotation = Vector3.ZERO
	reset_physics_interpolation()
	_collision.set_deferred("disabled", false)
	_hurtbox.set_enabled(true)
	_health.reset(data.max_health)
	_cooldown = data.attack_cooldown
	_set_mode(Mode.IDLE)


func _own_material(mesh_instance: MeshInstance3D) -> StandardMaterial3D:
	var material: StandardMaterial3D = mesh_instance.get_active_material(0).duplicate()
	mesh_instance.material_override = material
	return material
