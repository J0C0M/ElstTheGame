extends SceneTree
## Renders the same little scene of Elst (Klaas, a player model, a driller, a
## cultist, houses, trees, a road and Amber behind them) in the four style
## proposals of Prototype 2, to compare them. Needs a window.
## Run: godot --path . -s res://tools/style_preview/render_styles.gd
## Writes docs/style_proposals/style_a.png .. style_d.png and a 2 x 2 sheet.
##
## A: clean low poly (flat colours, soft shadows, ambient occlusion, mist)
## B: real PS1 retro (low resolution, wobbling vertices, dithered patterns)
## C: toon / cel shaded (hard light bands, dark outlines, bright colours)
## D: hand-painted low poly (painted variation in colour, warm wrapped light)

const OUT: String = "res://docs/style_proposals/"
const SIZE: Vector2i = Vector2i(960, 540)

const PS1_SHADER: String = """
shader_type spatial;
render_mode vertex_lighting, specular_disabled;
uniform vec4 base_color : source_color = vec4(1.0);
uniform bool use_vcol = false;
uniform bool vcol_srgb = false;
uniform float snap = 90.0;
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	clip.xy = round(clip.xy / clip.w * snap) / snap * clip.w;
	POSITION = clip;
}
void fragment() {
	vec3 v = vcol_srgb ? pow(COLOR.rgb, vec3(2.2)) : COLOR.rgb;
	vec3 c = base_color.rgb * (use_vcol ? v : vec3(1.0));
	vec2 cell = floor(wpos.xz * 3.0 + wpos.y * 2.0);
	float n = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	c *= 0.82 + 0.28 * n;
	c = floor(c * 12.0 + 0.5) / 12.0;
	ALBEDO = c;
}
"""

const PAINT_SHADER: String = """
shader_type spatial;
render_mode diffuse_lambert_wrap, specular_disabled;
uniform vec4 base_color : source_color = vec4(1.0);
uniform bool use_vcol = false;
uniform bool vcol_srgb = false;
varying vec3 wpos;
varying vec3 lpos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; lpos = VERTEX; }
void fragment() {
	vec3 v = vcol_srgb ? pow(COLOR.rgb, vec3(2.2)) : COLOR.rgb;
	vec3 c = base_color.rgb * (use_vcol ? v : vec3(1.0));
	float strokes = noise(wpos.xz * 2.5 + wpos.y * 1.7) * 0.6 + noise(vec2(wpos.x + wpos.z, wpos.y) * 9.0) * 0.4;
	c *= mix(0.7, 1.22, strokes);
	c *= mix(0.78, 1.08, clamp(lpos.y * 0.6 + 0.5, 0.0, 1.0));
	c = mix(c, c * vec3(1.1, 1.0, 0.86), 0.45);
	ALBEDO = c;
	ROUGHNESS = 1.0;
}
"""

var _models: Array[Node3D] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = SIZE
	var images: Array[Image] = []
	for style: String in ["a", "b", "c", "d"]:
		var image: Image = await _render(style)
		image.save_png(OUT + "style_%s.png" % style)
		images.append(image)
	var sheet: Image = Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGB8)
	for n: int in 4:
		var small: Image = images[n].duplicate() as Image
		small.convert(Image.FORMAT_RGB8)
		small.resize(SIZE.x / 2, SIZE.y / 2, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(small, Rect2i(Vector2i.ZERO, small.get_size()), Vector2i((n % 2) * SIZE.x / 2, (n / 2) * SIZE.y / 2))
	sheet.save_png(OUT + "styles_sheet.png")
	print("wrote the style proposals")
	quit()


func _render(style: String) -> Image:
	var low: bool = style == "b"
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(320, 180) if low else SIZE
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_DISABLED if low else Viewport.MSAA_4X
	root.add_child(viewport)
	var world: Node3D = Node3D.new()
	viewport.add_child(world)
	_build_scene(world)
	_add_light_and_sky(world, style)
	var camera: Camera3D = Camera3D.new()
	camera.fov = 52.0
	world.add_child(camera)
	camera.position = Vector3(3.2, 2.1, 7.6)
	camera.look_at(Vector3(-1.2, 1.5, 0.5))
	camera.current = true
	for i: int in 40:
		await physics_frame
	_apply_style(world, style)
	for i: int in 8:
		await process_frame
	var image: Image = viewport.get_texture().get_image()
	if low:
		image.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_NEAREST)
	viewport.queue_free()
	return image


