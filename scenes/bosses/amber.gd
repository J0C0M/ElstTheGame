class_name Amber
extends CharacterBody3D
## Amber de Draak, the last boss, in the round arena under the church. She
## has two health bars. With the first, Klaas fights along and she aims part
## of her attacks at him.
##
## She does not just run at you: she keeps a good distance for her breath
## and circles around her target, and she walks around a pillar to find a
## line of fire. Hide too long and she takes to the air. Each attack has its
## own cooldown, so she mixes them, and every attack is announced:
## - fire breath: a red fan on the floor shows where the fire will go, with
##   a shadow behind each pillar; she aims, locks, and pours fire in that
##   fan (in her second bar she sweeps it). Afterwards she pants with her
##   head low, and her head takes double damage;
## - a tail swipe at whoever stands beside or behind her;
## - wing gusts that blow the player away (a pillar shields you too);
## - she flies up more often and spits fireballs: three crossbow bolts
##   bring her down, and dazed on the floor her head takes double damage;
## - hit her a few times in a row and she roars and runs a lap along the
##   arena wall, trampling whoever is in her way, then comes back in.
## Her whole body (head, neck, tail, and spread wings) keeps clear of the
## pillars and the wall; the Probe markers of her model tell where it is.
##
## When the first bar is empty a scene follows in which Klaas saves the
## player and falls. With the second bar she is furious: faster, burning
## patches where she walks and after her breath, twice she calls
## cultists from Zevenaar, and she has a new attack: she rears up and stamps, and two
## rings of fire run over the floor (jump over them). When she dies she drops the golden Tren syringe. Saving is
## blocked during the fight and the gate is shut; a GameState flag keeps her
## beaten.

enum Mode { WAITING, CHASE, INHALE, BREATH, PANT, TAIL_WINDUP, TAIL, WINGS, TAKEOFF, FLYING, CRASH, DAZED, LAND, TRANSITION, DEAD, ROAR, LAP, STOMP }

## Health per bar, tail and trample damage.
@export var data: EnemyData
@export var defeated_flag: StringName = &"boss_amber"
## FlagGate of the arena: shut while the fight lasts.
@export var gate_path: NodePath
@export var klaas_path: NodePath
## Middle of the arena; she walks within arena_radius of it.
@export var arena_centre: Vector3
@export var arena_radius: float = 16.0
## Inside of the arena wall: no part of her goes past it.
@export var wall_radius: float = 26.2
## Centres of the pillars, and how far a pillar reaches from its centre.
@export var pillars: Array[Vector3] = []
@export var pillar_radius: float = 1.85
@export var start_radius: float = 16.0
@export var walk_speed: float = 4.2
@export var turn_speed: float = 1.6
@export_group("Stalking")
## She likes to stand this far from her target, for her breath.
@export var preferred_min: float = 9.0
@export var preferred_max: float = 15.0
@export var strafe_speed: float = 2.8
## Seconds between two attacks.
@export var attack_pause: float = 1.6
## Seconds a target may hide behind a pillar before she flies up.
@export var hide_limit: float = 4.0
@export_group("Breath")
@export var breath_range: float = 16.0
@export var breath_angle: float = 20.0
## In her second bar she sweeps the breath this far to either side.
@export var breath_sweep: float = 20.0
## Damage every quarter second in the flames.
@export var breath_damage: int = 8
@export var inhale_time: float = 1.25
@export var breath_time: float = 2.0
@export var pant_time: float = 2.2
@export var breath_cooldown: float = 8.0
@export_group("Tail and wings")
@export var tail_windup: float = 0.6
@export var tail_range: float = 10.5
@export var tail_cooldown: float = 3.5
@export var wing_windup: float = 0.6
@export var wing_time: float = 2.5
@export var wing_push: float = 10.0
@export var wing_range: float = 16.0
@export var wing_cooldown: float = 9.0
@export_group("Flight")
@export var flight_interval: float = 13.0
@export var flight_height: float = 8.0
@export var flight_time: float = 10.0
## She hovers over the middle of the arena, this far off it.
@export var hover_radius: float = 1.2
## Crossbow damage in the air that brings her down.
@export var shoot_down_damage: int = 90
@export var meteor_scene: PackedScene
@export var meteor_interval: float = 0.8
@export var meteor_damage: int = 18
@export var dazed_time: float = 4.0
@export_group("Lap")
## Hits by the player within lap_window seconds that make her run a lap.
@export var lap_hits: int = 4
@export var lap_window: float = 6.0
@export var lap_cooldown: float = 16.0
## Distance from the middle of the arena of her lap, between the pillars
## and the wall.
@export var lap_radius: float = 20.5
@export var lap_speed: float = 13.5
@export var roar_time: float = 1.1
@export_group("Second bar")
@export var enraged_speed_factor: float = 1.3
@export var fire_patch_scene: PackedScene
@export var fire_patch_damage: int = 6
@export var helper_scene: PackedScene
## Where the cultists come in, from the arena centre; two per call.
@export var helper_offsets: Array[Vector3] = []
## Health ratios of the second bar at which she calls cultists.
@export var help_at: Array[float] = [0.66, 0.33]
## Her stamp in the second bar: rings of fire that run over the floor.
@export var fire_wave_scene: PackedScene
@export var fire_wave_damage: int = 16
@export var stamp_cooldown: float = 9.0
@export var stamp_rear_time: float = 1.0
@export var tren_spuit_scene: PackedScene

