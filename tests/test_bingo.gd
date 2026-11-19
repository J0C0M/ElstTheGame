extends SceneTree
## Headless test for Quest 5, the Bingo Club Boomer Cave and the crossbow:
## Klaas gives the quest, a bingo-opa's BINGO! fires up the grandmas, the
## coffee room is a checkpoint, Grumpy Oma blocks most damage until she is
## exhausted after a slam (with a shockwave) or a tornado, the lair gate
## closes and saving is blocked during the fight, the Bingo Club is
## liberated, Klaas gives the crossbow, a crossbow bolt hurts an enemy, and a
## boss beaten before Klaas asked still counts. Uses its own save folder.
## Run: godot --headless --path . --fixed-fps 60 -s res://tests/test_bingo.gd
##
## The main script of -s is compiled before the autoloads exist, so project
## classes that use them (Main, Player, GrumpyOma) are held in Variant here.

const TEST_SAVE_DIR: String = "user://test_saves/"
const QUEST: StringName = &"q5_bingo"
const DUNGEON: String = "res://scenes/dungeons/BingoCave.tscn"
const CHASE: int = 1
const JUMP: int = 3
const SPIN: int = 4
const EXHAUSTED: int = 5

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
	_check(_main.get_world().find_child("BingoOma1", true, false) != null, "grandmas guard the Bingo Club in Elst")
	await _test_klaas_gives_quest()
	await _test_grandmas()
	await _test_checkpoint()
	await _test_boss_fight()
	await _test_reward_and_crossbow()
	await _test_beaten_early()
	_clear_saves()
	DirAccess.remove_absolute(TEST_SAVE_DIR)
	print("test_bingo: %d failed" % _failures)
	quit(1 if _failures > 0 else 0)


func _finish_earlier_quests() -> void:
	for quest: StringName in [&"q1_tutorial", &"q2_station", &"q3_westeraam", &"q4_obc"]:
		_quests.complete_quest(quest)
	for flag: StringName in [&"q1_reported", &"station_cleared", &"boss_vape_koning", &"boss_fatbike_kindje"]:
		_state.set_flag(flag)


func _test_klaas_gives_quest() -> void:
	await _enter_klaas_house()
	var box: Variant = await _talk_to_klaas()
	box.choose(0)
	box.choose(1)
	_check(box.get_current_line().id == &"q5_offer", "after Quest 4 Klaas tells about the Bingo Club")
	box.choose(0)
	box.choose(0)
	_check(_quests.get_status(QUEST) == 1, "taking the job starts Quest 5")
	await _press(&"pause")
	await _frames(5)


func _test_grandmas() -> void:
	await _go_to(DUNGEON)
	_check(_main.get_world().location_name == "Bingo Club Boomer Cave", "the cave door leads into the Bingo Club")
	_check(_main.get_world().get_node("Enemies").get_child_count() == 24, "the Bingo Club has the most enemies: 24")
	var oma: Variant = _main.get_world().find_child("Oma3", true, false)
	var opa: Variant = _main.get_world().find_child("Opa1", true, false)
	_check(oma.health.max_health == 45, "boze oma's are not weakened by the station")
	opa.get_node("BingoCaller").bingo()
	_check(is_equal_approx(oma.damage_multiplier, 1.25) and oma.get_damage() == 13, "BINGO! makes the grandmas nearby hit 25% harder")
	_player().is_invulnerable = true


func _test_checkpoint() -> void:
	var autosaves: int = _count_saves("auto")
	_place(Vector3(12, 0, -76), PI)
	await _frames(5)
	_place(_main.get_world().get_node("Checkpoint").global_position, PI)
	await _frames(60)
	_check(_count_saves("auto") == autosaves + 1, "the coffee room halfway is a checkpoint with an autosave")


