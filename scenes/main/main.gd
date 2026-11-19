extends Node
## Root scene. Holds the retro screen (with the 3D world inside) and the HUD,
## and catches the mouse for the camera. Scene changes and transitions follow
## in Phase 2.

## World that is loaded into the retro screen at startup.
@export var start_scene: PackedScene

## True while the mouse waits for the window to get focus at startup.
var _capture_on_focus: bool = false

@onready var _retro_screen: RetroScreen = $RetroScreen
@onready var _filter_info: Label = $UI/FilterInfo


func _ready() -> void:
	EventBus.settings_changed.connect(_update_filter_info)
	_retro_screen.render_size_changed.connect(_on_render_size_changed)
	if start_scene != null:
		_retro_screen.set_world(start_scene.instantiate())
	_update_filter_info()
	# Catching the mouse fails while the window has no focus yet, so wait for it.
	if get_window().has_focus():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		_capture_on_focus = true


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