const SAVE_BLOCK: StringName = &"boss"
const HEAD_FACTOR: float = 2.0
const BREATH_TICK: float = 0.25
const KLAAS_SHARE: float = 0.35
const TRAIL_EVERY: float = 1.2
const SAME_SWING: float = 0.3
const CHEST: float = 1.2
const TAKEOFF_CROUCH: float = 0.5
const TAKEOFF_TIME: float = 1.8
const LAND_TIME: float = 1.4
## Degrees she runs around the ring: four gaps on.
const LAP_SPAN: float = 288.0
const TRAMPLE_REACH: float = 3.2
const WING_REACH: float = 9.0
## Half the width of the hot zone under her neck while she breathes fire.
const NECK_HEAT: float = 3.2
## The heat under her neck pushes the player out, in metres per second.
const NECK_PUSH: float = 7.0
const ROARS: Array[String] = ["GRAAAAH!", "Uit mijn buurt, insecten!", "Jullie krijgen me niet te pakken!"]

var mode: Mode = Mode.WAITING
## 1 or 2: which health bar she is on.
var phase: int = 1
## The player or Klaas: whom her next attack is for.
var target: Node3D
## How many times she called cultists, laps she ran and breaths she took, for tests.
var helps: int = 0
var laps: int = 0
var stamps: int = 0
var _waves_left: int = 0
var breaths: int = 0
var _timer: float = 0.0
var _attack_wait: float = 0.0
var _flight_wait: float = 0.0
var _flight_damage: int = 0
var _meteor_wait: float = 0.0
var _tick: float = 0.0
var _trail_wait: float = 0.0
var _tail_hit: bool = false
var _ground_y: float = 0.0
var _flight_angle: float = 0.0
var _flight_from: Vector3
var _land_from: Vector3
var _clock: float = 0.0
var _recent_hits: Dictionary = {}
var _cooldowns: Dictionary = {&"breath": 0.0, &"tail": 0.0, &"wings": 0.0, &"lap": 0.0, &"stamp": 0.0}
var _hit_times: Array[float] = []
var _strafe_side: float = 1.0
var _strafe_wait: float = 0.0
var _hidden_time: float = 0.0
var _breath_yaw: float = 0.0
var _sweep_side: float = 1.0
var _lap_stage: int = 0
var _lap_gap: float = 0.0
var _lap_side: float = 1.0
var _lap_angle: float = 0.0
var _lap_travelled: float = 0.0
var _lap_time: float = 0.0
var _trampled: Array[Node3D] = []
var _gate: FlagGate
var _klaas: KlaasAlly
## Her own body, left out of her rays.
var _excluded: Array[RID] = []

@onready var model: AmberModel = $Model
@onready var health: HealthComponent = $Health
@onready var breath: AmberBreath = $Breath
@onready var _body_hurtbox: Hurtbox = $BodyHurtbox
@onready var _head_hurtbox: Hurtbox = $Model/Body/Neck/Head/HeadHurtbox
@onready var _hit_ref: Hitbox = $AttackHitbox
@onready var _charge_ball: Node3D = $Model/Body/Neck/Head/ChargeBall
@onready var _rage_light: OmniLight3D = $RageLight


func _ready() -> void:
	_gate = get_node_or_null(gate_path) as FlagGate
	_klaas = get_node_or_null(klaas_path) as KlaasAlly
	_ground_y = global_position.y
	if GameState.has_flag(defeated_flag):
		# Beaten before: only the syringe is left, if it was not picked up.
		if tren_spuit_scene != null and not GameState.has_flag(&"tren_spuit_found") and not GameState.has_flag(&"klaas_revived"):
			var spuit: Node3D = tren_spuit_scene.instantiate() as Node3D
			spuit.position = position + _forward() * 7.0
			get_parent().add_child.call_deferred(spuit)
		queue_free()
		return
	health.reset(data.get_max_health())
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_bar_empty)
	_body_hurtbox.hit_received.connect(_on_hit_received.bind(false))
	_head_hurtbox.hit_received.connect(_on_hit_received.bind(true))
	_charge_ball.visible = false
	_rage_light.visible = false
	_excluded = [get_rid()]


func is_flying() -> bool:
	return mode in [Mode.TAKEOFF, Mode.FLYING]


## Klaas hits her. Only on the ground and when she can be hurt.
func take_ally_hit(amount: int) -> void:
	if _can_be_hurt() and not is_flying():
		health.take_damage(amount)


## How far any part of her body reaches into a pillar or past the wall, in
## metres (0 when she stands clear), for tests.
func body_overlap() -> float:
	var worst: float = 0.0
	for probe: Array in model.get_probes(_wings_spread()):
		var point: Vector3 = (probe[0] as Node3D).global_position
		var radius: float = float(probe[1])
		for pillar: Vector3 in pillars:
			worst = maxf(worst, pillar_radius + radius - _flat(point - pillar).length())
		worst = maxf(worst, _flat(point - arena_centre).length() + radius - wall_radius)
	return worst