func _build_scene(world: Node3D) -> void:
	var ground: MeshInstance3D = _box(world, Vector3(0, -0.05, -10), Vector3(80, 0.1, 60), Color(0.46, 0.6, 0.32))
	ground.name = "Ground"
	_box(world, Vector3(0, 0.0, 1.0), Vector3(80, 0.04, 5), Color(0.45, 0.44, 0.42))
	_box(world, Vector3(0, 0.02, 1.0), Vector3(80, 0.02, 0.2), Color(0.9, 0.9, 0.85))
	var house_scene: PackedScene = load("res://scenes/world/props/House.tscn") as PackedScene
	for spec: Array in [[Vector3(-3, 0, -7), Vector3(8, 6, 7), Color(0.92, 0.6, 0.85), Color(0.6, 0.26, 0.42)],
			[Vector3(6, 0, -8), Vector3(7, 5, 6), Color(0.66, 0.5, 0.38), Color(0.3, 0.28, 0.3)],
			[Vector3(11, 0, -6), Vector3(6, 5, 6), Color(0.82, 0.76, 0.64), Color(0.58, 0.24, 0.17)]]:
		var house: Node3D = house_scene.instantiate() as Node3D
		house.set(&"size", spec[1])
		house.set(&"wall_color", spec[2])
		house.set(&"roof_color", spec[3])
		house.position = spec[0]
		world.add_child(house)
	var tree_scene: PackedScene = load("res://scenes/world/props/TreeProp.tscn") as PackedScene
	for spot: Vector3 in [Vector3(-2.5, 0, -4), Vector3(7, 0, -3.5), Vector3(-11, 0, -2)]:
		var tree: Node3D = tree_scene.instantiate() as Node3D
		tree.position = spot
		world.add_child(tree)
	_model(world, "res://scenes/npcs/KlaasModel.tscn", Vector3(-0.8, 0, 2.0), 0.4, &"flex")
	_model(world, "res://scenes/player/PlayerModel.tscn", Vector3(1.4, 0, 3.0), 0.9, &"")
	_model(world, "res://scenes/enemies/models/DrillerModel.tscn", Vector3(3.6, 0, 1.5), -0.6, &"enemy_windup")
	_model(world, "res://scenes/enemies/models/CultistModel.tscn", Vector3(-3.2, 0, 0.5), 0.6, &"")
	var amber: Node3D = (load("res://scenes/bosses/AmberModel.tscn") as PackedScene).instantiate() as Node3D
	amber.position = Vector3(-15, 0, -9)
	amber.rotation.y = -0.9
	amber.scale = Vector3.ONE * 0.75
	world.add_child(amber)
	amber.set(&"pose", 5)


func _model(world: Node3D, path: String, at: Vector3, yaw: float, action: StringName) -> void:
	var model: Node3D = (load(path) as PackedScene).instantiate() as Node3D
	model.position = at
	model.rotation.y = yaw
	world.add_child(model)
	if action != &"":
		model.call(&"play_action", action, 0.8, true)
	_models.append(model)


