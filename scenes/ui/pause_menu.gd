class_name PauseMenu
extends Control
## Pause menu. Main pauses the game while it is open and handles the buttons.

signal resume_pressed
signal save_pressed
signal load_pressed
signal settings_pressed
signal main_menu_pressed
signal quit_pressed

@onready var _resume_button: Button = %ResumeButton
@onready var _save_button: Button = %SaveButton


func _ready() -> void:
	_resume_button.pressed.connect(resume_pressed.emit)
	_save_button.pressed.connect(save_pressed.emit)
	(%LoadButton as Button).pressed.connect(load_pressed.emit)
	(%SettingsButton as Button).pressed.connect(settings_pressed.emit)
	(%MainMenuButton as Button).pressed.connect(main_menu_pressed.emit)
	(%QuitButton as Button).pressed.connect(quit_pressed.emit)
	hide()


func open() -> void:
	_save_button.disabled = not SaveManager.can_save()
	_save_button.tooltip_text = "" if SaveManager.can_save() else "Je kunt nu niet opslaan."
	show()
	_resume_button.grab_focus()