func _physics_process(delta: float) -> void:
	_clock += delta
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	if player == null or mode in [Mode.DEAD, Mode.TRANSITION]:
		breath.hide_warning()
		return
	var speed_factor: float = enraged_speed_factor if phase == 2 else 1.0
	for key: StringName in _cooldowns:
		_cooldowns[key] = maxf(float(_cooldowns[key]) - delta, 0.0)
	model.look_pitch = 0.0
	if mode not in [Mode.INHALE, Mode.BREATH]:
		breath.hide_warning()
	match mode:
		Mode.WAITING:
			model.pose = AmberModel.Pose.IDLE
			if _flat(player.global_position - global_position).length() <= start_radius:
				_start_fight(player)
		Mode.CHASE:
			_stalk(player, delta, speed_factor)
		Mode.INHALE:
			_inhale(player, delta, speed_factor)
		Mode.BREATH:
			_breathe(player, delta)
		Mode.PANT, Mode.DAZED:
			_timer -= delta
			if _timer <= 0.0:
				_back_to_chase()
		Mode.TAIL_WINDUP:
			_timer -= delta * speed_factor
			model.tail_sweep = lerpf(model.tail_sweep, -0.8, 1.0 - exp(-8.0 * delta))
			if _timer <= 0.0:
				mode = Mode.TAIL
				_timer = 0.6
				_tail_hit = false
		Mode.TAIL:
			_timer -= delta * speed_factor
			model.tail_sweep = lerpf(-0.8, 2.6, 1.0 - _timer / 0.6)
			if not _tail_hit and _timer <= 0.3:
				_tail_hit = true
				_tail_strike(player)
			if _timer <= 0.0:
				model.tail_sweep = 0.0
				_back_to_chase()
		Mode.WINGS:
			_timer -= delta
			# First she rears up and spreads her wings, then the gust comes.
			if _timer <= wing_time - wing_windup:
				_wing_gust(player)
			if _timer <= 0.0:
				_back_to_chase()
		Mode.TAKEOFF:
			_take_off_step(delta)
		Mode.FLYING:
			_fly(player, delta)
		Mode.CRASH:
			_timer -= delta
			global_position.y = move_toward(global_position.y, _ground_y, 20.0 * delta)
			if _timer <= 0.0:
				global_position.y = _ground_y
				mode = Mode.DAZED
				_timer = dazed_time
				model.pose = AmberModel.Pose.DAZED
		Mode.LAND:
			_timer -= delta
			var t: float = 1.0 - clampf(_timer / LAND_TIME, 0.0, 1.0)
			global_position = _land_from.lerp(Vector3(_land_from.x, _ground_y, _land_from.z), t * t)
			_turn_to(player.global_position, delta, 2.0)
			if _timer <= 0.0:
				global_position.y = _ground_y
				_back_to_chase()
		Mode.ROAR:
			_timer -= delta * speed_factor
			_turn_to(player.global_position, delta, 2.0)
			if _timer <= 0.0:
				_start_lap(player)
		Mode.LAP:
			_run_lap(player, delta, speed_factor)
		Mode.STOMP:
			_stamp(player, delta)
	if mode not in [Mode.TAKEOFF, Mode.FLYING, Mode.CRASH, Mode.LAND]:
		_keep_clear()


# --- On the ground: stalking her target and choosing an attack.

func _stalk(player: Player, delta: float, speed_factor: float) -> void:
	model.pose = AmberModel.Pose.IDLE
	if target == null or not is_instance_valid(target):
		target = player
	var aim: Vector3 = _target_position(player)
	var to_target: Vector3 = _flat(aim - global_position)
	var distance: float = to_target.length()
	var towards: Vector3 = to_target.normalized() if distance > 0.1 else _forward()
	_turn_to(aim, delta, speed_factor)
	_attack_wait -= delta
	_flight_wait -= delta
	_strafe_wait -= delta
	if _strafe_wait <= 0.0:
		_strafe_side = -_strafe_side
		_strafe_wait = randf_range(3.5, 6.0)
	var sideways: Vector3 = towards.cross(Vector3.UP) * _strafe_side
	var in_sight: bool = _clear_line(model.get_mouth(), aim + Vector3.UP * CHEST, target)
	var wanted: Vector3
	if not in_sight:
		# Hidden behind a pillar: walk around it to find a line of fire.
		_hidden_time += delta
		wanted = sideways * walk_speed + towards * walk_speed * 0.3
	else:
		_hidden_time = 0.0
		if distance > preferred_max:
			wanted = towards * walk_speed + sideways * strafe_speed * 0.4
		elif distance < preferred_min:
			wanted = -towards * walk_speed * 0.7 + sideways * strafe_speed * 0.5
		else:
			wanted = sideways * strafe_speed
	wanted += _pillar_push()
	var from_centre: Vector3 = _flat(global_position - arena_centre)
	if from_centre.length() > arena_radius:
		wanted -= from_centre.normalized() * walk_speed * (from_centre.length() - arena_radius) * 0.6
	velocity = wanted.limit_length(walk_speed * 1.2) * speed_factor
	move_and_slide()
	global_position.y = _ground_y
	model.walk_speed = velocity.length()
	_leave_trail(delta)
	if _hidden_time > hide_limit:
		_flight_wait = minf(_flight_wait, 0.0)
	if _flight_wait <= 0.0:
		_take_off()
		return
	if _attack_wait > 0.0:
		return
	if _hit_times.size() >= lap_hits and _cooldowns[&"lap"] <= 0.0:
		_roar()
		return
	var to_player: Vector3 = _flat(player.global_position - global_position)
	var player_angle: float = rad_to_deg(_forward().angle_to(to_player))
	var target_angle: float = rad_to_deg(_forward().angle_to(to_target))
	if target == player and player_angle > 100.0 and to_player.length() < tail_range and _cooldowns[&"tail"] <= 0.0:
		mode = Mode.TAIL_WINDUP
		_timer = tail_windup
		model.pose = AmberModel.Pose.TAIL
		_cooldowns[&"tail"] = tail_cooldown
	elif distance < 7.5 and target_angle < 50.0 and _cooldowns[&"wings"] <= 0.0 and _room_for_wings():
		mode = Mode.WINGS
		_timer = wing_time
		model.pose = AmberModel.Pose.WINGS
		_cooldowns[&"wings"] = wing_cooldown
	elif phase == 2 and to_player.length() < 14.0 and _cooldowns[&"stamp"] <= 0.0:
		mode = Mode.STOMP
		_timer = stamp_rear_time
		_waves_left = 2
		model.pose = AmberModel.Pose.ROAR
		_cooldowns[&"stamp"] = stamp_cooldown
		if stamps == 0:
			EventBus.message_requested.emit("Amber steigert! Spring over het vuur!")
	elif distance >= 5.0 and distance <= breath_range and target_angle < 30.0 and in_sight and _cooldowns[&"breath"] <= 0.0:
		mode = Mode.INHALE
		_timer = inhale_time
		model.pose = AmberModel.Pose.INHALE
		_cooldowns[&"breath"] = breath_cooldown * (0.7 if phase == 2 else 1.0)
	if mode != Mode.CHASE:
		model.walk_speed = 0.0


