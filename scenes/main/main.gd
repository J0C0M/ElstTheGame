extends Node
## Root scene. Holds the retro screen (with the 3D world inside) and the HUD,
## switches between worlds behind a fade, and catches the mouse for the camera.

const FADE_TIME: float = 0.35

## World that is loaded into the retro screen at startup.
@export var start_scene: PackedScene
## Spawn point to start at. Empty means the world's default spawn.
@export var start_spawn: StringName = &""

## True while the mouse waits for the window to get focus at startup.
var _capture_on_focus: bool = false
var _world: GameWorld
var _changing_world: bool = false

@onready var _retro_screen: RetroScreen = $RetroScreen
@onready var _filter_info: Label = $UI/FilterInfo
@onready var _fade: ColorRect = $UI/Fade


func _ready() -> void:
	EventBus.settings_changed.connect(_update_filter_info)
	_retro_screen.render_size_changed.connect(_on_render_size_changed)
	EventBus.world_change_requested.connect(change_world)
	if start_scene != null:
		_show_world(start_scene.instantiate() as GameWorld, start_spawn, {})
	_update_filter_info()
	# Catching the mouse fails while the window has no focus yet, so wait for it.
	if get_window().has_focus():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		_capture_on_focus = true


## Switches to the world in [param scene_path] behind a fade and puts the
## player at the spawn point [param spawn_id]. Health and stamina carry over.
func change_world(scene_path: String, spawn_id: StringName) -> void:
	if _changing_world:
		return
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		push_error("Cannot change world: %s does not load." % scene_path)
		return
	_changing_world = true
	var player: Player = _world.get_player() if _world != null else null
	var carried: Dictionary = player.save_data() if player != null else {}
	await _fade_to(1.0)
	_show_world(scene.instantiate() as GameWorld, spawn_id, carried)
	await _fade_to(0.0)
	_changing_world = false


func get_world() -> GameWorld:
	return _world


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		# Until the pause menu exists (Phase 3), Esc only frees the mouse.
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and event is InputEventMouseButton and event.is_pressed():
		# A click on the game catches the mouse again; it does not attack.
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and _capture_on_focus:
		_capture_on_focus = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _show_world(world: GameWorld, spawn_id: StringName, carried: Dictionary) -> void:
	_retro_screen.set_world(world)
	_world = world
	world.place_player(spawn_id)
	var player: Player = world.get_player()
	if player != null and not carried.is_empty():
		player.load_data(carried)
	EventBus.location_entered.emit(world.location_name)


func _fade_to(alpha: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await tween.finished


func _on_render_size_changed(_render_size: Vector2i) -> void:
	_update_filter_info()


func _update_filter_info() -> void:
	var render_size: Vector2i = _retro_screen.get_render_size()
	var resolution: String = "%d×%d" % [render_size.x, render_size.y]
	if Settings.retro_filter_enabled:
		_filter_info.text = "Retrofilter: aan  [F1]\nPixelgrootte: %s, %s  [F2]" % [
			Settings.get_pixel_size_label(Settings.pixel_size), resolution]
	else:
		_filter_info.text = "Retrofilter: uit  [F1]\nVolle resolutie, %s" % resolution
