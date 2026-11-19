extends Node
## Player settings that are not part of a save game, stored in
## user://settings.cfg. The settings menu (Phase 3) builds on this.

enum PixelSize { LOW, MEDIUM, OFF }

const SETTINGS_PATH: String = "user://settings.cfg"
const GRAPHICS_SECTION: String = "graphics"
const CONTROLS_SECTION: String = "controls"

var retro_filter_enabled: bool = true
var pixel_size: PixelSize = PixelSize.MEDIUM
## Camera turn in degrees per pixel of mouse movement.
var mouse_sensitivity: float = 0.15


func _ready() -> void:
	_load()


func set_retro_filter_enabled(enabled: bool) -> void:
	if enabled == retro_filter_enabled:
		return
	retro_filter_enabled = enabled
	_save_and_notify()


func set_pixel_size(new_size: PixelSize) -> void:
	if new_size == pixel_size:
		return
	pixel_size = new_size
	_save_and_notify()


func set_mouse_sensitivity(degrees_per_pixel: float) -> void:
	if is_equal_approx(degrees_per_pixel, mouse_sensitivity):
		return
	mouse_sensitivity = degrees_per_pixel
	_save_and_notify()


## Steps to the next pixel size: low, medium, off and back to low.
func cycle_pixel_size() -> void:
	set_pixel_size(((pixel_size + 1) % PixelSize.size()) as PixelSize)


## Dutch name of a pixel size, for menus and the HUD.
func get_pixel_size_label(size: PixelSize) -> String:
	match size:
		PixelSize.LOW:
			return "Laag"
		PixelSize.MEDIUM:
			return "Midden"
		_:
			return "Uit"


func _load() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	retro_filter_enabled = bool(config.get_value(GRAPHICS_SECTION, "retro_filter_enabled", retro_filter_enabled))
	var size_name: String = str(config.get_value(GRAPHICS_SECTION, "pixel_size", ""))
	if PixelSize.has(size_name):
		pixel_size = PixelSize[size_name]
	mouse_sensitivity = float(config.get_value(CONTROLS_SECTION, "mouse_sensitivity", mouse_sensitivity))


func _save_and_notify() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(GRAPHICS_SECTION, "retro_filter_enabled", retro_filter_enabled)
	config.set_value(GRAPHICS_SECTION, "pixel_size", PixelSize.find_key(pixel_size))
	config.set_value(CONTROLS_SECTION, "mouse_sensitivity", mouse_sensitivity)
	var error: Error = config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save settings to %s (error %d)." % [SETTINGS_PATH, error])
	EventBus.settings_changed.emit()
