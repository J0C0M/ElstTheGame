extends SceneTree
## Headless test for Quest 2 and the station dungeon: Klaas gives the quest,
## the compass points to the station, a generator breaks under the sword and
## stays broken after loading, the last generator clears the station,
## Westeraam drillers get weaker, Klaas hands out the reward, and a station
## cleared before Klaas asked still counts. Uses its own save folder.
## Run: godot --headless --path . --fixed-fps 60 -s res://tests/test_station.gd
##
## The main script of -s is compiled before the autoloads exist, so project
## classes that use them (Main, Player, Generator) are held in Variant here.

const TEST_SAVE_DIR: String = "user://test_saves/"
const QUEST: StringName = &"q2_station"
const STATION: String = "res://scenes/dungeons/Station.tscn"

var _failures: int = 0
var _main: Variant
var _quests: Variant
var _state: Variant


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("SaveManager").save_dir = TEST_SAVE_DIR
	_clear_saves()
	_quests = root.get_node("QuestManager")
	_state = root.get_node("GameState")
	_main = (load("res://scenes/main/Main.tscn") as PackedScene).instantiate()
	_main.skip_main_menu = true
	root.add_child(_main)
	await _wait_for_world("Elst")
	_quests.complete_quest(&"q1_tutorial")
	_state.add_gear(load("res://data/items/rusty_sword.tres"))
	await _test_klaas_gives_quest()
	await _test_first_generator()
	await _test_save_keeps_generator()
	await _test_station_cleared()
	await _test_reward()
	await _test_cleared_early()
	_clear_saves()
	DirAccess.remove_absolute(TEST_SAVE_DIR)
	print("test_station: %d failed" % _failures)
	quit(1 if _failures > 0 else 0)


func _test_klaas_gives_quest() -> void:
	await _enter_klaas_house()
	var box: Variant = await _talk_to_klaas()
	box.choose(0)
	_check(box.get_current_line().id == &"hub", "Klaas asks what you want")
	box.choose(1)
	_check(box.get_current_line().id == &"q2_offer", "after the tutorial Klaas has a new job")
	box.choose(0)
	box.choose(0)
	_check(_quests.get_status(QUEST) == 1, "taking the job starts Quest 2")
	_check(_step() == &"generators", "the first objective is the four generators")
	box.choose(0)
	_check(box.get_current_line().id == &"hub", "then Klaas asks what else you want")
	await _press(&"pause")
	await _frames(5)
	_check(_main.get_node("UI/HUD/Compass").has_target(), "inside, the compass points to the way out")
	await _stand_at("ExitDoor", 1.6)
	await _press(&"interact")
	await _wait_for_world("Elst")
	await _frames(5)
	_check(_main.get_node("UI/HUD/Compass").has_target(), "in Elst the compass points to the station")


func _test_first_generator() -> void:
	await _go_to(STATION)
	_check(_main.get_world().location_name == "Station Elst", "the station door leads into the dungeon")
	var group: Variant = _main.get_world().get_node("Generators")
	_check(group.get_generators().size() == 4, "the dungeon has four generators")
	_check(_main.get_node("UI/HUD/Compass").has_target(), "in the dungeon the compass points to a generator")
	_player().is_invulnerable = true
	var generator: Variant = group.get_node("Generator1")
	var front: Vector3 = generator.global_position + generator.global_basis.z * -1.9
	var to_generator: Vector3 = generator.global_position - front
	_place(front, atan2(to_generator.x, to_generator.z) + PI)
	await _frames(5)
	for i: int in 30:
		if generator.is_broken():
			break
		await _tap(&"attack")
		await _frames(30)
	_check(generator.is_broken(), "sword hits break a generator")
	_check(_state.has_flag(&"station_generator_1"), "a broken generator is remembered")
	_check(_quests.get_step_progress(QUEST) == "1/4", "the HUD counts the generators")
	await _frames(2)
	var marker: Variant = _main.get_world().find_quest_marker(&"generator")
	_check(marker != null and not generator.is_ancestor_of(marker), "the compass moves on to a generator that still runs")


func _test_save_keeps_generator() -> void:
	await _frames(30)
	root.get_node("SaveManager").quicksave()
	_quests.reset()
	root.get_node("SaveManager").quickload()
	await _wait_for_world("Station Elst")
	await _frames(10)
	var generator: Variant = _main.get_world().get_node("Generators/Generator1")
	_check(generator.is_broken() and not generator.get_node("Light").visible, "a broken generator stays broken after loading")
	_check(_quests.get_step_progress(QUEST) == "1/4", "the quest still counts one generator")


