extends SceneTree
## Headless test for the quest system: plays Quest 1 (the tutorial) from a new
## game to the reward with simulated input, checks the compass, the HUD
## objective, the questlog, saving and loading in the middle and at the end,
## and a quest that was finished before it was given. Uses its own save folder.
## Run: godot --headless --path . --fixed-fps 60 -s res://tests/test_quests.gd
##
## The main script of -s is compiled before the autoloads exist, so project
## classes that use them (Main, Player, QuestManager) are held in Variant here.

const TEST_SAVE_DIR: String = "user://test_saves/"
const QUEST: StringName = &"q1_tutorial"

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
	await _test_start()
	await _test_talk_to_klaas()
	await _test_movement()
	await _test_sword_and_block()
	await _test_potion_and_save()
	await _test_practice_fight()
	await _test_save_mid_quest()
	await _test_report_and_reward()
	await _test_questlog()
	await _test_finished_early()
	_clear_saves()
	DirAccess.remove_absolute(TEST_SAVE_DIR)
	print("test_quests: %d failed" % _failures)
	quit(1 if _failures > 0 else 0)


func _test_start() -> void:
	_check(_quests.get_status(QUEST) == 1, "a new game starts the tutorial")
	_check(_step() == &"talk_to_klaas", "the first objective is to talk to Klaas")
	await _frames(5)
	_check(_main.get_node("UI/HUD/ObjectiveLabel").visible, "the HUD shows the objective")
	_check(_main.get_node("UI/HUD/Compass").has_target(), "the compass points to Klaas")


func _test_talk_to_klaas() -> void:
	await _stand_at("FrontDoor", 1.6)
	await _press(&"interact")
	await _wait_for_world("Huis van Klaas")
	_check(_main.get_node("UI/HUD/Compass").has_target(), "inside, the compass still points to Klaas")
	_place(Vector3(0, 0, -0.9), 0.0)
	await _frames(10)
	await _press(&"interact")
	var box: Variant = _main.get_node("UI/Menus/DialogueBox")
	for i: int in 6:
		box.choose(0)
	await _frames(5)
	_check(_player().has_sword(), "Klaas hands over a sword")
	_check(_step() == &"move", "talking to Klaas finishes the first objective")
	await _frames(60)
	_check(_count_saves("auto") >= 1, "a finished objective makes an autosave")
	await _stand_at("ExitDoor", 1.6)
	await _press(&"interact")
	await _wait_for_world("Elst")


func _test_movement() -> void:
	_act(&"move_forward", true)
	_act(&"sprint", true)
	await _frames(20)
	_act(&"sprint", false)
	_act(&"move_forward", false)
	await _frames(20)
	await _press(&"jump")
	await _frames(60)
	await _press(&"dodge")
	await _frames(40)
	_check(_step() == &"sword", "sprinting, jumping and dodging finish the movement lesson")


func _test_sword_and_block() -> void:
	var dummy: Variant = _main.get_world().find_child("TrainingDummy", true, false)
	dummy.get_node("Health").take_damage(1000)
	await _frames(5)
	_check(_step() == &"block", "breaking the training dummy finishes the sword lesson")
	var sparring: Variant = _main.get_world().find_child("SparringDummy", true, false)
	var to_dummy: Vector3 = sparring.global_position - _player().global_position
	to_dummy.y = 0.0
	_place(sparring.global_position - to_dummy.normalized() * 2.0, atan2(to_dummy.x, to_dummy.z) + PI)
	_act(&"block_aim", true)
	for i: int in 600:
		await physics_frame
		if _step() != &"block":
			break
	_act(&"block_aim", false)
	_check(_step() == &"potion", "blocking the sparring dummy finishes the block lesson")
	_check(_state.get_potion_count() >= 1, "Klaas gives a potion to practise with")
	_place(_main.get_world().find_child("Garden", true, false).global_position, 0.0)
	await _frames(30)


func _test_potion_and_save() -> void:
	await _press(&"use_potion")
	await _frames(70)
	_check(_step() == &"save", "drinking finishes the potion lesson")
	await _press(&"quicksave")
	await _frames(10)
	_check(_step() == &"fight", "saving finishes the save lesson")