func _back_to_chase() -> void:
	mode = Mode.CHASE
	_attack_wait = attack_pause * (0.7 if phase == 2 else 1.0)
	model.pose = AmberModel.Pose.IDLE
	_pick_target()


func _pick_target() -> void:
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	target = player
	if phase == 1 and _klaas != null and _klaas.is_fighting() and randf() < KLAAS_SHARE:
		target = _klaas


func _target_position(player: Player) -> Vector3:
	return target.global_position if target != null and is_instance_valid(target) else player.global_position


## The targets of an attack: the player, and Klaas while he fights.
func _victims(player: Player) -> Array[Node3D]:
	var victims: Array[Node3D] = [player]
	if _klaas != null and _klaas.is_fighting():
		victims.append(_klaas)
	return victims


# --- Fire breath.

func _breath_half_angle() -> float:
	return breath_angle + (breath_sweep if phase == 2 else 0.0)


func _inhale(player: Player, delta: float, speed_factor: float) -> void:
	_timer -= delta * speed_factor
	# She aims during the first part, then locks: the fan on the floor stays.
	if _timer > inhale_time * 0.4:
		_turn_to(_target_position(player), delta, speed_factor * 1.5)
	var urgency: float = 1.0 - clampf(_timer / inhale_time, 0.0, 1.0)
	var neck: Array[Vector3] = _neck_zone()
	breath.show_warning(model.get_mouth(), _forward(), _breath_half_angle(), breath_range, _ground_y, urgency, _excluded, neck[0], neck[1], NECK_HEAT)
	if _timer <= 0.0:
		mode = Mode.BREATH
		breaths += 1
		_timer = breath_time
		_tick = 0.0
		_breath_yaw = rotation.y
		_sweep_side = 1.0 if randf() < 0.5 else -1.0
		model.pose = AmberModel.Pose.BREATH


func _breathe(player: Player, delta: float) -> void:
	_timer -= delta
	if phase == 2:
		var progress: float = 1.0 - clampf(_timer / breath_time, 0.0, 1.0)
		rotation.y = _breath_yaw + deg_to_rad(breath_sweep) * _sweep_side * lerpf(-1.0, 1.0, progress)
	var mouth: Vector3 = model.get_mouth()
	var shown: Vector3 = _forward().rotated(Vector3.UP, _breath_yaw - rotation.y) if phase == 2 else _forward()
	var neck: Array[Vector3] = _neck_zone()
	breath.show_warning(mouth, shown, _breath_half_angle(), breath_range, _ground_y, 1.0, _excluded, neck[0], neck[1], NECK_HEAT)
	breath.pour(mouth, _forward(), breath_angle, breath_range, _ground_y, delta, _excluded)
	_push_from_neck(player)
	_tick -= delta
	if _tick <= 0.0:
		_tick = BREATH_TICK
		_breath_tick(player)
	if _timer <= 0.0:
		breath.hide_warning()
		if phase == 2:
			for distance: float in [4.0, 8.0, 12.0]:
				_spawn_fire(_flat(mouth) + Vector3.UP * _ground_y + _forward() * distance)
		mode = Mode.PANT
		_timer = pant_time
		model.pose = AmberModel.Pose.PANT


## The floor under her neck, from the middle of her body to her mouth: it
## burns too, so running in under her head or chest is no way out of the
## breath.
func _neck_zone() -> Array[Vector3]:
	return [_flat(global_position), _flat(model.get_mouth())]


## The heat drives the player out from under her neck, sideways, every frame.
func _push_from_neck(player: Player) -> void:
	var neck: Array[Vector3] = _neck_zone()
	var feet: Vector3 = _flat(player.global_position)
	var nearest: Vector3 = Geometry3D.get_closest_point_to_segment(feet, neck[0], neck[1])
	if nearest.distance_to(feet) > NECK_HEAT:
		return
	var out: Vector3 = feet - nearest
	if out.length() < 0.2:
		out = _forward().cross(Vector3.UP)
	player.apply_wind(out.normalized() * NECK_PUSH)


func _breath_tick(player: Player) -> void:
	var mouth: Vector3 = model.get_mouth()
	var neck: Array[Vector3] = _neck_zone()
	for victim: Node3D in _victims(player):
		var feet: Vector3 = _flat(victim.global_position)
		var nearest: Vector3 = Geometry3D.get_closest_point_to_segment(feet, neck[0], neck[1])
		if nearest.distance_to(feet) <= NECK_HEAT:
			_hurt(victim, breath_damage)
			continue
		var chest: Vector3 = victim.global_position + Vector3.UP * CHEST
		var to: Vector3 = _flat(chest - mouth)
		if to.length() > breath_range or rad_to_deg(_forward().angle_to(to)) > breath_angle:
			continue
		if not _clear_line(mouth, chest, victim):
			continue
		_hurt(victim, breath_damage)


# --- Tail and wings.

func _tail_strike(player: Player) -> void:
	for victim: Node3D in _victims(player):
		var to: Vector3 = _flat(victim.global_position - global_position)
		if to.length() <= tail_range and rad_to_deg(_forward().angle_to(to)) > 70.0:
			_hurt(victim, data.damage)


func _wing_gust(player: Player) -> void:
	var to: Vector3 = _flat(player.global_position - global_position)
	if to.length() > wing_range or rad_to_deg(_forward().angle_to(to)) > 70.0:
		return
	if _clear_line(global_position + Vector3.UP * 3.0, player.global_position + Vector3.UP * 1.0, player):
		player.apply_wind(to.normalized() * wing_push)


## Spread wings reach about 9 m to either side: only gust with room.
func _room_for_wings() -> bool:
	for pillar: Vector3 in pillars:
		if _flat(pillar - global_position).length() < WING_REACH + pillar_radius:
			return false
	return _flat(global_position - arena_centre).length() + WING_REACH < wall_radius


