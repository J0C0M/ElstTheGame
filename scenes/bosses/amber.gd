class_name Amber
extends CharacterBody3D
## Amber de Draak, the last boss, in the round arena under the church. She
## has two health bars. With the first, Klaas fights along and she aims part
## of her attacks at him. Every attack is announced and leaves an opening:
## - fire breath in a cone: a pillar in between stops it; afterwards she pants
##   with her head low, and her head takes double damage;
## - a tail swipe at whoever stands beside or behind her;
## - wing gusts that blow the player away (a pillar shields you too);
## - now and then she flies up and spits fireballs: three crossbow bolts
##   bring her down, and dazed on the floor her head takes double damage.
## When the first bar is empty a scene follows in which Klaas saves the
## player and falls. With the second bar she is furious: faster, burning
## patches where she walks and after her breath, and twice she calls
## drillers. When she dies she drops the golden Tren syringe. Saving is
## blocked during the fight and the gate is shut; a GameState flag keeps her
## beaten.

enum Mode { WAITING, CHASE, INHALE, BREATH, PANT, TAIL_WINDUP, TAIL, WINGS, TAKEOFF, FLYING, CRASH, DAZED, LAND, TRANSITION, DEAD }

## Health per bar, tail damage.
@export var data: EnemyData
@export var defeated_flag: StringName = &"boss_amber"
## FlagGate of the arena: shut while the fight lasts.
@export var gate_path: NodePath
@export var klaas_path: NodePath
## Middle of the arena; she stays within arena_radius of it.
@export var arena_centre: Vector3
@export var arena_radius: float = 15.0
@export var start_radius: float = 20.0
@export var walk_speed: float = 4.2
@export var turn_speed: float = 1.6
@export_group("Breath")
@export var breath_range: float = 14.0
@export var breath_angle: float = 25.0
## Damage every quarter second in the flames.
@export var breath_damage: int = 8
@export var inhale_time: float = 0.8
@export var breath_time: float = 2.0
@export var pant_time: float = 2.0
@export_group("Tail and wings")
@export var tail_windup: float = 0.6
@export var tail_range: float = 9.0
@export var wing_time: float = 2.5
@export var wing_push: float = 10.0
@export var wing_range: float = 16.0
@export_group("Flight")
@export var flight_interval: float = 25.0
@export var flight_height: float = 10.0
@export var flight_time: float = 12.0
## Crossbow damage in the air that brings her down.
@export var shoot_down_damage: int = 90
@export var meteor_scene: PackedScene
@export var meteor_interval: float = 0.8
@export var meteor_damage: int = 18
@export var dazed_time: float = 4.0
@export_group("Second bar")
@export var enraged_speed_factor: float = 1.3
@export var fire_patch_scene: PackedScene
@export var fire_patch_damage: int = 6
@export var helper_scene: PackedScene
## Where the drillers come in, from the arena centre; two per call.
@export var helper_offsets: Array[Vector3] = []
## Health ratios of the second bar at which she calls drillers.
@export var help_at: Array[float] = [0.66, 0.33]
@export var tren_spuit_scene: PackedScene

const SAVE_BLOCK: StringName = &"boss"
const HEAD_FACTOR: float = 2.0
const BREATH_TICK: float = 0.25
const KLAAS_SHARE: float = 0.35
const ATTACK_PAUSE: float = 1.0
const TRAIL_EVERY: float = 1.2
const SAME_SWING: float = 0.3

var mode: Mode = Mode.WAITING
## 1 or 2: which health bar she is on.
var phase: int = 1
## The player or Klaas: whom her next attack is for.
var target: Node3D
## How many times she called drillers, for tests.
var helps: int = 0
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
var _clock: float = 0.0
var _recent_hits: Dictionary = {}
var _gate: FlagGate
var _klaas: KlaasAlly

@onready var model: AmberModel = $Model
@onready var health: HealthComponent = $Health
@onready var _body_hurtbox: Hurtbox = $BodyHurtbox
@onready var _head_hurtbox: Hurtbox = $Model/Body/Neck/Head/HeadHurtbox
@onready var _hit_ref: Hitbox = $AttackHitbox
@onready var _breath_stream: Node3D = $Model/Body/Neck/Head/BreathStream
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
	_breath_stream.visible = false
	_charge_ball.visible = false
	_rage_light.visible = false


func is_flying() -> bool:
	return mode in [Mode.TAKEOFF, Mode.FLYING]


## Klaas hits her. Only on the ground and when she can be hurt.
func take_ally_hit(amount: int) -> void:
	if _can_be_hurt() and not is_flying():
		health.take_damage(amount)


