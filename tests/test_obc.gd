extends SceneTree
## Headless test for Quest 4 and OBC Elst Fort: Klaas gives the quest,
## voetballers shoot footballs, a fatbiker's charge hurts, the staff room is a
## checkpoint, and the fatbike-kindje revs, charges, crashes into a wall and is
## only hurt while dazed; below half health he charges twice in a row. The
## arena gate closes and saving is blocked during the fight, he stays beaten
## after loading, OBC is liberated, Klaas hands out the reward, and a boss
## beaten before Klaas asked still counts. Uses its own save folder.
## Run: godot --headless --path . --fixed-fps 60 -s res://tests/test_obc.gd
##
## The main script of -s is compiled before the autoloads exist, so project
## classes that use them (Main, Player, FatbikeKid) are held in Variant here.

const TEST_SAVE_DIR: String = "user://test_saves/"
const QUEST: StringName = &"q4_obc"
const DUNGEON: String = "res://scenes/dungeons/OBC.tscn"
const AIMING: int = 1
const DAZED: int = 3

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
	_finish_earlier_quests()
	await _frames(5)
	_check(_main.get_world().find_child("Voetballer1", true, false) != null, "kakkers hold the OBC pitch in Elst")
	await _test_klaas_gives_quest()
	await _test_enemies()
	await _test_checkpoint()
	await _test_boss_fight()
	await _test_boss_stays_beaten()
	await _test_obc_liberated()
	await _test_reward()
	await _test_beaten_early()
	_clear_saves()
	DirAccess.remove_absolute(TEST_SAVE_DIR)
	print("test_obc: %d failed" % _failures)
	quit(1 if _failures > 0 else 0)


func _finish_earlier_quests() -> void:
	for quest: StringName in [&"q1_tutorial", &"q2_station", &"q3_westeraam"]:
		_quests.complete_quest(quest)
	for flag: StringName in [&"q1_reported", &"station_cleared", &"boss_vape_koning"]:
		_state.set_flag(flag)


func _test_klaas_gives_quest() -> void:
	await _enter_klaas_house()
	var box: Variant = await _talk_to_klaas()
	box.choose(0)
	box.choose(1)
	_check(box.get_current_line().id == &"q4_offer", "after Quest 3 Klaas tells about the OBC")
	box.choose(0)
	box.choose(0)
	_check(_quests.get_status(QUEST) == 1 and _step() == &"boss", "taking the job starts Quest 4")
	await _press(&"pause")
	await _frames(5)


func _test_enemies() -> void:
	await _go_to(DUNGEON)
	_check(_main.get_world().location_name == "OBC Elst Fort", "the school door leads into OBC Elst Fort")
	var kicker: Variant = _main.get_world().find_child("Voetballer1", true, false)
	var biker: Variant = _main.get_world().find_child("Fatbiker1", true, false)
	_check(kicker.data.is_ranged() and is_equal_approx(kicker.data.accuracy, 0.6), "voetballers shoot, and hit 60% of the time")
	_check(kicker.health.max_health == 30 and biker.health.max_health == 52, "the destroyed station weakens OBC's enemies")
	_place(kicker.global_position + Vector3(0, 0, 9), 0.0)
	var shot: bool = false
	for i: int in 600:
		await physics_frame
		shot = shot or not _projectiles().is_empty()
		if shot:
			break
	_check(shot, "a voetballer kicks footballs")
	# Footballs land in the same node as the enemies, so pick the enemies out.
	for enemy: Variant in _main.get_world().get_node("Enemies").get_children():
		if enemy != biker and enemy.is_in_group(&"enemies"):
			enemy.health.take_damage(999)
	await _frames(30)
	_player().health.set_health(100)
	_place(biker.global_position + biker.get_forward() * 5.0, biker.rotation.y + PI)
	for i: int in 400:
		await physics_frame
		if _player().health.current_health < 100:
			break
	_check(_player().health.current_health <= 90, "a fatbiker's charge hurts")
	_player().is_invulnerable = true
	biker.health.take_damage(999)


func _test_checkpoint() -> void:
	var autosaves: int = _count_saves("auto")
	_place(Vector3(-10, 0, -84), -PI / 2)
	await _frames(5)
	_place(_main.get_world().get_node("Checkpoint").global_position, -PI / 2)
	await _frames(60)
	_check(_count_saves("auto") == autosaves + 1, "the staff room halfway is a checkpoint with an autosave")


