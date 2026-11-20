extends SceneTree
## Headless test for Quest 6 and the church: the church opens after the three
## faction bosses (also for a save made before the church could open) and
## Quest 6 starts by itself; Klaas is away from home; the church dungeon has
## enemies of every faction, chanting Amber cultists, flying dragonlings that
## spit fire and fire grates, a checkpoint in the antechamber, and Klaas with
## his last talk and shop, who opens the arena gate. Uses its own save folder.
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
	await _test_klaas_away()
	await _test_church_dungeon()
	await _test_church_enemies()
	await _test_klaas_at_the_gate()
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


func _test_klaas_away() -> void:
	await _enter_house()
	_check(_main.get_world().find_child("Klaas", true, false) != null, "while a quest still waits for him, Klaas stays home")
	await _leave_house()
	for quest: StringName in [&"q1_tutorial", &"q2_station", &"q3_westeraam", &"q4_obc", &"q5_bingo"]:
		_quests.complete_quest(quest)
	await _enter_house()
	var house: Variant = _main.get_world()
	_check(house.find_child("Klaas", true, false) == null and house.get_node("AwayNote").visible, "with all else done, Klaas is off to the church and leaves a note")
	await _leave_house()


func _enter_house() -> void:
	await _stand_at("FrontDoor", 1.6)
	await _press(&"interact")
	await _wait_for_world("Huis van Klaas")


func _leave_house() -> void:
	await _stand_at("ExitDoor", 1.6)
	await _press(&"interact")
	await _wait_for_world("Elst")
	await _frames(10)


func _test_church_dungeon() -> void:
	await _frames(10)
	await _stand_at("ChurchDoor", 1.8)
	await _press(&"interact")
	await _wait_for_world("De Kerk van Amber")
	await _frames(10)
	_player().is_invulnerable = true
	_check(_step() == &"descend", "inside the church the quest says: go down")
	var factions: Dictionary = {}
	for enemy: Node in _main.get_world().get_node("Enemies").get_children():
		factions[enemy.data.faction] = true
	_check(_main.get_world().get_node("Enemies").get_child_count() >= 25 and factions.size() == 4,
		"the church has enemies of every faction (%d factions)" % factions.size())
	var autosaves: int = _count_saves("auto")
	_place(Vector3(12, -15, -191), PI)
	await _frames(30)
	_place(Vector3(8, -15, -196), PI)
	await _frames(60)
	_check(_step() == &"klaas", "down in the antechamber the quest says: talk to Klaas")
	_check(_count_saves("auto") > autosaves, "the antechamber is a checkpoint with an autosave")


func _test_church_enemies() -> void:
	var enemies: Variant = _main.get_world().get_node("Enemies")
	enemies.get_node("Cultist3/Chanter").chant()
	_check(enemies.get_node("VapeDriller4").damage_multiplier > 1.0, "an Amber cultist's chant fires up the enemies around him")
	var dragon: Variant = enemies.get_node("Dragonling3")
	_place(Vector3(12, -10, -138), PI)
	for i: int in 240:
		await physics_frame
		if dragon.mode == 1 and dragon.global_position.y > -7.5:
			break
	_check(dragon.mode == 1 and dragon.global_position.y > -7.5, "a dragonling sees the player and flies above them")
	var fireball: bool = false
	for i: int in 300:
		await physics_frame
		for node: Node in _main.get_world().get_children():
			fireball = fireball or node.scene_file_path.ends_with("Fireball.tscn")
		if fireball:
			break
	_check(fireball, "it spits fireballs")
	dragon.health.take_damage(100)
	await _frames(5)
	_check(dragon.mode == 3 and not dragon.is_in_group(&"enemies"), "a dragonling can be shot down")
	var grate: Variant = _main.get_world().get_node("FireGrate1")
	var burned: bool = false
	for i: int in 300:
		await physics_frame
		burned = burned or grate.is_burning()
	_check(burned, "the fire grates in the tunnel flare up in turns")


func _test_klaas_at_the_gate() -> void:
	var gate: Variant = _main.get_world().get_node("ArenaGate")
	_check(gate.visible, "the arena gate is shut")
	var box: Variant = await _talk_to_klaas()
	_check(box.get_current_line().id == &"church_hello", "Klaas waits at the gate of the arena")
	box.choose(1)
	await _frames(3)
	_check(_main.get_node("UI/Menus/ShopMenu").visible, "one last time to buy and sell with Klaas")
	await _press(&"pause")
	await _frames(5)
	box = await _talk_to_klaas()
	box.choose(2)
	_check(_state.has_flag(&"klaas_ready") and _step() == &"amber", "ready: the quest says fight Amber with Klaas")
	await _press(&"pause")
	await _frames(5)
	_check(not gate.visible, "Klaas opens the arena gate")


func _talk_to_klaas() -> Variant:
	var klaas: Node3D = _main.get_world().get_node("Klaas")
	_place(klaas.global_position + Vector3(0, 0, 1.6), 0.0)
	await _frames(10)
	await _press(&"interact")
	return _main.get_node("UI/Menus/DialogueBox")


func _count_saves(save_type: String) -> int:
	var count: int = 0
	for meta: Dictionary in root.get_node("SaveManager").list_saves():
		if meta.get("type") == save_type:
			count += 1
	return count


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
