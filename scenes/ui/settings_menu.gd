class_name SettingsMenu
extends Control
## Settings: retro filter, pixel size, fullscreen, mouse sensitivity and the
## volumes. Settings saves and applies every change straight away.

signal closed

@onready var _filter_check: CheckButton = %FilterCheck
@onready var _pixel_option: OptionButton = %PixelOption
@onready var _fullscreen_check: CheckButton = %FullscreenCheck
@onready var _sensitivity_slider: HSlider = %SensitivitySlider
@onready var _volume_sliders: Dictionary[StringName, HSlider] = {
	&"Master": %MasterSlider, &"Music": %MusicSlider, &"SFX": %SfxSlider,
}
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_pixel_option.clear()
	for size: int in Settings.PixelSize.values():
		_pixel_option.add_item(Settings.get_pixel_size_label(size), size)
	_filter_check.toggled.connect(Settings.set_retro_filter_enabled)
	_pixel_option.item_selected.connect(_on_pixel_size_selected)
	_fullscreen_check.toggled.connect(Settings.set_fullscreen)
	_sensitivity_slider.value_changed.connect(Settings.set_mouse_sensitivity)
	for bus: StringName in _volume_sliders:
		_volume_sliders[bus].value_changed.connect(_on_volume_changed.bind(bus))
	_back_button.pressed.connect(close)
	hide()


func open() -> void:
	_filter_check.set_pressed_no_signal(Settings.retro_filter_enabled)
	_pixel_option.select(_pixel_option.get_item_index(Settings.pixel_size))
	_fullscreen_check.set_pressed_no_signal(Settings.fullscreen)
	_sensitivity_slider.set_value_no_signal(Settings.mouse_sensitivity)
	for bus: StringName in _volume_sliders:
		_volume_sliders[bus].set_value_no_signal(Settings.get_volume(bus))
	show()
	_filter_check.grab_focus()


func close() -> void:
	hide()
	closed.emit()


func _on_pixel_size_selected(index: int) -> void:
	Settings.set_pixel_size(_pixel_option.get_item_id(index) as Settings.PixelSize)


func _on_volume_changed(value: float, bus: StringName) -> void:
	Settings.set_volume(bus, value)
