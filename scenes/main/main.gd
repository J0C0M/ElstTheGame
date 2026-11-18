extends Node
## Root scene. Holds the retro screen (with the 3D world inside) and the HUD.
## Scene changes and transitions follow in Phase 2.

## World that is loaded into the retro screen at startup.
@export var start_scene: PackedScene

@onready var _retro_screen: RetroScreen = $RetroScreen
@onready var _filter_info: Label = $HUD/FilterInfo


func _ready() -> void:
	EventBus.settings_changed.connect(_update_filter_info)
	_retro_screen.render_size_changed.connect(_on_render_size_changed)
	if start_scene != null:
		_retro_screen.set_world(start_scene.instantiate())
	_update_filter_info()


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
