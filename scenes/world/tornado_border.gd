class_name TornadoBorder
extends Node3D
## The tornado around Elst: a spinning wall of dust and debris that can be
## seen from everywhere. Close to it the wind pushes the player back, and a
## solid ring behind that keeps everyone inside. After Amber the end scene
## calls dissolve(): the dust walls fade and sink, the debris spins away and
## the haze lifts. With [member gone_flag] set (also after loading) it stays
## gone. Walking out of Elst then plays a short scene instead: the player
## says they stay to celebrate a while, and walks back a few metres.

const MESSAGE: String = "De tornado is te sterk. Je kunt Elst niet ontsnappen."
const GONE_LINE: String = "Waar ga ik heen? Ik blijf het nog even vieren in Elst!"
## How far back into Elst the player walks after the line, in metres.
const WALK_BACK: float = 6.0
## Mist and light of a clear day once the tornado is gone.
const CLEAR_FOG_BEGIN: float = 120.0
const CLEAR_FOG_END: float = 520.0
const CLEAR_FOG_COLOR: Color = Color(0.78, 0.82, 0.86)
const DEBRIS_COLORS: Array[Color] = [
	Color(0.45, 0.32, 0.2), Color(0.5, 0.48, 0.45), Color(0.35, 0.3, 0.26), Color(0.62, 0.5, 0.36),
]

## Radius of the solid wall, in metres from this node.
@export var radius: float = 240.0
## From this radius on the wind pushes inwards, harder closer to the wall.
@export var push_start_radius: float = 222.0
## Wind speed right at the wall, in metres per second. Faster than sprinting.
@export var max_wind_speed: float = 11.0
## Seconds between two warning messages.
@export var message_cooldown: float = 5.0
@export var debris_count: int = 260
## Turn speed of the flying debris, in radians per second.
@export var debris_spin_speed: float = 0.12
@export var wall_segments: int = 64
## GameState flag that keeps the tornado gone.
@export var gone_flag: StringName = &"tornado_gone"

var _message_wait: float = 0.0
var _gone: bool = false
var _turning_back: bool = false

@onready var _debris: MultiMeshInstance3D = $Debris
@onready var _wall: StaticBody3D = $Wall


func _ready() -> void:
	_build_wall()
	_build_debris()
	if GameState.has_flag(gone_flag):
		_gone = true
		for part: Node3D in [$OuterWall, $InnerWall, _debris]:
			part.visible = false
		_clear_sky.call_deferred(0.0)


func is_gone() -> bool:
	return _gone


## Makes the tornado disappear over [param seconds]: the walls fade and
## sink, the debris spins faster and is gone, the haze lifts. Sets the flag.
func dissolve(seconds: float = 6.0) -> void:
	_gone = true
	GameState.set_flag(gone_flag)
	var tween: Tween = create_tween().set_parallel(true)
	for wall: MeshInstance3D in [$OuterWall as MeshInstance3D, $InnerWall as MeshInstance3D]:
		# A copy: the material is shared with every Elst loaded later on.
		var material: ShaderMaterial = ((wall.mesh as PrimitiveMesh).material as ShaderMaterial).duplicate() as ShaderMaterial
		wall.material_override = material
		tween.tween_property(material, "shader_parameter/opacity", 0.0, seconds).set_ease(Tween.EASE_IN)
		tween.tween_property(material, "shader_parameter/spin_speed", 0.05, seconds)
		tween.tween_property(wall, "scale:y", 0.05, seconds).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "debris_spin_speed", 1.2, seconds * 0.5)
	tween.tween_property(_debris, "scale", Vector3(1.15, 0.02, 1.15), seconds).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.chain().tween_callback(func() -> void:
		for part: Node3D in [$OuterWall, $InnerWall, _debris]:
			part.visible = false)
	_clear_sky(seconds)