func _physics_process(delta: float) -> void:
	_clock += delta
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	if player == null or mode in [Mode.DEAD, Mode.TRANSITION]:
		return
	var speed_factor: float = enraged_speed_factor if phase == 2 else 1.0
	match mode:
		Mode.WAITING:
			model.pose = AmberModel.Pose.IDLE
			if _flat(player.global_position - global_position).length() <= start_radius:
				_start_fight(player)
		Mode.CHASE:
			_chase(player, delta, speed_factor)
		Mode.INHALE:
			_timer -= delta * speed_factor
			_turn_to(_target_position(player), delta, speed_factor)
			if _timer <= 0.0:
				mode = Mode.BREATH
				_timer = breath_time
				_tick = 0.0
				model.pose = AmberModel.Pose.BREATH
				_breath_stream.visible = true
		Mode.BREATH:
			_timer -= delta
			_turn_to(_target_position(player), delta, 0.35)
			_tick -= delta
			if _tick <= 0.0:
				_tick = BREATH_TICK
				_breath_tick(player)
			if _timer <= 0.0:
				_breath_stream.visible = false
				if phase == 2:
					for distance: float in [4.0, 8.0, 12.0]:
						_spawn_fire(global_position + _forward() * distance)
				mode = Mode.PANT
				_timer = pant_time
				model.pose = AmberModel.Pose.PANT
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
			_wing_gust(player)
			if _timer <= 0.0:
				_back_to_chase()
		Mode.TAKEOFF:
			_timer -= delta
			var rise: float = 1.0 - clampf(_timer / 1.5, 0.0, 1.0)
			global_position = _flight_from.lerp(_flight_spot(), rise)
			if _timer <= 0.0:
				mode = Mode.FLYING
				_timer = flight_time
				_meteor_wait = 0.5
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
			global_position.y = move_toward(global_position.y, _ground_y, flight_height / 1.2 * delta)
			if _timer <= 0.0:
				global_position.y = _ground_y
				_back_to_chase()


func _chase(player: Player, delta: float, speed_factor: float) -> void:
	model.pose = AmberModel.Pose.IDLE
	if target == null or not is_instance_valid(target):
		target = player
	var to_target: Vector3 = _flat(_target_position(player) - global_position)
	_turn_to(_target_position(player), delta, speed_factor)
	_attack_wait -= delta
	_flight_wait -= delta
	var planar: Vector3 = Vector3.ZERO
	if to_target.length() > 7.0:
		planar = _forward() * walk_speed * speed_factor
	# Back towards the middle when she wanders to the wall.
	var from_centre: Vector3 = _flat(global_position - arena_centre)
	if from_centre.length() > arena_radius:
		planar = -from_centre.normalized() * walk_speed
	velocity = planar
	move_and_slide()
	global_position.y = _ground_y
	model.walk_speed = planar.length()
	if phase == 2 and planar.length() > 0.1:
		_trail_wait -= delta
		if _trail_wait <= 0.0:
			_trail_wait = TRAIL_EVERY
			_spawn_fire(global_position - _forward() * 3.0)
	if _flight_wait <= 0.0:
		_take_off()
		return
	if _attack_wait > 0.0:
		return
	var to_player: Vector3 = _flat(player.global_position - global_position)
	var player_angle: float = rad_to_deg(_forward().angle_to(to_player))
	if target == player and player_angle > 110.0 and to_player.length() < tail_range:
		mode = Mode.TAIL_WINDUP
		_timer = tail_windup
		model.pose = AmberModel.Pose.TAIL
	elif target == player and to_player.length() < 6.0:
		mode = Mode.WINGS
		_timer = wing_time
		model.pose = AmberModel.Pose.WINGS
	elif to_target.length() < breath_range and rad_to_deg(_forward().angle_to(to_target)) < 20.0:
		mode = Mode.INHALE
		_timer = inhale_time
		model.pose = AmberModel.Pose.INHALE
	model.walk_speed = 0.0 if mode != Mode.CHASE else model.walk_speed


func _back_to_chase() -> void:
	mode = Mode.CHASE
	_attack_wait = ATTACK_PAUSE
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


func _breath_tick(player: Player) -> void:
	var mouth: Vector3 = global_position + Vector3.UP * 4.0 + _forward() * 5.0
	for victim: Node3D in _victims(player):
		var to: Vector3 = victim.global_position + Vector3.UP * 1.2 - mouth
		if to.length() > breath_range or rad_to_deg(_forward().angle_to(_flat(to))) > breath_angle:
			continue
		if not _clear_line(mouth, victim.global_position + Vector3.UP * 1.2, victim):
			continue
		_hurt(victim, breath_damage)


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


func _take_off() -> void:
	mode = Mode.TAKEOFF
	_timer = 1.5
	_flight_from = global_position
	_flight_damage = 0
	_flight_angle = atan2(global_position.z - arena_centre.z, global_position.x - arena_centre.x)
	model.pose = AmberModel.Pose.FLY
	model.walk_speed = 0.0


