extends Node
## Player settings that are not part of a save game: graphics, controls and
## audio, stored in user://settings.cfg. The setters save and apply a change
## straight away; the settings menu uses them.

enum PixelSize { LOW, MEDIUM, OFF }

const SETTINGS_PATH: String = "user://settings.cfg"
const GRAPHICS_SECTION: String = "graphics"
const CONTROLS_SECTION: String = "controls"
const AUDIO_SECTION: String = "audio"
## Audio buses (see default_bus_layout.tres) that have a volume setting.
const VOLUME_BUSES: Array[StringName] = [&"Master", &"Music", &"SFX"]

var retro_filter_enabled: bool = true
var pixel_size: PixelSize = PixelSize.MEDIUM
var fullscreen: bool = false
## Camera turn in degrees per pixel of mouse movement.
var mouse_sensitivity: float = 0.15
## Volume per bus, from 0.0 (silent) to 1.0.
var volumes: Dictionary[StringName, float] = {&"Master": 1.0, &"Music": 0.8, &"SFX": 0.9}


func _ready() -> void:
	_load()
	_apply()


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


func set_fullscreen(enabled: bool) -> void:
	if enabled == fullscreen:
		return
	fullscreen = enabled
	_save_and_notify()


func set_mouse_sensitivity(degrees_per_pixel: float) -> void:
	if is_equal_approx(degrees_per_pixel, mouse_sensitivity):
		return
	mouse_sensitivity = degrees_per_pixel
	_save_and_notify()


func set_volume(bus: StringName, volume: float) -> void:
	volume = clampf(volume, 0.0, 1.0)
	if is_equal_approx(volume, get_volume(bus)):
		return
	volumes[bus] = volume
	_save_and_notify()


func get_volume(bus: StringName) -> float:
	return volumes.get(bus, 1.0)


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


func _apply() -> void:
	for bus: StringName in VOLUME_BUSES:
		var index: int = AudioServer.get_bus_index(bus)
		if index < 0:
			continue
		var volume: float = get_volume(bus)
		AudioServer.set_bus_mute(index, volume <= 0.0)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
	var mode: DisplayServer.WindowMode = (DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED)
	if DisplayServer.window_get_mode() != mode and (fullscreen or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN):
		DisplayServer.window_set_mode(mode)


func _load() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	retro_filter_enabled = bool(config.get_value(GRAPHICS_SECTION, "retro_filter_enabled", retro_filter_enabled))
	var size_name: String = str(config.get_value(GRAPHICS_SECTION, "pixel_size", ""))
	if PixelSize.has(size_name):
		pixel_size = PixelSize[size_name]
	fullscreen = bool(config.get_value(GRAPHICS_SECTION, "fullscreen", fullscreen))
	mouse_sensitivity = float(config.get_value(CONTROLS_SECTION, "mouse_sensitivity", mouse_sensitivity))
	for bus: StringName in VOLUME_BUSES:
		volumes[bus] = clampf(float(config.get_value(AUDIO_SECTION, String(bus).to_lower(), get_volume(bus))), 0.0, 1.0)


func _save_and_notify() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(GRAPHICS_SECTION, "retro_filter_enabled", retro_filter_enabled)
	config.set_value(GRAPHICS_SECTION, "pixel_size", PixelSize.find_key(pixel_size))
	config.set_value(GRAPHICS_SECTION, "fullscreen", fullscreen)
	config.set_value(CONTROLS_SECTION, "mouse_sensitivity", mouse_sensitivity)
	for bus: StringName in VOLUME_BUSES:
		config.set_value(AUDIO_SECTION, String(bus).to_lower(), get_volume(bus))
	var error: Error = config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save settings to %s (error %d)." % [SETTINGS_PATH, error])
	_apply()
	EventBus.settings_changed.emit()