func _wings_spread() -> bool:
	return mode in [Mode.WINGS, Mode.ROAR, Mode.STOMP] or (mode == Mode.TAKEOFF and _timer > TAKEOFF_TIME - TAKEOFF_CROUCH)


# --- Flight.

func _take_off() -> void:
	mode = Mode.TAKEOFF
	_timer = TAKEOFF_TIME
	_flight_from = global_position
	_flight_damage = 0
	_hidden_time = 0.0
	_flight_angle = atan2(global_position.z - arena_centre.z, global_position.x - arena_centre.x)
	model.pose = AmberModel.Pose.TAKEOFF
	model.walk_speed = 0.0


func _take_off_step(delta: float) -> void:
	_timer -= delta
	var rise: float = 1.0 - clampf(_timer / (TAKEOFF_TIME - TAKEOFF_CROUCH), 0.0, 1.0)
	if _timer > TAKEOFF_TIME - TAKEOFF_CROUCH:
		return
	# A leap and strong beats: fast at first, easing into the hover.
	model.pose = AmberModel.Pose.FLY
	global_position = _flight_from.lerp(_flight_spot(), 1.0 - pow(1.0 - rise, 2.0))
	if _timer <= 0.0:
		mode = Mode.FLYING
		_timer = flight_time
		_meteor_wait = 0.5


func _flight_spot() -> Vector3:
	return arena_centre + Vector3(cos(_flight_angle) * hover_radius, _ground_y - arena_centre.y + flight_height, sin(_flight_angle) * hover_radius)


func _fly(player: Player, delta: float) -> void:
	_timer -= delta
	_flight_angle += delta * 0.4
	global_position = global_position.lerp(_flight_spot(), 1.0 - exp(-3.0 * delta))
	_turn_to(player.global_position, delta, 2.0)
	var below: float = global_position.y - player.global_position.y
	model.look_pitch = -clampf(atan2(below, maxf(_flat(player.global_position - global_position).length(), 1.0)) * 0.6, 0.0, 0.7)
	_meteor_wait -= delta
	if _meteor_wait <= 0.0:
		_meteor_wait = meteor_interval / (enraged_speed_factor if phase == 2 else 1.0)
		_spit_meteor(player)
	if _flight_damage >= shoot_down_damage:
		mode = Mode.CRASH
		_timer = 0.6
		model.pose = AmberModel.Pose.DAZED
		EventBus.message_requested.emit("Amber stort neer! Raak haar kop!")
	elif _timer <= 0.0:
		mode = Mode.LAND
		_timer = LAND_TIME
		_land_from = global_position
		model.pose = AmberModel.Pose.LAND
	if mode != Mode.FLYING:
		_flight_wait = flight_interval * (0.7 if phase == 2 else 1.0)


func _spit_meteor(player: Player) -> void:
	if meteor_scene == null:
		return
	var mouth: Vector3 = model.get_mouth()
	var aim: Vector3 = player.global_position + Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-2.0, 2.0))
	# A pillar in the way catches the fireball.
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(mouth, aim + Vector3.UP * 0.5, PhysicsLayers.WORLD, [get_rid()])
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		aim = hit["position"]
	var meteor: Node3D = meteor_scene.instantiate() as Node3D
	get_parent().add_child(meteor)
	meteor.call(&"launch", mouth, aim, meteor_damage, self, fire_patch_scene, fire_patch_damage)


# --- The stamp of her second bar.

## She rears up, then stamps: two rings of fire run out over the floor,
## one after the other.
func _stamp(player: Player, delta: float) -> void:
	_timer -= delta
	_turn_to(player.global_position, delta, 1.5)
	if _timer > 0.0:
		return
	if _waves_left == 0:
		_back_to_chase()
		return
	if _waves_left == 2:
		stamps += 1
		model.pose = AmberModel.Pose.PANT
	_waves_left -= 1
	_timer = 0.55 if _waves_left > 0 else 0.9
	if fire_wave_scene != null:
		var wave: Node3D = fire_wave_scene.instantiate() as Node3D
		get_parent().add_child(wave)
		var chest: Vector3 = (model.get_node("Body/ProbeChest") as Node3D).global_position
		wave.global_position = Vector3(chest.x, _ground_y, chest.z)
		wave.call(&"start", fire_wave_damage, self)


# --- The lap along the arena wall.

func _roar() -> void:
	mode = Mode.ROAR
	_timer = roar_time
	_hit_times.clear()
	_cooldowns[&"lap"] = lap_cooldown
	model.pose = AmberModel.Pose.ROAR
	model.walk_speed = 0.0
	EventBus.subtitle_requested.emit("Amber", ROARS[randi() % ROARS.size()], 1.6)


func _start_lap(player: Player) -> void:
	mode = Mode.LAP
	laps += 1
	_trampled.clear()
	var own: float = _angle_of(global_position)
	_lap_gap = _nearest_gap(own)
	# She runs away from the player first.
	_lap_side = -1.0 if wrapf(_angle_of(player.global_position) - _lap_gap, -180.0, 180.0) > 0.0 else 1.0
	_lap_stage = 0
	_lap_travelled = 0.0
	_lap_angle = own
	_lap_time = 0.0
	model.pose = AmberModel.Pose.RUN