func _test_boss_fight() -> void:
	var oma: Variant = _main.get_world().find_child("GrumpyOma", true, false)
	var gate: Variant = _main.get_world().get_node("ArenaGate")
	_place(Vector3(12, 0, -166), PI)
	await _frames(5)
	_check(oma.mode == CHASE, "walking into her lair starts the fight")
	_check(_state.is_saving_blocked() and gate.visible, "saving is blocked and the gate of the lair closes")
	_hit(oma, 100)
	_check(oma.health.current_health == 525, "her handbag blocks most damage (%d)" % oma.health.current_health)
	_place(oma.global_position + Vector3(0, 0, 8), PI)
	oma.set("_special_timer", 0.0)
	await _frames(2)
	_check(oma.mode == JUMP, "she jumps for a ground slam")
	await _wait_for_mode(oma, EXHAUSTED)
	_check(_count_with_script("shockwave.gd") > 0, "her landing sends a shockwave over the floor")
	_hit(oma, 100)
	_check(oma.health.current_health == 425, "exhausted, she takes full damage")
	await _wait_for_mode(oma, CHASE)
	_place(oma.global_position + Vector3(0, 0, 8), PI)
	oma.set("_special_timer", 0.0)
	await _frames(2)
	_check(oma.mode == SPIN, "next she spins like a tornado")
	await _wait_for_mode(oma, EXHAUSTED)
	_check(oma.mode == EXHAUSTED, "after the tornado she is exhausted too")
	oma.health.take_damage(300)
	_check(oma.is_enraged(), "below 30% health she gets faster")
	oma.health.take_damage(1000)
	await _frames(5)
	_check(_state.has_flag(&"boss_grumpy_oma") and not _state.is_saving_blocked(), "beating her is remembered and saving works again")
	_check(not gate.visible and _step() == &"report", "the gate opens and the quest sends you back to Klaas")
	await _frames(60)


func _test_reward_and_crossbow() -> void:
	await _go_to("res://scenes/world/Elst.tscn", &"BingoExit")
	await _frames(5)
	var areas: Variant = _main.get_world().get_node("Areas")
	_check(areas.get_node("BingoArea/Liberated").visible and areas.find_child("BingoOma1", true, false) == null,
		"the Bingo Club is liberated: villagers instead of grandmas")
	var gold: int = _state.gold
	await _go_to("res://scenes/world/Elst.tscn", &"Start")
	await _enter_klaas_house()
	var box: Variant = await _talk_to_klaas()
	_check(box.get_current_line().id == &"q5_report", "Klaas hears about Grumpy Oma")
	box.choose(0)
	_check(_quests.get_status(QUEST) == 2 and _state.gold == gold + 150 and _state.inwijding == 5, "the reward is 150 gold and Inwijding 5")
	box.choose(0)
	_check(_state.has_gear(&"crossbow"), "Klaas gives his old crossbow")
	await _press(&"pause")
	await _frames(5)
	await _stand_at("ExitDoor", 1.6)
	await _press(&"interact")
	await _wait_for_world("Elst")
	await _frames(10)
	var target: Variant = (load("res://scenes/enemies/BozeOma.tscn") as PackedScene).instantiate()
	_main.get_world().add_child(target)
	target.global_position = _player().global_position + Vector3(0, 0, -9)
	await _frames(5)
	_place(_player().global_position, 0.0)
	_player().camera.pitch = deg_to_rad(-4.0)
	await _press(&"weapon_crossbow")
	_check(_player().weapon == &"crossbow", "key 2 takes the crossbow")
	_act(&"block_aim", true)
	await _frames(10)
	_check(_player().aiming and _main.get_node("UI/HUD/Crosshair").visible, "the right mouse button aims and shows a crosshair")
	await _press(&"attack")
	await _frames(40)
	_act(&"block_aim", false)
	_check(target.health.current_health < 45, "a crossbow bolt hurts an enemy (%d)" % target.health.current_health)
	await _press(&"weapon_sword")
	_check(_player().weapon == &"sword", "key 1 takes the sword again")
	target.queue_free()


func _test_beaten_early() -> void:
	_state.reset()
	_quests.reset()
	_finish_earlier_quests()
	_state.set_flag(&"boss_grumpy_oma")
	await _frames(10)
	await _enter_klaas_house()
	var box: Variant = await _talk_to_klaas()
	box.choose(0)
	box.choose(1)
	_check(box.get_current_line().id == &"q5_early", "Klaas already noticed the quiet in the Bingo Club")
	box.choose(0)
	box.choose(0)
	_check(_quests.get_status(QUEST) == 2 and _state.has_gear(&"crossbow"), "a boss beaten early still gives the reward and the crossbow")
	await _press(&"pause")


func _hit(target: Variant, damage: int) -> void:
	target.get_node("Hurtbox").receive_hit(load("res://scripts/components/hit_data.gd").new(damage, _player(), null))


func _wait_for_mode(boss: Variant, mode: int) -> void:
	for i: int in 600:
		if boss.mode == mode:
			return
		await physics_frame


func _count_with_script(script_file: String) -> int:
	var count: int = 0
	for node: Node in _main.get_world().find_children("*", "", true, false):
		if node.get_script() != null and node.get_script().resource_path.ends_with(script_file) and not node.is_queued_for_deletion():
			count += 1
	return count


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


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS ", description)
	else:
		_failures += 1
		printerr("FAIL ", description)
