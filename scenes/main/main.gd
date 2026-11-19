extends Node
## Root scene. Holds the retro screen (with the 3D world inside), the HUD and
## the menus. Runs the main menu, the pause menu, world changes behind a fade,
## new games, loading saves and what happens after dying, and catches the
## mouse for the camera while playing.

enum AppState { MAIN_MENU, PLAYING }

const FADE_TIME: float = 0.35
## Seconds the death message stays up before the last save loads.
const DEATH_DELAY: float = 3.0

## World and spawn point of a new game.
@export var new_game_scene: PackedScene
@export var new_game_spawn: StringName = &"Start"
## Shown behind the main menu.
@export var menu_backdrop: PackedScene
## Skips the main menu and starts a new game straight away (for tests).
@export var skip_main_menu: bool = false

var _app_state: AppState = AppState.MAIN_MENU
var _world: GameWorld
var _changing_world: bool = false
## True while the mouse waits for the window to get focus.
var _capture_on_focus: bool = false
## Menu to show again when the settings or save menu closes.
var _menu_below: Control

@onready var _retro_screen: RetroScreen = $RetroScreen
@onready var _hud: Control = $UI/HUD
@onready var _controls_help: Label = $UI/ControlsHelp
@onready var _main_menu: MainMenu = $UI/Menus/MainMenu
@onready var _pause_menu: PauseMenu = $UI/Menus/PauseMenu
@onready var _save_load_menu: SaveLoadMenu = $UI/Menus/SaveLoadMenu
@onready var _settings_menu: SettingsMenu = $UI/Menus/SettingsMenu
@onready var _fade: ColorRect = $UI/Fade


func _ready() -> void:
	EventBus.world_change_requested.connect(change_world)
	EventBus.save_load_requested.connect(_on_save_load_requested)
	EventBus.player_died.connect(_on_player_died)
	_main_menu.continue_pressed.connect(func() -> void: SaveManager.load_save(SaveManager.get_latest_save_id()))
	_main_menu.new_game_pressed.connect(start_new_game)
	_main_menu.load_pressed.connect(_open_submenu.bind(_main_menu, _save_load_menu.open.bind(SaveLoadMenu.Mode.LOAD)))
	_main_menu.settings_pressed.connect(_open_submenu.bind(_main_menu, _settings_menu.open))
	_main_menu.quit_pressed.connect(get_tree().quit)
	_pause_menu.resume_pressed.connect(resume)
	_pause_menu.save_pressed.connect(_open_submenu.bind(_pause_menu, _save_load_menu.open.bind(SaveLoadMenu.Mode.SAVE)))
	_pause_menu.load_pressed.connect(_open_submenu.bind(_pause_menu, _save_load_menu.open.bind(SaveLoadMenu.Mode.LOAD)))
	_pause_menu.settings_pressed.connect(_open_submenu.bind(_pause_menu, _settings_menu.open))
	_pause_menu.main_menu_pressed.connect(return_to_main_menu)
	_pause_menu.quit_pressed.connect(get_tree().quit)
	_save_load_menu.closed.connect(_on_submenu_closed)
	_settings_menu.closed.connect(_on_submenu_closed)
	if skip_main_menu:
		start_new_game()
	else:
		_show_main_menu()


func _process(delta: float) -> void:
	if _app_state == AppState.PLAYING and not get_tree().paused and not _changing_world:
		GameState.play_time += delta


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		_on_escape()
	elif _wants_captured_mouse() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED \
			and event is InputEventMouseButton and event.is_pressed():
		# A click on the game catches the mouse again; it does not attack.
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _app_state != AppState.PLAYING or get_tree().paused or _changing_world:
		return
	if event.is_action_pressed(&"quicksave"):
		get_viewport().set_input_as_handled()
		SaveManager.quicksave()
	elif event.is_action_pressed(&"quickload"):
		get_viewport().set_input_as_handled()
		SaveManager.quickload()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and _capture_on_focus:
		_capture_on_focus = false
		_update_mouse()


func get_world() -> GameWorld:
	return _world


func start_new_game() -> void:
	if _changing_world:
		return
	GameState.reset()
	QuestManager.reset()
	await _enter_world(new_game_scene.instantiate() as GameWorld, new_game_spawn, {}, {})