## Out through a gap between the pillars, a spiral out onto the ring and
## around it, and back in through a gap further on.
func _run_lap(player: Player, delta: float, speed_factor: float) -> void:
	_lap_time += delta
	var angle: float = _angle_of(global_position)
	_lap_travelled += absf(wrapf(angle - _lap_angle, -180.0, 180.0))
	_lap_angle = angle
	var from_centre: Vector3 = _flat(global_position - arena_centre)
	var radius: float = from_centre.length()
	var outward: Vector3 = from_centre.normalized() if radius > 0.1 else _forward()
	var wanted: Vector3 = Vector3.ZERO
	var speed: float = lap_speed
	var along: Vector3 = Vector3.UP.cross(outward) * _lap_side
	# Inside the pillars she heads straight out (or in); further out she
	# turns along the wall. She curves through the gap, as she is long.
	var turned: float = smoothstep(10.0, 17.0, radius)
	match _lap_stage:
		0:
			wanted = _flat(_ring_point(_lap_gap, 11.0) - global_position)
			if wanted.length() < 1.5 or _lap_time > 5.0:
				_lap_stage = 1
				_lap_travelled = 0.0
				_lap_time = 0.0
		1:
			wanted = along * turned + outward * (1.0 - turned) + outward * clampf((lap_radius - radius) * 0.3, -0.6, 0.6) * turned
			wanted += _pillar_push() * 0.3
			var end_gap: float = _nearest_gap(angle + _lap_side * 12.0)
			if (_lap_travelled > LAP_SPAN - 40.0 and absf(wrapf(angle + _lap_side * 12.0 - end_gap, -180.0, 180.0)) < 8.0) or _lap_time > 14.0:
				_lap_gap = end_gap
				_lap_stage = 2
				_lap_time = 0.0
		2:
			wanted = along * smoothstep(9.0, 18.0, radius) * 0.8 - outward + _pillar_push() * 0.3
			if radius < 7.0 or _lap_time > 5.0:
				_back_to_chase()
				return
	speed = walk_speed * 1.6 if _lap_stage == 0 else lap_speed
	velocity = wanted.normalized() * speed * speed_factor
	move_and_slide()
	global_position.y = _ground_y
	_turn_to(global_position + wanted, delta, 3.5 * speed_factor)
	model.pose = AmberModel.Pose.RUN if _lap_stage == 1 else AmberModel.Pose.IDLE
	model.walk_speed = speed
	_leave_trail(delta)
	for victim: Node3D in _victims(player):
		if victim in _trampled:
			continue
		for probe: Node3D in [model.get_node("Body/Neck/Head/ProbeHead") as Node3D, model.get_node("Body/ProbeChest") as Node3D]:
			if _flat(victim.global_position - probe.global_position).length() < TRAMPLE_REACH:
				_trampled.append(victim)
				_hurt(victim, data.damage)
				if victim is Player:
					(victim as Player).apply_wind(_flat(victim.global_position - global_position).normalized() * wing_push * 1.2)
				break


## Angle of [param point] around the middle of the arena, in degrees.
func _angle_of(point: Vector3) -> float:
	return rad_to_deg(atan2(point.z - arena_centre.z, point.x - arena_centre.x))


## The gap between two pillars nearest to [param angle] (degrees).
func _nearest_gap(angle: float) -> float:
	var best: float = angle
	var best_distance: float = INF
	for pillar: Vector3 in pillars:
		var pillar_angle: float = rad_to_deg(atan2(pillar.z - arena_centre.z, pillar.x - arena_centre.x))
		for gap: float in [pillar_angle + 36.0, pillar_angle - 36.0]:
			var distance: float = absf(wrapf(gap - angle, -180.0, 180.0))
			if distance < best_distance:
				best_distance = distance
				best = gap
	return best


func _ring_point(angle: float, radius: float) -> Vector3:
	var a: float = deg_to_rad(angle)
	return Vector3(arena_centre.x + cos(a) * radius, _ground_y, arena_centre.z + sin(a) * radius)


# --- Keeping her body clear of pillars and wall.

## A push away from pillars close to her, to steer around them.
func _pillar_push() -> Vector3:
	var push: Vector3 = Vector3.ZERO
	for probe: Array in model.get_probes(false):
		var point: Vector3 = (probe[0] as Node3D).global_position
		for pillar: Vector3 in pillars:
			var away: Vector3 = _flat(point - pillar)
			var room: float = away.length() - pillar_radius - float(probe[1])
			if room < 3.0:
				push += away.normalized() * (3.0 - room) * 1.2
	return push


## Moves her out of any pillar or wall that a part of her body reaches into.
func _keep_clear() -> void:
	var spread: bool = _wings_spread()
	for attempt: int in 3:
		var push: Vector3 = Vector3.ZERO
		for probe: Array in model.get_probes(spread):
			var point: Vector3 = (probe[0] as Node3D).global_position
			var radius: float = float(probe[1])
			for pillar: Vector3 in pillars:
				var away: Vector3 = _flat(point - pillar)
				var overlap: float = pillar_radius + radius - away.length()
				if overlap > 0.0:
					push += away.normalized() * overlap
			var out: Vector3 = _flat(point - arena_centre)
			var past: float = out.length() + radius - wall_radius
			if past > 0.0:
				push -= out.normalized() * past
		if push.length() < 0.01:
			return
		global_position += push


# --- Shared.

func _leave_trail(delta: float) -> void:
	if phase != 2 or velocity.length() < 0.1:
		return
	_trail_wait -= delta
	if _trail_wait <= 0.0:
		_trail_wait = TRAIL_EVERY
		_spawn_fire(global_position - _forward() * 3.0)


func _hurt(victim: Node3D, amount: int) -> void:
	if victim is KlaasAlly:
		(victim as KlaasAlly).take_hit()
	elif victim is Player:
		(victim as Player).get_node("Hurtbox").call(&"receive_hit", HitData.new(amount, self, _hit_ref))


## True when no wall or pillar stands between [param from] and [param to].
func _clear_line(from: Vector3, to: Vector3, victim: Node3D) -> bool:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to, PhysicsLayers.WORLD, [get_rid()])
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == victim


func _spawn_fire(at: Vector3) -> void:
	if fire_patch_scene == null:
		return
	var patch: Node3D = fire_patch_scene.instantiate() as Node3D
	get_parent().add_child(patch)
	patch.global_position = Vector3(at.x, _ground_y, at.z)
	patch.call(&"ignite", fire_patch_damage, self)