func _test_practice_fight() -> void:
	await _frames(10)
	var fight: Node = _main.get_world().find_child("PracticeFight", true, false)
	var drillers: Array[Node] = []
	for child: Node in fight.get_children():
		if child.is_in_group(&"enemies"):
			drillers.append(child)
	_check(drillers.size() == 2, "two laag drillers appear for the practice fight")
	_player().is_invulnerable = true
	drillers[0].health.take_damage(100)
	await _frames(5)
	_check(_quests.get_step_progress(QUEST) == "1/2", "the HUD counts the kills")
	drillers[1].health.take_damage(100)
	await _frames(5)
	_check(_step() == &"report", "beating both finishes the fight")


func _test_save_mid_quest() -> void:
	await _frames(60)
	root.get_node("SaveManager").quicksave()
	_quests.reset()
	root.get_node("SaveManager").quickload()
	await _wait_for_world("Elst")
	await _frames(10)
	_check(_quests.get_status(QUEST) == 1 and _step() == &"report", "loading brings back the quest at the same step")


func _test_report_and_reward() -> void:
	var gold: int = _state.gold
	var potions: int = _state.get_potion_count()
	await _stand_at("FrontDoor", 1.6)
	await _press(&"interact")
	await _wait_for_world("Huis van Klaas")
	_place(Vector3(0, 0, -0.9), 0.0)
	await _frames(10)
	await _press(&"interact")
	var box: Variant = _main.get_node("UI/Menus/DialogueBox")
	_check(box.get_current_line().id == &"tutorial_report", "Klaas is proud after the practice fight")
	box.choose(0)
	_check(_quests.get_status(QUEST) == 2, "reporting back finishes Quest 1")
	_check(_state.inwijding == 1, "the reward includes Inwijding 1")
	_check(_state.gold == gold + 20, "the reward includes 20 gold")
	_check(_state.get_potion_count() == potions + 2, "the reward includes two potions")
	box.choose(0)
	_check(box.get_current_line().id == &"hub", "then Klaas asks what you want")
	box.choose(0)
	await _frames(2)
	_check(_main.get_node("UI/Menus/ShopMenu").visible, "the shop is open now")
	_main.get_node("UI/Menus/ShopMenu").close()
	await _frames(5)


func _test_questlog() -> void:
	await _press(&"quest_log")
	var log: Variant = _main.get_node("UI/Menus/QuestLog")
	_check(log.visible and paused, "J opens the questlog")
	_check(log.get_node("%QuestTitle").text == "Inleiding", "the questlog shows the finished tutorial")
	await _press(&"quest_log")
	_check(not log.visible and not paused, "J closes the questlog")
	root.get_node("SaveManager").quicksave()
	_quests.reset()
	root.get_node("SaveManager").quickload()
	await _wait_for_world("Huis van Klaas")
	_check(_quests.get_status(QUEST) == 2, "a finished quest stays finished after loading")


func _test_finished_early() -> void:
	var quest: Resource = load("res://scripts/data/quest_data.gd").new()
	quest.id = &"test_early"
	quest.number = 9
	quest.title = "Testquest"
	quest.completion_flag = &"test_boss_beaten"
	quest.reward_gold = 5
	var step: Resource = load("res://scripts/data/quest_step.gd").new()
	step.id = &"beat_boss"
	step.flag = &"never"
	quest.steps.append(step)
	_quests.add_quest(quest)
	var gold: int = _state.gold
	var inwijding: int = _state.inwijding
	_state.set_flag(&"test_boss_beaten")
	_check(_quests.get_status(&"test_early") == 0, "beating a boss does not start its quest")
	_quests.start_quest(&"test_early")
	_check(_quests.get_status(&"test_early") == 2, "a quest done early is finished as soon as it is given")
	_check(_state.gold == gold + 5 and _state.inwijding == inwijding + 1, "the reward still comes")


func _step() -> StringName:
	var step: Variant = _quests.get_current_step(QUEST)
	return step.id if step != null else &""


func _count_saves(save_type: String) -> int:
	var count: int = 0
	for meta: Dictionary in root.get_node("SaveManager").list_saves():
		if meta.get("type") == save_type:
			count += 1
	return count


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
