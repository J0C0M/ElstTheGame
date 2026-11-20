extends SceneTree
## Headless test for saving and loading: quicksave and quickload, autosaves in
## dungeons and their three slots, named saves that bring back the scene,
## blocked saves in the air, loading the last save after dying, the version
## check, and play time while paused. Uses its own save folder.
## Run: godot --headless --path . --fixed-fps 60 -s res://tests/test_save.gd
##
## The main script of -s is compiled before the autoloads exist, so project
## classes that use them (Main, Player, SaveManager) are held in Variant here.

const TEST_SAVE_DIR: String = "user://test_saves/"

var _failures: int = 0
var _main: Variant
var _saves: Variant
var _game_state: Variant


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_saves = root.get_node("SaveManager")
	_game_state = root.get_node("GameState")
	_saves.save_dir = TEST_SAVE_DIR
	_clear_saves()
	_main = (load("res://scenes/main/Main.tscn") as PackedScene).instantiate()
	_main.skip_main_menu = true
	root.add_child(_main)
	await _frames(40)
	await _test_quicksave_and_quickload()
	await _test_dungeon_autosave_and_named_save()
	await _test_no_saving_in_the_air()
	await _test_death_loads_last_save()
	await _test_autosave_slots()
	await _test_version_check()
	await _test_play_time()
	await _test_beaten_dungeon()
	_clear_saves()
	DirAccess.remove_absolute(TEST_SAVE_DIR)
	print("test_save: %d failed" % _failures)
	quit(1 if _failures > 0 else 0)


func _test_quicksave_and_quickload() -> void:
	# Two open spots in Klaas' garden, next to the start.
	var start: Vector3 = _main.get_world().get_spawn(&"Start").global_position
	var spot: Vector3 = start + Vector3(3, 0, 1)
	_place(spot, 1.0)
	_player().health.set_health(61)
	_game_state.gold = 42
	await _frames(5)
	await _press(&"quicksave")
	_check(FileAccess.file_exists(TEST_SAVE_DIR + "quicksave.json"), "F5 writes the quicksave")
	_place(start + Vector3(-3, 0, 2), 0.0)
	_player().health.set_health(100)
	_game_state.gold = 0
	await _frames(5)
	await _press(&"quickload")
	await _frames(60)
	_check(_main.get_world().location_name == "Elst", "F9 loads back into Elst")
	_check(_player().global_position.distance_to(spot) < 0.1, "the position comes back")
	_check(absf(angle_difference(_player().rotation.y, 1.0)) < 0.01, "the rotation comes back")
	_check(_player().health.current_health == 61, "the health comes back")
	_check(_game_state.gold == 42, "GameState comes back")


func _test_dungeon_autosave_and_named_save() -> void:
	root.get_node("EventBus").world_change_requested.emit("res://scenes/dungeons/Station.tscn", &"Entrance")
	await _frames(60)
	_check(_main.get_world().location_name == "Station Elst", "the door leads into the station dungeon")
	_check(_count_saves("auto") == 1, "entering a dungeon makes an autosave")
	var entrance: Vector3 = _main.get_world().get_spawn(&"Entrance").global_position
	var dungeon_spot: Vector3 = entrance + Vector3(3, 0, -4)
	_place(dungeon_spot, PI)
	_player().health.set_health(50)
	await _frames(5)
	OS.delay_msec(5)
	_check(_saves.save_game(0, "Test dungeon"), "a named save can be made")
	root.get_node("EventBus").world_change_requested.emit("res://scenes/world/Elst.tscn", &"StationExit")
	await _frames(60)
	_check(_main.get_world().location_name == "Elst", "back in Elst")
	_check(_saves.load_save(_find_save("Test dungeon")), "the named save loads")
	await _frames(60)
	_check(_main.get_world().location_name == "Station Elst", "loading brings back the dungeon scene")
	_check(_player().global_position.distance_to(dungeon_spot) < 0.1, "loading brings back the dungeon position")
	_check(_player().health.current_health == 50, "loading brings back the health")