func _start_fight(player: Player) -> void:
	GameState.block_saving(SAVE_BLOCK)
	EventBus.boss_started.emit("%s – 1/2" % data.display_name, health.max_health)
	EventBus.subtitle_requested.emit("Amber", "Kijk eens wie daar is. Het niemandje en zijn bodybuilder.", 3.0)
	if _gate != null:
		_gate.set_open(false)
	if _klaas != null and _klaas.mode in [KlaasAlly.Mode.WAITING, KlaasAlly.Mode.FOLLOW]:
		# Klaas comes in with the player, not stuck behind the gate.
		if _klaas.global_position.distance_to(player.global_position) > 8.0:
			_klaas.global_position = player.global_position + _flat(player.global_position - global_position).normalized() * 2.0
		_klaas.join_fight(self)
	_flight_wait = flight_interval
	_attack_wait = attack_pause
	target = player
	mode = Mode.CHASE


func _can_be_hurt() -> bool:
	return mode not in [Mode.WAITING, Mode.TRANSITION, Mode.DEAD]


func _on_hit_received(hit: HitData, head: bool) -> void:
	if not _can_be_hurt():
		return
	var factor: float = HEAD_FACTOR if head and mode in [Mode.PANT, Mode.DAZED] else 1.0
	var amount: int = roundi(hit.damage * factor)
	# One swing can touch head and body: it counts once, the best of the two.
	if hit.hitbox != null:
		var key: int = hit.hitbox.get_instance_id()
		var recent: Array = _recent_hits.get(key, [-INF, 0])
		if _clock - float(recent[0]) < SAME_SWING:
			amount -= int(recent[1])
			if amount <= 0:
				return
			_recent_hits[key] = [_clock, int(recent[1]) + amount]
		else:
			_recent_hits[key] = [_clock, amount]
	if is_flying():
		_flight_damage += amount
	elif hit.source is Player:
		# A flurry of hits makes her run a lap (see _stalk).
		_hit_times.append(_clock)
		while not _hit_times.is_empty() and _clock - _hit_times[0] > lap_window:
			_hit_times.pop_front()
	health.take_damage(amount)


func _on_health_changed(current: int, maximum: int) -> void:
	EventBus.boss_health_changed.emit(current, maximum)
	if phase == 2 and helps < help_at.size() and float(current) / float(maximum) <= help_at[helps]:
		_call_helpers()


func _call_helpers() -> void:
	EventBus.message_requested.emit("Amber roept haar cultisten uit Zevenaar!")
	var parent: Node3D = get_parent() as Node3D
	for i: int in [helps * 2, helps * 2 + 1]:
		if helper_scene == null or i >= helper_offsets.size():
			continue
		var helper: Node3D = helper_scene.instantiate() as Node3D
		# Placed before it enters the tree, so the spot becomes its home.
		helper.position = parent.to_local(arena_centre + helper_offsets[i])
		parent.add_child(helper)
		helper.call(&"notice_player")
	helps += 1


func _on_bar_empty() -> void:
	if phase == 1:
		_transition()
	else:
		_die()