func _box(world: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material = material
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	world.add_child(instance)
	return instance


func _add_light_and_sky(world: Node3D, style: String) -> void:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation = Vector3(-0.75, 0.9, 0)
	sun.shadow_enabled = true
	var env: Environment = Environment.new()
	var sky: Sky = Sky.new()
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky.sky_material = sky_material
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	match style:
		"a":
			sun.light_energy = 1.3
			sun.light_angular_distance = 2.0
			env.ssao_enabled = true
			env.ssao_intensity = 2.5
			env.fog_enabled = true
			env.fog_mode = Environment.FOG_MODE_DEPTH
			env.fog_light_color = Color(0.75, 0.8, 0.88)
			env.fog_depth_begin = 15.0
			env.fog_depth_end = 70.0
			sky_material.sky_top_color = Color(0.36, 0.55, 0.8)
			sky_material.sky_horizon_color = Color(0.78, 0.84, 0.9)
		"b":
			sun.light_energy = 0.9
			sun.shadow_enabled = false
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0.32, 0.3, 0.36)
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = Color(0.45, 0.42, 0.5)
			env.fog_enabled = true
			env.fog_mode = Environment.FOG_MODE_DEPTH
			env.fog_light_color = Color(0.32, 0.3, 0.36)
			env.fog_depth_begin = 8.0
			env.fog_depth_end = 36.0
		"c":
			sun.light_energy = 1.15
			env.ambient_light_energy = 0.55
			env.adjustment_enabled = true
			env.adjustment_saturation = 1.3
			sky_material.sky_top_color = Color(0.2, 0.5, 0.95)
			sky_material.sky_horizon_color = Color(0.7, 0.88, 1.0)
		"d":
			sun.light_color = Color(1.0, 0.86, 0.68)
			sun.light_energy = 1.4
			sun.rotation = Vector3(-0.42, 1.2, 0)
			env.ambient_light_energy = 1.1
			env.glow_enabled = true
			env.glow_intensity = 0.4
			env.adjustment_enabled = true
			env.adjustment_saturation = 1.1
			sky_material.sky_top_color = Color(0.42, 0.55, 0.8)
			sky_material.sky_horizon_color = Color(1.0, 0.82, 0.62)
			sky_material.ground_horizon_color = Color(0.9, 0.72, 0.55)
	world.add_child(sun)
	var holder: WorldEnvironment = WorldEnvironment.new()
	holder.environment = env
	world.add_child(holder)


## Swaps every material for the one of the style, keeping its colour.
func _apply_style(world: Node3D, style: String) -> void:
	if style == "a":
		return
	var ps1: Shader = Shader.new()
	ps1.code = PS1_SHADER
	var paint: Shader = Shader.new()
	paint.code = PAINT_SHADER
	for node: Node in world.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		if instance.mesh == null:
			continue
		var source: Material = instance.material_override if instance.material_override != null else instance.get_active_material(0)
		var base: StandardMaterial3D = source as StandardMaterial3D
		var color: Color = base.albedo_color if base != null else Color.WHITE
		var vertex_colors: bool = base != null and base.vertex_color_use_as_albedo
		var srgb: bool = base != null and base.vertex_color_is_srgb
		var glowing: bool = base != null and (base.emission_enabled or base.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED)
		if glowing:
			continue
		match style:
			"b":
				var material: ShaderMaterial = ShaderMaterial.new()
				material.shader = ps1
				material.set_shader_parameter(&"base_color", color)
				material.set_shader_parameter(&"use_vcol", vertex_colors)
				material.set_shader_parameter(&"vcol_srgb", srgb)
				instance.material_override = material
			"c":
				var toon: StandardMaterial3D = StandardMaterial3D.new()
				toon.albedo_color = color
				toon.vertex_color_use_as_albedo = vertex_colors
				toon.vertex_color_is_srgb = srgb
				toon.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
				toon.specular_mode = BaseMaterial3D.SPECULAR_TOON
				toon.roughness = 0.6
				toon.cull_mode = base.cull_mode if base != null else BaseMaterial3D.CULL_BACK
				if instance.name != "Ground" and toon.cull_mode == BaseMaterial3D.CULL_BACK:
					var outline: StandardMaterial3D = StandardMaterial3D.new()
					outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					outline.albedo_color = Color(0.08, 0.05, 0.06)
					outline.cull_mode = BaseMaterial3D.CULL_FRONT
					outline.grow = true
					outline.grow_amount = 0.035
					toon.next_pass = outline
				instance.material_override = toon
			"d":
				var material: ShaderMaterial = ShaderMaterial.new()
				material.shader = paint
				material.set_shader_parameter(&"base_color", color)
				material.set_shader_parameter(&"use_vcol", vertex_colors)
				material.set_shader_parameter(&"vcol_srgb", srgb)
				instance.material_override = material