## Switches to the world in [param scene_path] behind a fade and puts the
## player at the spawn point [param spawn_id]. Health and stamina carry over.
func change_world(scene_path: String, spawn_id: StringName) -> void:
	if _changing_world or _app_state != AppState.PLAYING:
		return
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		push_error("Cannot change world: %s does not load." % scene_path)
		return
	var player: Player = _world.get_player()
	var vitals: Dictionary = player.get_vitals() if player != null else {}
	await _enter_world(scene.instantiate() as GameWorld, spawn_id, vitals, {})


func pause() -> void:
	get_tree().paused = true
	_pause_menu.open()
	_update_mouse()


func resume() -> void:
	_close_menus()
	get_tree().paused = false
	_update_mouse()


func return_to_main_menu() -> void:
	if _changing_world:
		return
	_changing_world = true
	await _fade_to(1.0)
	_show_main_menu()
	await _fade_to(0.0)
	_changing_world = false


func _enter_world(world: GameWorld, spawn_id: StringName, vitals: Dictionary, save: Dictionary) -> void:
	_changing_world = true
	GameState.block_saving(&"world_change")
	await _fade_to(1.0)
	_close_menus()
	get_tree().paused = false
	if not save.is_empty():
		SaveManager.restore_globals(save)
	# Main decides what happens after dying, not the world itself.
	world.respawn_on_death = false
	_retro_screen.set_world(world)
	_world = world
	SaveManager.world = world
	world.place_player(spawn_id)
	var player: Player = world.get_player()
	if player != null and not vitals.is_empty():
		player.set_vitals(vitals)
	if not save.is_empty():
		SaveManager.restore_world(world, save)
	_app_state = AppState.PLAYING
	_hud.show()
	_controls_help.show()
	_update_mouse()
	EventBus.location_entered.emit(world.location_name)
	await _fade_to(0.0)
	GameState.unblock_saving(&"world_change")
	_changing_world = false
	if world.autosave_on_enter and save.is_empty():
		SaveManager.autosave()


func _show_main_menu() -> void:
	_app_state = AppState.MAIN_MENU
	get_tree().paused = false
	_close_menus()
	_world = null
	SaveManager.world = null
	_retro_screen.set_world(menu_backdrop.instantiate())
	_hud.hide()
	_controls_help.hide()
	_main_menu.open()
	_update_mouse()


func _on_escape() -> void:
	if _changing_world:
		return
	if _settings_menu.visible:
		_settings_menu.close()
	elif _save_load_menu.visible:
		_save_load_menu.close()
	elif _pause_menu.visible:
		resume()
	elif _app_state == AppState.PLAYING:
		pause()


func _open_submenu(below: Control, open_menu: Callable) -> void:
	below.hide()
	_menu_below = below
	open_menu.call()


func _on_submenu_closed() -> void:
	if _menu_below != null:
		_menu_below.call("open")


func _close_menus() -> void:
	for menu: Control in [_main_menu, _pause_menu, _save_load_menu, _settings_menu]:
		menu.hide()


func _on_save_load_requested(data: Dictionary) -> void:
	if _changing_world:
		return
	var scene: PackedScene = load(str(data.get("scene", ""))) as PackedScene
	if scene == null:
		EventBus.message_requested.emit("De wereld van deze save bestaat niet meer.")
		return
	await _enter_world(scene.instantiate() as GameWorld, &"", {}, data)


func _on_player_died() -> void:
	if _app_state != AppState.PLAYING:
		return
	var world_at_death: GameWorld = _world
	await get_tree().create_timer(DEATH_DELAY).timeout
	if _world != world_at_death or _changing_world:
		return
	var latest: String = SaveManager.get_latest_save_id()
	if latest.is_empty() or not SaveManager.load_save(latest):
		_world.respawn_player()


func _wants_captured_mouse() -> bool:
	return _app_state == AppState.PLAYING and not get_tree().paused


func _update_mouse() -> void:
	if not _wants_captured_mouse():
		_capture_on_focus = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif get_window().has_focus():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		# Catching the mouse fails while the window has no focus, so wait for it.
		_capture_on_focus = true


func _fade_to(alpha: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await tween.finished