## Klaas saves the player from her deadly fireball and falls. Then the second
## bar starts. The scene is staged in the middle of the arena, so every shot
## shows it clearly: Amber lowers her head at the player and gathers a
## fireball in her mouth; Klaas runs in from the side and, in slow motion,
## dives into its path; the fireball hits him and throws him back.
func _transition() -> void:
	mode = Mode.TRANSITION
	breath.hide_warning()
	model.tail_sweep = 0.0
	model.walk_speed = 0.0
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	var scene: Cutscene = Cutscene.begin(get_parent() as Node3D)
	# Amber in the middle, facing the gate; the player in front of her head,
	# Klaas off to the side.
	var ahead: Vector3 = Vector3(0, 0, 1)
	var side: Vector3 = Vector3(1, 0, 0)
	global_position = Vector3(arena_centre.x, _ground_y, arena_centre.z)
	_face_now(global_position + ahead)
	reset_physics_interpolation()
	var spot: Vector3 = global_position + ahead * 12.5
	player.global_position = spot
	player.rotation.y = atan2(ahead.x, ahead.z)
	player.reset_physics_interpolation()
	var klaas_start: Vector3 = spot - ahead * 1.0 + side * 6.0
	if _klaas != null:
		_klaas.set_physics_process(false)
		_klaas.global_position = klaas_start
		_klaas.rotation.y = atan2(side.x, side.z)
		_klaas.reset_physics_interpolation()
	model.pose = AmberModel.Pose.IDLE
	model.look_pitch = 0.0
	# 1. Wide, from the side: Amber, the player and Klaas.
	scene.look(spot - ahead * 5.0 - side * 13.0 + Vector3.UP * 4.0, spot - ahead * 5.0 + Vector3.UP * 2.0)
	await scene.say("Amber", "Genoeg! Jij en je opgepompte vriend zijn klaar.", 2.8)
	# 2. Over the player's shoulder: her head comes down at them, fire in her mouth.
	scene.look(spot + ahead * 3.0 + side * 1.0 + Vector3.UP * 2.0, model.get_mouth())
	model.pose = AmberModel.Pose.BREATH
	var lower: Tween = create_tween()
	lower.tween_property(model, "look_pitch", -0.6, 1.4).set_trans(Tween.TRANS_SINE)
	_charge_ball.visible = true
	var grow: Tween = create_tween()
	grow.tween_property(_charge_ball, "scale", Vector3.ONE * 2.2, 2.2).from(Vector3.ONE * 0.2)
	await scene.wait(1.0)
	await scene.say("Amber", "Verbrand, niemand!", 2.0)
	# 3. Klaas sees it and runs in.
	scene.look(spot - ahead * 2.5 - side * 9.0 + Vector3.UP * 2.4, spot - ahead * 2.5 + side * 2.0 + Vector3.UP * 1.4)
	var cover: Vector3 = spot - ahead * 2.6
	if _klaas != null:
		_klaas.say("NEE!")
		_klaas.model.set_locomotion(7.5, true, true)
		var run: Tween = create_tween()
		run.tween_property(_klaas, "global_position", cover + side * 2.4, 0.9)
		await run.finished
	# 4. Slow motion: he dives into the path as the fireball flies.
	Engine.time_scale = 0.35
	var ball: MeshInstance3D = MeshInstance3D.new()
	ball.mesh = (_charge_ball as MeshInstance3D).mesh
	ball.scale = Vector3.ONE * 1.6
	get_parent().add_child(ball)
	ball.global_position = model.get_mouth()
	_charge_ball.visible = false
	var shot: Tween = create_tween()
	shot.tween_property(ball, "global_position", cover + Vector3.UP * 1.3, 0.6)
	if _klaas != null:
		_klaas.model.set_locomotion(0.0, false, true)
		_klaas.model.play_action(&"dive", 0.6, true)
		var dive: Tween = create_tween()
		dive.tween_property(_klaas, "global_position", cover + Vector3.UP * 0.4, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await shot.finished
	# 5. The hit: a flash, Klaas is thrown back and falls; the player stumbles.
	var flash: OmniLight3D = OmniLight3D.new()
	flash.light_color = Color(1.0, 0.55, 0.15)
	flash.omni_range = 16.0
	flash.light_energy = 12.0
	get_parent().add_child(flash)
	flash.global_position = cover + Vector3.UP * 1.5
	ball.queue_free()
	if _klaas != null:
		_klaas.fall()
		var thrown: Tween = create_tween()
		thrown.tween_property(_klaas, "global_position", cover + ahead * 1.6, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	player.model.play_action(&"hurt", 0.6)
	var fade: Tween = create_tween()
	fade.tween_property(flash, "light_energy", 0.0, 0.8)
	fade.tween_callback(flash.queue_free)
	await scene.wait(0.6)
	Engine.time_scale = 1.0
	model.pose = AmberModel.Pose.IDLE
	var raise: Tween = create_tween()
	raise.tween_property(model, "look_pitch", 0.0, 1.0)
	# 6. Close on Klaas on the floor.
	var lying: Vector3 = _klaas.global_position if _klaas != null else cover
	await scene.glide(lying + side * 3.0 + ahead * 1.5 + Vector3.UP * 1.6, lying + Vector3.UP * 0.4, 1.4)
	await scene.say("Klaas", "Niet... op mijn... maatje...", 2.8)
	await scene.say("Klaas", "Pak haar. Voor Elst.", 2.4)
	scene.look(spot + ahead * 3.0 + side * 1.0 + Vector3.UP * 2.2, global_position + Vector3.UP * 4.0)
	await scene.say("Amber", "Eén minder. Nu jij.", 2.2)
	if _klaas != null:
		_klaas.set_physics_process(true)
	scene.finish()
	GameState.set_flag(&"klaas_fallen")
	_start_phase_two()


func _start_phase_two() -> void:
	phase = 2
	health.reset(data.get_max_health())
	EventBus.boss_started.emit("%s – 2/2" % data.display_name, health.max_health)
	_rage_light.visible = true
	_flight_wait = flight_interval * 0.7
	_attack_wait = attack_pause
	_hit_times.clear()
	target = get_tree().get_first_node_in_group(&"player") as Player
	mode = Mode.CHASE


func _die() -> void:
	mode = Mode.DEAD
	breath.hide_warning()
	_body_hurtbox.set_enabled(false)
	_head_hurtbox.set_enabled(false)
	_rage_light.visible = false
	model.pose = AmberModel.Pose.DEAD
	model.walk_speed = 0.0
	global_position.y = _ground_y
	GameState.set_flag(defeated_flag)
	EventBus.enemy_killed.emit(data.id)
	_end_fight()
	EventBus.message_requested.emit("Amber de Draak is verslagen!")
	EventBus.subtitle_requested.emit("Amber", "Dit... is niet... het einde...", 3.0)
	_drop_tren_spuit()
	SaveManager.request_autosave()


func _drop_tren_spuit() -> void:
	if tren_spuit_scene == null:
		return
	var spuit: Node3D = tren_spuit_scene.instantiate() as Node3D
	get_parent().add_child(spuit)
	# In front of her, but not in a pillar.
	var spot: Vector3 = _flat(global_position) + _forward() * 9.0
	for pillar: Vector3 in pillars:
		if _flat(spot - pillar).length() < pillar_radius + 1.0:
			spot = _flat(global_position) - _forward() * 2.0 + _forward().cross(Vector3.UP) * 5.0
	spuit.global_position = Vector3(spot.x, _ground_y, spot.z)


func _end_fight() -> void:
	GameState.unblock_saving(SAVE_BLOCK)
	EventBus.boss_ended.emit()
	if _gate != null:
		_gate.set_open(true)


## [param point], pulled in so it stays inside the arena wall (for the camera).
func _inside_arena(point: Vector3) -> Vector3:
	var from_centre: Vector3 = _flat(point - arena_centre)
	if from_centre.length() > arena_radius + 2.0:
		from_centre = from_centre.normalized() * (arena_radius + 2.0)
	return Vector3(arena_centre.x + from_centre.x, point.y, arena_centre.z + from_centre.z)


func _forward() -> Vector3:
	return -global_basis.z


func _flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)


func _turn_to(point: Vector3, delta: float, factor: float) -> void:
	var to: Vector3 = _flat(point - global_position)
	if to.length() < 0.1:
		return
	var wanted: float = atan2(-to.x, -to.z)
	rotation.y = rotate_toward(rotation.y, wanted, turn_speed * factor * delta)


func _face_now(point: Vector3) -> void:
	var to: Vector3 = _flat(point - global_position)
	if to.length() > 0.1:
		rotation.y = atan2(-to.x, -to.z)


func _exit_tree() -> void:
	# Leaving mid-fight (the player died and a save loads) ends the fight too.
	if mode not in [Mode.WAITING, Mode.DEAD]:
		_end_fight()
