class_name RetroScreen
extends SubViewportContainer
## Shows the 3D world through the retro filter. The world renders in a small
## SubViewport that is scaled up to the window with nearest-neighbour
## filtering, with retro_post.gdshader on top. The HUD lives outside this node,
## so it stays sharp.

## Emitted when the internal render resolution changes.
signal render_size_changed(render_size: Vector2i)

## Render height for the "Midden" pixel size: 640x360 in a 16:9 window.
const MEDIUM_RENDER_HEIGHT: int = 360
## Render height for the "Laag" pixel size: 960x540 in a 16:9 window.
const LOW_RENDER_HEIGHT: int = 540

## Material with retro_post.gdshader; left off while the filter is disabled.
@export var retro_material: ShaderMaterial

@onready var world_viewport: SubViewport = $WorldViewport


func _ready() -> void:
	EventBus.settings_changed.connect(_apply_settings)
	get_viewport().size_changed.connect(_update_render_size)
	_apply_settings()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_retro_filter"):
		Settings.set_retro_filter_enabled(not Settings.retro_filter_enabled)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cycle_pixel_size"):
		Settings.cycle_pixel_size()
		get_viewport().set_input_as_handled()


## Replaces the world shown on screen with [param world].
func set_world(world: Node) -> void:
	for child: Node in world_viewport.get_children():
		child.queue_free()
	world_viewport.add_child(world)


## Resolution the 3D world currently renders at.
func get_render_size() -> Vector2i:
	return world_viewport.size


func _apply_settings() -> void:
	material = retro_material if Settings.retro_filter_enabled else null
	_update_render_size()


func _update_render_size() -> void:
	var canvas_size: Vector2 = get_viewport_rect().size
	var window_height: int = get_window().size.y
	if canvas_size.y <= 0.0 or window_height <= 0:
		return
	var render_height: int = window_height
	if Settings.retro_filter_enabled:
		if Settings.pixel_size == Settings.PixelSize.LOW:
			render_height = mini(LOW_RENDER_HEIGHT, window_height)
		elif Settings.pixel_size == Settings.PixelSize.MEDIUM:
			render_height = mini(MEDIUM_RENDER_HEIGHT, window_height)
	# Shrink this control to render_height and scale it back up to fill the
	# screen. With stretch on, the SubViewport follows the unscaled size.
	var pixel_scale: float = canvas_size.y / float(render_height)
	var new_size: Vector2 = (canvas_size / pixel_scale).round()
	scale = Vector2(pixel_scale, pixel_scale)
	if new_size != size:
		size = new_size
		render_size_changed.emit(get_render_size())
