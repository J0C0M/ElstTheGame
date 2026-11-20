class_name AmberBreath
extends Node3D
## Amber's fire breath, as seen: a warning on the floor and the flames.
## - The warning is a red fan on the floor that shows where the fire will
##   go. Pillars cast a shadow in it: behind a pillar the fan stops, and
##   there the player is safe. It pulses faster as the breath comes.
## - The flames are blobs of fire that pour from her mouth, grow and cool
##   from yellow to dark red, and splash against a pillar or wall.
## Amber calls show_warning() and pour() every physics frame; the damage is
## hers (amber.gd), with the same shape and the same pillar check.

## Rays across the fan; more gives sharper pillar shadows.
const RAYS: int = 24
const FLAME_COUNT: int = 40
const FLAME_SPEED: float = 20.0
const FLAMES_PER_SECOND: float = 46.0
const FLAME_LIFE: float = 0.85
## Height above the floor at which the fire hurts (the player's chest).
const CHEST: float = 1.2
## Width of the bright edge of the warning, in metres.
const RIM: float = 0.6

var _fan: ImmediateMesh
var _fan_material: StandardMaterial3D
var _flame_mesh: BoxMesh
var _flame_materials: Array[StandardMaterial3D] = []
var _flames: Array[MeshInstance3D] = []
var _velocity: Array[Vector3] = []
var _age: Array[float] = []
var _travel: Array[float] = []
var _reach: Array[float] = []
var _spawn_debt: float = 0.0
var _warning_time: float = 0.0
var _poured: bool = false

@onready var _fan_instance: MeshInstance3D = $Fan
@onready var _light: OmniLight3D = $Light


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_fan = ImmediateMesh.new()
	_fan_instance.mesh = _fan
	_fan_instance.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_fan_material = StandardMaterial3D.new()
	_fan_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fan_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fan_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_fan_material.no_depth_test = false
	_fan_material.vertex_color_use_as_albedo = true
	_fan_instance.material_override = _fan_material
	_fan_instance.visible = false
	_flame_mesh = BoxMesh.new()
	for color: Color in [Color(1.0, 0.95, 0.55), Color(1.0, 0.68, 0.15), Color(0.95, 0.38, 0.08), Color(0.55, 0.14, 0.05)]:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = color
		_flame_materials.append(material)
	for i: int in FLAME_COUNT:
		var flame: MeshInstance3D = MeshInstance3D.new()
		flame.mesh = _flame_mesh
		flame.visible = false
		flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(flame)
		_flames.append(flame)
		_velocity.append(Vector3.ZERO)
		_age.append(INF)
		_travel.append(0.0)
		_reach.append(0.0)
	_light.visible = false


## Shows the warning on the floor for a breath from [param mouth] towards
## [param forward], [param half_angle] degrees to either side, out to
## [param distance] metres, on a floor at [param floor_y]. [param urgency]
## from 0 to 1 makes it pulse faster and brighter.
func show_warning(mouth: Vector3, forward: Vector3, half_angle: float, distance: float, floor_y: float, urgency: float, exclude: Array[RID]) -> void:
	_warning_time += get_physics_process_delta_time() * lerpf(4.0, 14.0, urgency)
	var alpha: float = lerpf(0.45, 0.75, urgency) + sin(_warning_time) * 0.15
	_draw_fan(mouth, forward, half_angle, distance, floor_y, Color(1.0, 0.1, 0.04, alpha), exclude)


## Hides the warning.
func hide_warning() -> void:
	_fan_instance.visible = false
	_warning_time = 0.0


## Pours flames for one physics frame from [param mouth] towards
## [param forward], spread over [param half_angle] degrees.
func pour(mouth: Vector3, forward: Vector3, half_angle: float, distance: float, floor_y: float, delta: float, exclude: Array[RID]) -> void:
	_poured = true
	_light.visible = true
	_light.global_position = mouth + forward * 3.0
	_light.light_energy = 4.0 + randf() * 2.0
	_spawn_debt += FLAMES_PER_SECOND * delta
	while _spawn_debt >= 1.0:
		_spawn_debt -= 1.0
		var angle: float = deg_to_rad(randf_range(-half_angle, half_angle) * 0.85)
		var side: Vector3 = forward.rotated(Vector3.UP, angle)
		var target: Vector3 = Vector3(mouth.x, floor_y + CHEST * randf_range(0.4, 1.4), mouth.z) + side * distance
		_spawn(mouth, target, exclude)