func _flight_spot() -> Vector3:
	return arena_centre + Vector3(cos(_flight_angle) * 8.0, _ground_y - arena_centre.y + flight_height, sin(_flight_angle) * 8.0)


func _fly(player: Player, delta: float) -> void:
	_timer -= delta
	_flight_angle += delta * 0.5
	global_position = _flight_spot()
	_turn_to(player.global_position, delta, 2.0)
	_meteor_wait -= delta
	if _meteor_wait <= 0.0:
		_meteor_wait = meteor_interval / (enraged_speed_factor if phase == 2 else 1.0)
		_spit_meteor(player)
	if _flight_damage >= shoot_down_damage:
		mode = Mode.CRASH
		_timer = 0.6
		EventBus.message_requested.emit("Amber stort neer! Raak haar kop!")
	elif _timer <= 0.0:
		mode = Mode.LAND
		_timer = 1.2
	if mode != Mode.FLYING:
		_flight_wait = flight_interval * (0.7 if phase == 2 else 1.0)


func _spit_meteor(player: Player) -> void:
	if meteor_scene == null:
		return
	var mouth: Vector3 = global_position + Vector3.UP * 2.0 + _forward() * 4.0
	var aim: Vector3 = player.global_position + Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-2.0, 2.0))
	# A pillar in the way catches the fireball.
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(mouth, aim + Vector3.UP * 0.5, PhysicsLayers.WORLD, [get_rid()])
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		aim = hit["position"]
	var meteor: Node3D = meteor_scene.instantiate() as Node3D
	get_parent().add_child(meteor)
	meteor.call(&"launch", mouth, aim, meteor_damage, self, fire_patch_scene, fire_patch_damage)


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
	health.take_damage(amount)


func _on_health_changed(current: int, maximum: int) -> void:
	EventBus.boss_health_changed.emit(current, maximum)
	if phase == 2 and helps < help_at.size() and float(current) / float(maximum) <= help_at[helps]:
		_call_helpers()


func _call_helpers() -> void:
	EventBus.message_requested.emit("Amber roept haar drillers!")
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
## bar starts.
func _transition() -> void:
	mode = Mode.TRANSITION
	_breath_stream.visible = false
	model.tail_sweep = 0.0
	global_position.y = _ground_y
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	var scene: Cutscene = Cutscene.begin(get_parent() as Node3D)
	var away: Vector3 = _flat(player.global_position - global_position).normalized()
	if away.length() < 0.5:
		away = -_forward()
	_face_now(player.global_position)
	var middle: Vector3 = (global_position + player.global_position) * 0.5
	var side: Vector3 = away.cross(Vector3.UP).normalized()
	# Over the player's shoulder: Amber in front, room for Klaas in between.
	scene.look(_inside_arena(player.global_position + away * 7.0 + side * 5.0) + Vector3.UP * 5.0, global_position + Vector3.UP * 3.0)
	model.pose = AmberModel.Pose.INHALE
	await scene.say("Amber", "Genoeg! Jij en je opgepompte vriend zijn klaar.")
	_charge_ball.visible = true
	var tween: Tween = create_tween()
	tween.tween_property(_charge_ball, "scale", Vector3.ONE * 2.5, 1.4).from(Vector3.ONE * 0.3)
	await scene.say("Amber", "Verbrand, niemand!", 1.6)
	if _klaas != null:
		_klaas.global_position = player.global_position - away * 1.6
		_klaas.rotation.y = atan2(away.x, away.z)
		_klaas.say("NEE!")
	await scene.wait(0.8)
	_charge_ball.visible = false
	if _klaas != null:
		_klaas.fall()
	player.global_position += away * 3.0
	player.reset_physics_interpolation()
	model.pose = AmberModel.Pose.IDLE
	await scene.glide(_inside_arena(player.global_position + away * 5.0) + Vector3.UP * 3.0, _klaas.global_position if _klaas != null else middle, 1.2)
	await scene.say("Klaas", "Niet... op mijn... maatje...", 2.8)
	await scene.say("Klaas", "Pak haar. Voor Elst.", 2.4)
	await scene.say("Amber", "Eén minder. Nu jij.", 2.2)
	scene.finish()
	GameState.set_flag(&"klaas_fallen")
	_start_phase_two()


func _start_phase_two() -> void:
	phase = 2
	health.reset(data.get_max_health())
	EventBus.boss_started.emit("%s – 2/2" % data.display_name, health.max_health)
	_rage_light.visible = true
	_flight_wait = flight_interval * 0.7
	_attack_wait = ATTACK_PAUSE
	target = get_tree().get_first_node_in_group(&"player") as Player
	mode = Mode.CHASE


func _die() -> void:
	mode = Mode.DEAD
	_breath_stream.visible = false
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
	var spot: Vector3 = global_position + _forward() * 7.0
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
