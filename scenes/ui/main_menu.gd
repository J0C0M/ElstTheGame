class_name MainMenu
extends Control
## Title screen with Doorgaan, Nieuw spel, Laden, Instellingen and Afsluiten.
## Main handles the buttons. Doorgaan and Laden need at least one save.

signal continue_pressed
signal new_game_pressed
signal load_pressed
signal settings_pressed
signal quit_pressed

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _load_button: Button = %LoadButton


func _ready() -> void:
	_continue_button.pressed.connect(continue_pressed.emit)
	_new_game_button.pressed.connect(new_game_pressed.emit)
	_load_button.pressed.connect(load_pressed.emit)
	(%SettingsButton as Button).pressed.connect(settings_pressed.emit)
	(%QuitButton as Button).pressed.connect(quit_pressed.emit)
	hide()


func open() -> void:
	var has_saves: bool = SaveManager.has_saves()
	_continue_button.disabled = not has_saves
	_load_button.disabled = not has_saves
	show()
	(_continue_button if has_saves else _new_game_button).grab_focus()
