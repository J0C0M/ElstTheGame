extends SceneTree
## Headless test for Quest 3 and the liberated areas: liberated areas in Elst
## swap patrols for villagers, Klaas gives the quest, vape-drillers shoot vape
## puffs and keep their distance, the checkpoint halfway autosaves and its
## bench heals, the Vape-koning hides in his clouds, is only
## hurt while exposed, fills the palace with vape while he flees, fires three
## puffs below half health, blocks saving
## during the fight and stays beaten after loading. Westeraam is liberated,
## Klaas hands out the reward, and a boss beaten before Klaas asked still
## counts. Uses its own save folder.
## Run: godot --headless --path . --fixed-fps 60 -s res://tests/test_westeraam.gd
##
## The main script of -s is compiled before the autoloads exist, so project
## classes that use them (Main, Player, VapeKing) are held in Variant here.

const TEST_SAVE_DIR: String = "user://test_saves/"
const QUEST: StringName = &"q3_westeraam"
const DUNGEON: String = "res://scenes/dungeons/Westeraam.tscn"

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
	_state.add_gear(load("res://data/items/rusty_sword.tres"))
	await _test_liberated_areas()
	await _test_klaas_gives_quest()
	await _test_vape_drillers()
	await _test_checkpoint()
	await _test_boss_fight()
	await _test_boss_stays_beaten()
	await _test_westeraam_liberated()
	await _test_reward()
	await _test_beaten_early()
	_clear_saves()
	DirAccess.remove_absolute(TEST_SAVE_DIR)
	print("test_westeraam: %d failed" % _failures)
	quit(1 if _failures > 0 else 0)


func _test_liberated_areas() -> void:
	var areas: Variant = _main.get_world().get_node("Areas")
	_check(not areas.get_node("StationArea/Liberated").visible, "an occupied area has no villagers")
	_check(areas.find_child("LowDriller1", true, false) != null, "drillers patrol the station while it is occupied")
	_quests.complete_quest(&"q1_tutorial")
	_state.set_flag(&"q1_reported")
	_quests.complete_quest(&"q2_station")
	_state.set_flag(&"station_cleared")
	await _frames(5)
	_check(areas.get_node("KlaasArea/Liberated").visible, "after Quest 1 villagers come to Klaas' street")
	_check(areas.get_node("StationArea/Liberated").visible, "after the station villagers fill the station square")
	_check(areas.find_child("LowDriller1", true, false) == null, "the station patrol is gone for good")
	_check(areas.find_child("Driller1", true, false) != null, "Westeraam is still occupied")


func _test_klaas_gives_quest() -> void:
	await _enter_klaas_house()
	var box: Variant = await _talk_to_klaas()
	box.choose(0)
	box.choose(1)
	_check(box.get_current_line().id == &"q3_offer", "after Quest 2 Klaas tells about the Vape-koning")
	box.choose(0)
	box.choose(0)
	_check(_quests.get_status(QUEST) == 1 and _step() == &"boss", "taking the job starts Quest 3")
	await _press(&"pause")
	await _frames(5)
	await _stand_at("ExitDoor", 1.6)
	await _press(&"interact")
	await _wait_for_world("Elst")
	await _frames(5)
	_check(_main.get_node("UI/HUD/Compass").has_target(), "the compass points to Westeraam")


func _test_vape_drillers() -> void:
	await _go_to(DUNGEON)
	_check(_main.get_world().location_name == "Westeraam Getho", "the flats lead into the Westeraam dungeon")
	var vaper: Variant = _main.get_world().find_child("VapeDriller1", true, false)
	_check(vaper.data.is_ranged(), "vape-drillers fight from a distance")
	_check(vaper.health.max_health == 24, "the destroyed station weakens vape-drillers too (%d)" % vaper.health.max_health)
	var to_vaper: Vector3 = vaper.global_position - Vector3(vaper.global_position.x - 8.0, 0, vaper.global_position.z)
	_place(vaper.global_position - Vector3(8, 0, 0), atan2(to_vaper.x, to_vaper.z) + PI)
	var shot: bool = false
	for i: int in 600:
		await physics_frame
		if not _puffs().is_empty():
			shot = true
		if _player().health.current_health < 100:
			break
	_check(shot, "a vape-driller blows vape puffs")
	_check(_player().health.current_health < 100, "a vape puff hurts the player")
	_player().is_invulnerable = true
	_place(vaper.global_position + Vector3(2.5, 0, 0), 0.0)
	var start: float = _player().global_position.distance_to(vaper.global_position)
	await _frames(120)
	_check(_player().global_position.distance_to(vaper.global_position) > start + 0.5, "a vape-driller backs off when the player comes close")


func _test_checkpoint() -> void:
	var checkpoint: Variant = _main.get_world().get_node("Checkpoint")
	var autosaves: int = _count_saves("auto")
	_place(Vector3(-20, 0, -48), -PI / 2)
	await _frames(5)
	_place(checkpoint.global_position, -PI / 2)
	await _frames(60)
	_check(checkpoint.is_reached(), "the bike cellar halfway is a checkpoint")
	_check(_count_saves("auto") == autosaves + 1, "reaching the checkpoint makes an autosave")
	_player().health.set_health(40)
	var bench: Variant = _main.get_world().get_node("RestBench")
	_place(bench.global_position + bench.global_basis.z * -1.2, bench.global_rotation.y + PI)
	await _frames(5)
	await _press(&"interact")
	await _frames(90)
	_check(_player().health.current_health == _player().health.max_health, "resting on the bench heals")