func _test_boss_fight() -> void:
	var kid: Variant = _main.get_world().find_child("FatbikeKid", true, false)
	var gate: Variant = _main.get_world().get_node("ArenaGate")
	_place(Vector3(-16, 0, -164), 0.0)
	await _frames(5)
	_check(kid.mode == AIMING, "walking onto the sports field starts the fight")
	_check(_state.is_saving_blocked() and _main.get_node("UI/HUD/BossBar").visible, "saving is blocked and the boss bar shows")
	_check(gate.visible and not gate.get_node("CollisionShape3D").disabled, "the gate of the sports field closes")
	_check(kid.get_node("AimLine").visible and kid.get_node("RevLabel").visible, "he revs up and a line shows where he will go")
	kid.get_node("Hurtbox").receive_hit(load("res://scripts/components/hit_data.gd").new(50, _player(), null))
	_check(kid.health.current_health == 450, "on his bike he cannot be hurt")
	await _wait_for_mode(kid, DAZED)
	_check(kid.mode == DAZED, "he crashes into a wall and is dazed")
	kid.get_node("Hurtbox").receive_hit(load("res://scripts/components/hit_data.gd").new(100, _player(), null))
	_check(kid.health.current_health == 350, "a dazed fatbike-kindje takes damage")
	kid.health.take_damage(150)
	await _wait_for_mode(kid, AIMING)
	var charges: int = kid.charge_count
	await _wait_for_mode(kid, DAZED)
	_check(kid.charge_count == charges + 2, "below half health he charges twice in a row")
	kid.health.take_damage(1000)
	await _frames(5)
	_check(_state.has_flag(&"boss_fatbike_kindje"), "beating him is remembered")
	_check(not _state.is_saving_blocked() and not _main.get_node("UI/HUD/BossBar").visible, "saving works again and the boss bar goes away")
	_check(not gate.visible, "the gate opens again")
	_check(_step() == &"report", "then the quest sends you back to Klaas")
	await _frames(60)


func _test_boss_stays_beaten() -> void:
	root.get_node("SaveManager").quicksave()
	_quests.reset()
	root.get_node("SaveManager").quickload()
	await _wait_for_world("OBC Elst Fort")
	await _frames(10)
	var kid: Variant = _main.get_world().find_child("FatbikeKid", true, false)
	_check(kid == null or kid.is_queued_for_deletion(), "a beaten fatbike-kindje stays gone after loading")


func _test_obc_liberated() -> void:
	await _go_to("res://scenes/world/Elst.tscn", &"OBCExit")
	await _frames(5)
	var areas: Variant = _main.get_world().get_node("Areas")
	_check(areas.get_node("OBCArea/Liberated").visible, "villagers walk on the OBC pitch")
	_check(areas.find_child("Voetballer1", true, false) == null, "the kakkers are gone from the pitch")


func _test_reward() -> void:
	var gold: int = _state.gold
	await _go_to("res://scenes/world/Elst.tscn", &"Start")
	await _enter_klaas_house()
	var box: Variant = await _talk_to_klaas()
	_check(box.get_current_line().id == &"q4_report", "Klaas hears about the fatbike-kindje")
	box.choose(0)
	_check(_quests.get_status(QUEST) == 2, "reporting back finishes Quest 4")
	_check(_state.gold == gold + 150 and _state.inwijding == 4, "the reward is 150 gold and Inwijding 4")
	await _press(&"pause")
	await _frames(5)


func _test_beaten_early() -> void:
	_state.reset()
	_quests.reset()
	_finish_earlier_quests()
	_state.set_flag(&"boss_fatbike_kindje")
	var gold: int = _state.gold
	await _frames(30)
	var box: Variant = await _talk_to_klaas()
	box.choose(0)
	box.choose(1)
	_check(box.get_current_line().id == &"q4_early", "Klaas already heard the engine stop")
	box.choose(0)
	_check(_quests.get_status(QUEST) == 2 and _state.gold == gold + 150 and _state.inwijding == 4, "a boss beaten early still gives the reward")
	await _press(&"pause")


func _wait_for_mode(kid: Variant, mode: int) -> void:
	for i: int in 600:
		if kid.mode == mode:
			return
		await physics_frame


func _projectiles() -> Array[Node]:
	var found: Array[Node] = []
	for node: Node in _main.get_world().find_children("*", "Area3D", true, false):
		if node.get_script() != null and node.get_script().resource_path.ends_with("vape_puff.gd") and not node.is_queued_for_deletion():
			found.append(node)
	return found


func _count_saves(save_type: String) -> int:
	var count: int = 0
	for meta: Dictionary in root.get_node("SaveManager").list_saves():
		if meta.get("type") == save_type:
			count += 1
	return count


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
