extends SceneTree
## Headless test for Quest 6 and the church: the church opens after the three
## faction bosses (also for a save made before the church could open) and
## Quest 6 starts by itself. Uses its own save folder.
## Run: godot --headless --path . --fixed-fps 60 -s res://tests/test_amber.gd
##
## The main script of -s is compiled before the autoloads exist, so project
## classes that use them (Main, Player) are held in Variant here.

const TEST_SAVE_DIR: String = "user://test_saves/"
const QUEST: StringName = &"q6_amber"
const ACTIVE: int = 1

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
	await _test_church_opens()
	await _test_old_save_opens_church()
	_clear_saves()
	DirAccess.remove_absolute(TEST_SAVE_DIR)
	print("test_amber: %d failed" % _failures)
	quit(1 if _failures > 0 else 0)


func _test_church_opens() -> void:
	var door: Variant = _main.get_world().find_child("ChurchDoor", true, false)
	_state.set_flag(&"boss_vape_koning")
	_state.set_flag(&"boss_fatbike_kindje")
	_check(door.is_locked() and _quests.get_status(QUEST) == 0, "two beaten bosses keep the church shut")
	_state.set_flag(&"boss_grumpy_oma")
	await _frames(2)
	_check(_state.has_flag(&"church_open") and _state.church_open and not door.is_locked(), "the third boss opens the church doors")
	_check(_quests.get_status(QUEST) == ACTIVE and _step() == &"enter", "Quest 6 starts by itself: go into the church")


func _test_old_save_opens_church() -> void:
	_state.reset()
	_quests.reset()
	_state.load_data({"flags": ["boss_vape_koning", "boss_fatbike_kindje", "boss_grumpy_oma"]})
	_quests.load_data({})
	_check(_state.has_flag(&"church_open") and _quests.get_status(QUEST) == ACTIVE, "a save from before the church opened gets the open church and Quest 6")


func _step() -> StringName:
	var step: Variant = _quests.get_current_step(QUEST)
	return step.id if step != null else &""


func _wait_for_world(location: String) -> void:
	for i: int in 300:
		var world: Variant = _main.get_world()
		if world != null and world.location_name == location and not _main.get("_changing_world"):
			return
		await physics_frame


func _clear_saves() -> void:
	var dir: DirAccess = DirAccess.open(TEST_SAVE_DIR)
	if dir != null:
		for file_name: String in dir.get_files():
			dir.remove(file_name)


func _frames(count: int) -> void:
	for i: int in count:
		await physics_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS ", description)
	else:
		_failures += 1
		printerr("FAIL ", description)
