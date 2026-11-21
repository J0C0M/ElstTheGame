extends SceneTree
## Renders a model scene from a few angles to PNG files, to check a model
## without opening the editor. Needs a window (not --headless).
## Run: godot --path . -s res://tools/models/preview_model.gd -- <scene> <out_prefix> [pose] [distance] [height]
## The pose is a property value set on the model ("pose=6"), when it has one.

var _model: Node3D
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var scene_path: String = args[0]
	var prefix: String = args[1]
	var setting: String = args[2] if args.size() > 2 else ""
	var distance: float = float(args[3]) if args.size() > 3 else 24.0
	var height: float = float(args[4]) if args.size() > 4 else 3.0
	root.size = Vector2i(960, 640)
	var world: Node3D = Node3D.new()
	root.add_child(world)
	var environment: WorldEnvironment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.32, 0.36, 0.42)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.55, 0.55, 0.6)
	world.add_child(environment)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation = Vector3(-0.9, 0.6, 0)
	world.add_child(sun)
	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(80, 80)
	floor_mesh.mesh = plane
	world.add_child(floor_mesh)
	_model = (load(scene_path) as PackedScene).instantiate() as Node3D
	world.add_child(_model)
	if setting.contains("="):
		var parts: PackedStringArray = setting.split("=")
		_model.set(parts[0], int(parts[1]))
	_camera = Camera3D.new()
	_camera.fov = 50.0
	world.add_child(_camera)
	_camera.current = true
	for i: int in 90:
		await process_frame
	var angles: Array[float] = [0.6, 2.2, -1.57, 3.14]
	for n: int in angles.size():
		var a: float = angles[n]
		_camera.global_position = Vector3(sin(a) * distance, height + distance * 0.25, cos(a) * distance)
		_camera.look_at(Vector3(0, height, 0))
		for i: int in 6:
			await process_frame
		var image: Image = root.get_texture().get_image()
		image.save_png("%s_%d.png" % [prefix, n])
	quit()