## Elst is free and the player wants to leave: a short scene in which they
## change their mind and walk back a few metres.
func _turn_back(player: Player, outward: Vector3) -> void:
	_turning_back = true
	var scene: Cutscene = Cutscene.begin(get_parent() as Node3D)
	var side: Vector3 = outward.cross(Vector3.UP)
	var start: Vector3 = player.global_position
	var home: Vector3 = start - outward * WALK_BACK
	# First looking out, the way they wanted to go.
	player.rotation.y = atan2(-outward.x, -outward.z)
	player.reset_physics_interpolation()
	scene.look(start + side * 4.5 - outward * 2.0 + Vector3.UP * 1.9, start + Vector3.UP * 1.3)
	await scene.say("Jij", GONE_LINE, 2.8)
	# Turn round and walk back into Elst; the model keeps moving meanwhile.
	player.rotation.y = atan2(outward.x, outward.z)
	player.model.process_mode = Node.PROCESS_MODE_ALWAYS
	player.model.set_locomotion(2.6, false, true)
	var walk: Tween = create_tween()
	walk.tween_property(player, "global_position", Vector3(home.x, start.y, home.z), WALK_BACK / 2.6)
	await walk.finished
	player.model.set_locomotion(0.0, false, true)
	player.model.process_mode = Node.PROCESS_MODE_INHERIT
	player.reset_physics_interpolation()
	scene.finish()
	_turning_back = false


## Lifts the haze to the mist of a clear day, over [param seconds].
func _clear_sky(seconds: float) -> void:
	var environment: WorldEnvironment = get_parent().get_node_or_null(^"WorldEnvironment") as WorldEnvironment
	if environment == null or environment.environment == null:
		return
	# A copy: the environment is shared with every Elst loaded later on.
	var env: Environment = environment.environment.duplicate() as Environment
	environment.environment = env
	if seconds <= 0.0:
		env.fog_depth_begin = CLEAR_FOG_BEGIN
		env.fog_depth_end = CLEAR_FOG_END
		env.fog_light_color = CLEAR_FOG_COLOR
		return
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(env, "fog_depth_begin", CLEAR_FOG_BEGIN, seconds)
	tween.tween_property(env, "fog_depth_end", CLEAR_FOG_END, seconds)
	tween.tween_property(env, "fog_light_color", CLEAR_FOG_COLOR, seconds)


func _physics_process(delta: float) -> void:
	_debris.rotate_y(debris_spin_speed * delta)
	_message_wait = maxf(_message_wait - delta, 0.0)
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	if player == null:
		return
	var offset: Vector3 = player.global_position - global_position
	offset.y = 0.0
	var distance: float = offset.length()
	if distance <= push_start_radius:
		return
	if _gone:
		if not _turning_back and not GameState.is_saving_blocked():
			_turn_back(player, offset.normalized())
		return
	if _message_wait <= 0.0:
		_message_wait = message_cooldown
		EventBus.message_requested.emit(MESSAGE)
	var strength: float = clampf(inverse_lerp(push_start_radius, radius, distance), 0.0, 1.0)
	player.apply_wind(-offset.normalized() * max_wind_speed * strength)


func _build_wall() -> void:
	_wall.collision_layer = PhysicsLayers.TORNADO_BORDER
	_wall.collision_mask = 0
	var segment_length: float = TAU * radius / wall_segments + 1.0
	for i: int in wall_segments:
		var angle: float = TAU * i / wall_segments
		var outward: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(segment_length, 80.0, 4.0)
		var shape: CollisionShape3D = CollisionShape3D.new()
		shape.shape = box
		shape.transform = Transform3D(Basis.looking_at(outward), outward * (radius + 2.0) + Vector3(0, 40, 0))
		_wall.add_child(shape)


func _build_debris() -> void:
	var tool: SurfaceTool = LowPolyMesh.begin()
	LowPolyMesh.add_box(tool, Vector3.ZERO, Vector3.ONE, Color.WHITE)
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = LowPolyMesh.commit(tool)
	multimesh.instance_count = debris_count
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	for i: int in debris_count:
		var angle: float = rng.randf() * TAU
		var distance: float = radius + rng.randf_range(-4.0, 12.0)
		var origin: Vector3 = Vector3(cos(angle) * distance, rng.randf_range(4.0, 110.0), sin(angle) * distance)
		var basis: Basis = Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU))
		# Planks, crates and the odd shed roof.
		var piece_size: Vector3 = Vector3(rng.randf_range(0.6, 3.5), rng.randf_range(0.2, 1.2), rng.randf_range(0.4, 2.0))
		multimesh.set_instance_transform(i, Transform3D(basis.scaled(piece_size), origin))
		multimesh.set_instance_color(i, DEBRIS_COLORS[rng.randi() % DEBRIS_COLORS.size()])
	_debris.multimesh = multimesh