func _test_station_cleared() -> void:
	var group: Variant = _main.get_world().get_node("Generators")
	for name: String in ["Generator2", "Generator3", "Generator4"]:
		group.get_node(name).get_node("Health").take_damage(1000)
		await _frames(3)
	_check(group.count_running() == 0 and _state.has_flag(&"station_cleared"), "breaking the last generator clears the station")
	_check(_step() == &"report", "then the quest sends you back to Klaas")
	var driller: Variant = (load("res://scenes/enemies/Driller.tscn") as PackedScene).instantiate()
	var low_driller: Variant = (load("res://scenes/enemies/LowDriller.tscn") as PackedScene).instantiate()
	_main.get_world().add_child(driller)
	_main.get_world().add_child(low_driller)
	driller.global_position = Vector3(0, 0, 12)
	low_driller.global_position = Vector3(2, 0, 12)
	await _frames(2)
	_check(driller.health.max_health == 32, "Westeraam drillers have 20%% less health now (%d)" % driller.health.max_health)
	_check(low_driller.health.max_health == 30, "Amber's own laag drillers keep their health")
	driller.queue_free()
	low_driller.queue_free()


func _test_reward() -> void:
	var gold: int = _state.gold
	await _go_to("res://scenes/world/Elst.tscn", &"StationExit")
	await _enter_klaas_house()
	var box: Variant = await _talk_to_klaas()
	_check(box.get_current_line().id == &"q2_report", "Klaas is proud of the quiet tracks")
	box.choose(0)
	_check(_quests.get_status(QUEST) == 2, "reporting back finishes Quest 2")
	_check(_state.gold == gold + 75, "the reward is 75 gold")
	_check(_state.inwijding == 2, "the reward includes Inwijding 2")
	box.choose(0)
	box.choose(1)
	_check(box.get_current_line().id == &"q3_offer", "after Quest 2 Klaas has the next job")
	await _press(&"pause")
	await _frames(5)


func _test_cleared_early() -> void:
	_state.reset()
	_quests.reset()
	_quests.complete_quest(&"q1_tutorial")
	_state.set_flag(&"station_cleared")
	_check(_quests.get_status(QUEST) == 0, "clearing the station does not start Quest 2 by itself")
	var gold: int = _state.gold
	await _frames(30)
	var box: Variant = await _talk_to_klaas()
	box.choose(0)
	box.choose(1)
	_check(box.get_current_line().id == &"q2_early", "Klaas notices the station is already down")
	box.choose(0)
	_check(_quests.get_status(QUEST) == 2, "a station cleared early finishes Quest 2 at once")
	_check(_state.gold == gold + 75 and _state.inwijding == 2, "the reward still comes")
	await _press(&"pause")


func _enter_klaas_house() -> void:
	await _stand_at("FrontDoor", 1.6)
	await _press(&"interact")
	await _wait_for_world("Huis van Klaas")


func _talk_to_klaas() -> Variant:
	_place(Vector3(0, 0, -0.9), 0.0)
	await _frames(10)
	await _press(&"interact")
	return _main.get_node("UI/Menus/DialogueBox")


func _step() -> StringName:
	var step: Variant = _quests.get_current_step(QUEST)
	return step.id if step != null else &""


func _go_to(scene_path: String, spawn_id: StringName = &"Entrance") -> void:
	# Main ignores a request while a fade is still running, so ask again.
	for attempt: int in 10:
		if _main.get_world() != null and _main.get_world().scene_file_path == scene_path and not _main.get("_changing_world"):
			break
		root.get_node("EventBus").world_change_requested.emit(scene_path, spawn_id)
		await _frames(60)


func _wait_for_world(location: String) -> void:
	for i: int in 300:
		var world: Variant = _main.get_world()
		if world != null and world.location_name == location and not _main.get("_changing_world"):
			return
		await physics_frame


func _stand_at(node_name: String, distance: float) -> void:
	var target: Node3D = _main.get_world().find_child(node_name, true, false)
	_place(target.global_position - target.global_basis.z * distance, target.global_rotation.y + PI)
	await _frames(5)


func _place(position: Vector3, yaw: float) -> void:
	var player: Variant = _player()
	player.teleport(Transform3D(Basis(Vector3.UP, yaw), position))
	player.camera.yaw = yaw


func _player() -> Variant:
	return _main.get_world().get_player()


func _clear_saves() -> void:
	var dir: DirAccess = DirAccess.open(TEST_SAVE_DIR)
	if dir != null:
		for file_name: String in dir.get_files():
			dir.remove(file_name)


func _frames(count: int) -> void:
	for i: int in count:
		await physics_frame


func _act(action: StringName, pressed: bool) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _press(action: StringName) -> void:
	_act(action, true)
	await process_frame
	await process_frame
	_act(action, false)
	await process_frame


func _tap(action: StringName) -> void:
	_act(action, true)
	await _frames(3)
	_act(action, false)
	await physics_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS ", description)
	else:
		_failures += 1
		printerr("FAIL ", description)