func _test_no_saving_in_the_air() -> void:
	_player().velocity.y = 6.0
	await _frames(3)
	_check(not _saves.can_save(), "no saving while falling or jumping")
	var count: int = _saves.list_saves().size()
	_saves.save_game(0, "In de lucht")
	_check(_saves.list_saves().size() == count, "a save in the air is refused")
	await _frames(90)


func _test_death_loads_last_save() -> void:
	_place(_main.get_world().get_spawn(&"Entrance").global_position + Vector3(-4, 0, -2), 0.0)
	_player().health.set_health(90)
	await _frames(5)
	_player().health.take_damage(90)
	await _frames(roundi(3.0 * 60.0) + 60)
	_check(_main.get_world().location_name == "Station Elst", "after dying the last save loads")
	_check(_player().health.current_health == 50, "the last save's health is back")
	_check(not _player().health.is_dead(), "the player lives again")
	_check(not _main.get_node("UI/HUD/DeathLabel").visible, "the death message goes away once the save is loaded")


func _test_autosave_slots() -> void:
	for i: int in 4:
		OS.delay_msec(5)
		_saves.autosave()
	_check(_count_saves("auto") == 3, "there are never more than three autosaves")


func _test_version_check() -> void:
	var file: FileAccess = FileAccess.open(TEST_SAVE_DIR + "future.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"save_version": 999, "scene": "res://scenes/world/Elst.tscn", "meta": {}}))
	file.close()
	_check(not _saves.load_save("future"), "a save from a newer version is refused")
	DirAccess.remove_absolute(TEST_SAVE_DIR + "future.json")


func _test_play_time() -> void:
	var start: float = _game_state.play_time
	await _frames(30)
	_check(_game_state.play_time > start, "play time counts while playing")
	_main.pause()
	var paused_at: float = _game_state.play_time
	await _frames(30)
	_check(is_equal_approx(_game_state.play_time, paused_at), "play time stops while paused")
	_main.resume()


func _test_beaten_dungeon() -> void:
	_game_state.set_flag(&"station_cleared")
	root.get_node("EventBus").world_change_requested.emit("res://scenes/dungeons/Station.tscn", &"Entrance")
	await _frames(60)
	var world: Variant = _main.get_world()
	_check(world.location_name == "Station Elst" and world.get_node("Enemies").get_child_count() == 0, "a beaten dungeon stays empty of enemies")
	var residents: Variant = world.get_node_or_null("Residents")
	_check(residents != null and residents.get_child_count() == 4, "coming back in through the door, a few residents walk around")
	_place(world.get_spawn(&"Entrance").global_position + Vector3(3, 0, -4), PI)
	await _frames(5)
	await _press(&"quicksave")
	await _press(&"quickload")
	await _frames(60)
	world = _main.get_world()
	_check(world.get_node("Enemies").get_child_count() == 0 and world.get_node_or_null("Residents") == null,
		"loading a save made inside keeps the dungeon empty")


func _count_saves(save_type: String) -> int:
	var count: int = 0
	for meta: Dictionary in _saves.list_saves():
		if meta.get("type") == save_type:
			count += 1
	return count


func _find_save(save_name: String) -> String:
	for meta: Dictionary in _saves.list_saves():
		if meta.get("name") == save_name:
			return str(meta["id"])
	return ""


func _clear_saves() -> void:
	var dir: DirAccess = DirAccess.open(TEST_SAVE_DIR)
	if dir != null:
		for file_name: String in dir.get_files():
			dir.remove(file_name)


func _place(position: Vector3, yaw: float) -> void:
	var player: Variant = _player()
	player.teleport(Transform3D(Basis(Vector3.UP, yaw), position))
	player.camera.yaw = yaw


func _player() -> Variant:
	return _main.get_world().get_player()


func _frames(count: int) -> void:
	for i: int in count:
		await physics_frame


func _press(action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await physics_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await physics_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS ", description)
	else:
		_failures += 1
		printerr("FAIL ", description)