## How far fire from [param mouth] gets towards [param target] before a
## pillar or wall stops it, in metres along the way.
func reach(mouth: Vector3, target: Vector3, exclude: Array[RID]) -> float:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(mouth, target, PhysicsLayers.WORLD, exclude)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return mouth.distance_to(target)
	return mouth.distance_to(hit["position"] as Vector3)


## Number of flames now in the air, for tests.
func flames_alive() -> int:
	var count: int = 0
	for flame: MeshInstance3D in _flames:
		count += 1 if flame.visible else 0
	return count


func _physics_process(delta: float) -> void:
	if not _poured:
		_light.visible = false
	_poured = false
	for i: int in _flames.size():
		if _age[i] >= FLAME_LIFE:
			continue
		var flame: MeshInstance3D = _flames[i]
		_age[i] += delta
		var t: float = _age[i] / FLAME_LIFE
		if _travel[i] < _reach[i]:
			var step: float = _velocity[i].length() * delta
			flame.global_position += _velocity[i] * delta
			_travel[i] += step
		else:
			# Splashed against a pillar: it spreads out and dies quicker.
			_age[i] += delta
		var size: float = lerpf(0.5, 2.4, minf(t * 1.4, 1.0))
		flame.scale = Vector3.ONE * size
		flame.rotation += Vector3(3.0, 2.0, 4.0) * delta
		flame.material_override = _flame_materials[mini(int(t * 4.0), 3)]
		if _age[i] >= FLAME_LIFE:
			flame.visible = false


func _spawn(mouth: Vector3, target: Vector3, exclude: Array[RID]) -> void:
	for i: int in _flames.size():
		if _age[i] < FLAME_LIFE:
			continue
		var flame: MeshInstance3D = _flames[i]
		_age[i] = 0.0
		_travel[i] = 0.0
		_reach[i] = maxf(reach(mouth, target, exclude) - 0.6, 0.5)
		_velocity[i] = (target - mouth).normalized() * FLAME_SPEED * randf_range(0.85, 1.15)
		flame.global_position = mouth
		flame.rotation = Vector3(randf(), randf(), randf()) * TAU
		flame.scale = Vector3.ONE * 0.5
		flame.visible = true
		flame.reset_physics_interpolation()
		return


func _draw_fan(mouth: Vector3, forward: Vector3, half_angle: float, distance: float, floor_y: float, color: Color, exclude: Array[RID]) -> void:
	_fan_instance.visible = true
	_fan.clear_surfaces()
	_fan.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var ground: Vector3 = Vector3(mouth.x, floor_y + 0.06, mouth.z)
	var flat: float = Vector2(distance, mouth.y - floor_y - CHEST).length()
	var previous: Vector3 = Vector3.INF
	var previous_inner: Vector3 = Vector3.INF
	for n: int in RAYS + 1:
		var angle: float = deg_to_rad(lerpf(-half_angle, half_angle, float(n) / RAYS))
		var direction: Vector3 = forward.rotated(Vector3.UP, angle)
		var target: Vector3 = Vector3(mouth.x, floor_y + CHEST, mouth.z) + direction * distance
		# The reach along the slanted ray, back to metres on the floor.
		var along: float = reach(mouth, target, exclude) / flat * distance
		var point: Vector3 = ground + direction * along
		var inner: Vector3 = ground + direction * maxf(along - RIM, 0.0)
		if previous != Vector3.INF:
			for vertex: Vector3 in [ground, previous_inner, inner]:
				_fan.surface_set_color(color)
				_fan.surface_add_vertex(vertex)
			var rim: Color = Color(1.0, 0.45, 0.1, minf(color.a + 0.25, 1.0))
			for vertex: Vector3 in [previous_inner, previous, point, previous_inner, point, inner]:
				_fan.surface_set_color(rim)
				_fan.surface_add_vertex(vertex)
		previous = point
		previous_inner = inner
	_fan.surface_end()