func _count_saves(save_type: String) -> int:
	var count: int = 0
	for meta: Dictionary in root.get_node("SaveManager").list_saves():
		if meta.get("type") == save_type:
			count += 1
	return count


func _test_boss_fight() -> void:
	var king: Variant = _main.get_world().find_child("VapeKing", true, false)
	_place(Vector3(-27, 0, -116), PI)
	for i: int in 30:
		await physics_frame
		if king.mode != 0:
			break
	_check(king.mode == 1, "walking into his palace starts the fight")
	_check(_state.is_saving_blocked(), "saving is blocked during the boss fight")
	_check(_main.get_node("UI/HUD/BossBar").visible, "the HUD shows the boss's health bar")
	king.get_node("Hurtbox").receive_hit(load("res://scripts/components/hit_data.gd").new(50, _player(), null))
	_check(king.health.current_health == 400, "inside his cloud he cannot be hurt")
	await _frames(150)
	_check(not _puffs().is_empty(), "he blows vape puffs from his cloud")
	var cloud: int = king.get("_cloud_index")
	_place(king.global_position + Vector3(1.5, 0, 0), 0.0)
	await _frames(5)
	_check(king.mode == 2, "walking into his cloud exposes him")
	king.get_node("Hurtbox").receive_hit(load("res://scripts/components/hit_data.gd").new(100, _player(), null))
	_check(king.health.current_health == 300, "an exposed Vape-koning takes damage")
	var environment: Environment = _main.get_world().get_node("WorldEnvironment").environment
	var thickest_fog: float = 0.0
	for i: int in 400:
		await physics_frame
		if king.mode == 3:
			thickest_fog = maxf(thickest_fog, environment.fog_density)
		if king.mode == 1:
			break
	_check(king.mode == 1 and king.get("_cloud_index") != cloud, "after a few seconds he flees to another cloud")
	_check(thickest_fog > 0.15, "while he flees, thick vape fills the palace")
	await _frames(90)
	_check(environment.fog_density < 0.01, "the vape clears once he sits in his new cloud")
	king.health.take_damage(150)
	var before: int = _puffs().size()
	king.call("_shoot", _player())
	_check(_puffs().size() == before + 3, "below half health he blows three puffs at once")
	_place(king.global_position + Vector3(1.5, 0, 0), 0.0)
	await _frames(5)
	king.health.take_damage(1000)
	await _frames(5)
	_check(_state.has_flag(&"boss_vape_koning"), "beating him is remembered")
	_check(not _state.is_saving_blocked(), "saving works again after the fight")
	_check(not _main.get_node("UI/HUD/BossBar").visible, "the boss bar goes away")
	_check(_step() == &"report", "then the quest sends you back to Klaas")
	await _frames(60)


func _test_boss_stays_beaten() -> void:
	root.get_node("SaveManager").quicksave()
	_quests.reset()
	root.get_node("SaveManager").quickload()
	await _wait_for_world("Westeraam Getho")
	await _frames(10)
	var king: Variant = _main.get_world().find_child("VapeKing", true, false)
	_check(king == null or king.is_queued_for_deletion(), "a beaten Vape-koning stays gone after loading")


func _test_westeraam_liberated() -> void:
	await _go_to("res://scenes/world/Elst.tscn", &"WesteraamExit")
	await _frames(5)
	var areas: Variant = _main.get_world().get_node("Areas")
	_check(areas.get_node("WesteraamArea/Liberated").visible, "villagers walk around Westeraam")
	_check(areas.find_child("Driller1", true, false) == null, "no more driller patrols in Westeraam")
	var villager: Variant = areas.get_node("WesteraamArea/Liberated/Villager1")
	_place(villager.global_position + Vector3(1.5, 0, 0), 0.0)
	await _frames(10)
	_check(villager.get_node("Speech").visible, "a villager waves and says something")


func _test_reward() -> void:
	var gold: int = _state.gold
	var inwijding: int = _state.inwijding
	await _go_to("res://scenes/world/Elst.tscn", &"Start")
	await _enter_klaas_house()
	var box: Variant = await _talk_to_klaas()
	_check(box.get_current_line().id == &"q3_report", "Klaas hears about the Vape-koning")
	box.choose(0)
	_check(_quests.get_status(QUEST) == 2, "reporting back finishes Quest 3")
	_check(_state.gold == gold + 150, "the reward is 150 gold")
	_check(_state.inwijding == inwijding + 1, "the reward includes Inwijding +1")
	await _press(&"pause")
	await _frames(5)


func _test_beaten_early() -> void:
	_state.reset()
	_quests.reset()
	_quests.complete_quest(&"q1_tutorial")
	_quests.complete_quest(&"q2_station")
	_state.set_flag(&"boss_vape_koning")
	var gold: int = _state.gold
	await _frames(30)
	var box: Variant = await _talk_to_klaas()
	box.choose(0)
	box.choose(1)
	_check(box.get_current_line().id == &"q3_early", "Klaas already heard about the Vape-koning")
	box.choose(0)
	_check(_quests.get_status(QUEST) == 2, "a boss beaten early finishes Quest 3 at once")
	_check(_state.gold == gold + 150 and _state.inwijding == 3, "the reward still comes")
	await _press(&"pause")


func _puffs() -> Array[Node]:
	var found: Array[Node] = []
	for node: Node in _main.get_world().find_children("*", "Area3D", true, false):
		if node.get_script() != null and node.get_script().resource_path.ends_with("vape_puff.gd") and not node.is_queued_for_deletion():
			found.append(node)
	return found


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


func _press(action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS ", description)
	else:
		_failures += 1
		printerr("FAIL ", description)
