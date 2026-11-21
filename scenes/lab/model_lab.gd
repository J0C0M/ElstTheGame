extends Control
## The model lab of Prototype 2 (P2-1): Klaas, Gyan, a driller and a house in
## the four model proposals M1 to M4, side by side in the retro filter of the
## game, with the light and fog of Elst. A developer tool, not part of the
## game.
##
## Keys: 1-4 one proposal, 0 all of them, C close to the figures or wide,
## R turn the figures, drag with the left mouse button to orbit, wheel to zoom,
## F1/F2 the filter as in the game.
## With [code]-- --render <dir>[/code] it saves a screenshot of every view and quits.

const GROUP_SPACING: float = 13.0
const FIGURE_SPACING: float = 1.35

var _figures: Array[Node3D] = []
var _focus: int = -1
var _close: bool = false
var _turn: bool = false
var _yaw: float = 0.0
var _pitch: float = -0.12
var _distance: float = 0.0
var _target: Vector3 = Vector3.ZERO
var _camera: Camera3D

@onready var _retro: RetroScreen = $RetroScreen
@onready var _title: Label = $Title
@onready var _help: Label = $Help


func _ready() -> void:
	var world: Node3D = _build_world()
	_retro.set_world(world)
	_set_view(-1, false)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = args.find("--render")
	if index != -1 and index + 1 < args.size():
		_render_all(args[index + 1])


func _build_world() -> Node3D:
	var world: Node3D = Node3D.new()
	world.name = "LabWorld"
	# Light and atmosphere as in Elst.tscn.
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.34, 0.44, 0.6)
	sky_material.sky_horizon_color = Color(0.74, 0.65, 0.55)
	sky_material.ground_bottom_color = Color(0.3, 0.28, 0.25)
	sky_material.ground_horizon_color = Color(0.74, 0.65, 0.55)
	var sky: Sky = Sky.new()
	sky.sky_material = sky_material
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.85
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.68, 0.6, 0.52)
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_density = 1.0
	environment.fog_sky_affect = 0.85
	environment.fog_depth_curve = 1.6
	environment.fog_depth_begin = 50.0
	environment.fog_depth_end = 235.0
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.environment = environment
	world.add_child(world_environment)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation = Vector3(-0.87, -0.7, 0)
	sun.light_color = Color(1, 0.9, 0.76)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 140.0
	world.add_child(sun)
	# Grass, a pavement in front of the houses and a street.
	var ground: MeshKit = MeshKit.new(true)
	ground.box(Vector3(0, -0.05, 0), Vector3(120, 0.1, 80), Color(0.42, 0.55, 0.3))
	ground.box(Vector3(0, 0.01, 2.0), Vector3(120, 0.04, 6.0), Color(0.6, 0.58, 0.55))
	ground.box(Vector3(0, 0.0, 8.5), Vector3(120, 0.04, 7.0), Color(0.33, 0.33, 0.35))
	var ground_mesh: MeshInstance3D = MeshInstance3D.new()
	ground_mesh.mesh = ground.commit()
	world.add_child(ground_mesh)
	for style: int in 4:
		var group_x: float = (style - 1.5) * GROUP_SPACING
		var house: MeshInstance3D = LabHouse.build(style as LabFigure.Style)
		house.position = Vector3(group_x, 0, -4.5)
		world.add_child(house)
		for n: int in LabFigure.CHARACTERS.size():
			var holder: Node3D = Node3D.new()
			holder.position = Vector3(group_x + (n - 1) * FIGURE_SPACING, 0, 2.2)
			holder.add_child(LabFigure.build(LabFigure.CHARACTERS[n], style as LabFigure.Style))
			world.add_child(holder)
			_figures.append(holder)
	_camera = Camera3D.new()
	_camera.fov = 60.0
	world.add_child(_camera)
	return world


func _process(delta: float) -> void:
	if _turn:
		for figure: Node3D in _figures:
			figure.rotate_y(delta * 0.8)
	var offset: Vector3 = Basis.from_euler(Vector3(_pitch, _yaw, 0)) * Vector3(0, 0, _distance)
	_camera.global_position = _target + offset
	_camera.look_at(_target)


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo:
		match key.physical_keycode:
			KEY_0:
				_set_view(-1, _close)
			KEY_1, KEY_2, KEY_3, KEY_4:
				_set_view(key.physical_keycode - KEY_1, _close)
			KEY_C:
				_set_view(_focus, not _close)
			KEY_R:
				_turn = not _turn
				if not _turn:
					for figure: Node3D in _figures:
						figure.rotation = Vector3.ZERO
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_yaw -= motion.screen_relative.x * 0.006
		_pitch = clampf(_pitch - motion.screen_relative.y * 0.006, -1.2, 0.3)
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.pressed:
		if button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = maxf(_distance * 0.9, 1.0)
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = minf(_distance * 1.1, 120.0)


## Points the camera at proposal [param focus] (-1 for all of them), close to
## the figures when [param close].
func _set_view(focus: int, close: bool) -> void:
	_focus = focus
	_close = close
	_yaw = 0.0
	_pitch = -0.12
	var x: float = 0.0 if focus == -1 else (focus - 1.5) * GROUP_SPACING
	if focus == -1:
		_target = Vector3(0, 2.5, -1.0)
		_distance = 34.0 if not close else 30.0
		_pitch = -0.2
	elif close:
		_target = Vector3(x, 1.15, 2.2)
		_distance = 4.6
		_pitch = -0.05
	else:
		_target = Vector3(x, 3.2, -1.5)
		_distance = 14.5
		_pitch = -0.14
	_title.text = "Alle voorstellen" if focus == -1 else LabFigure.STYLE_NAMES[focus]
	_help.text = "1-4 voorstel   0 alles   C dichtbij/ver   R draaien   muis slepen: rondkijken   F1 filter   F2 pixelgrootte"


func _render_all(directory: String) -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	_help.visible = false
	var views: Array = [[-1, false, "alles"]]
	for style: int in 4:
		views.append([style, false, "M%d_huis" % (style + 1)])
		views.append([style, true, "M%d_figuren" % (style + 1)])
	for view: Array in views:
		_set_view(view[0], view[1])
		for frame: int in 8:
			await get_tree().process_frame
		var image: Image = get_viewport().get_texture().get_image()
		image.save_png(directory.path_join("lab_%s.png" % view[2]))
	# Close-ups of the faces, from the front and from the side.
	_title.visible = false
	for style: int in 4:
		for n: int in 3:
			var figure: Node3D = _figures[style * 3 + n]
			_target = figure.position + Vector3(0, 1.62 if style != 2 else 1.55, 0)
			_distance = 1.5
			_pitch = -0.02
			for yaw: float in [0.0, 0.7]:
				_yaw = yaw
				for frame: int in 4:
					await get_tree().process_frame
				get_viewport().get_texture().get_image().save_png(directory.path_join("face_M%d_%s_%d.png" % [style + 1,
					LabFigure.CHARACTERS[n], int(yaw * 10)]))
	get_tree().quit()
