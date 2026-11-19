extends SceneTree
## Headless test for Klaas, the shop and the inventory: in through his front
## door, the first conversation up to the Inwijding, buying gear that goes on
## at once and shows on the player, locked items, armour, drinking a potion,
## the inventory on Tab, sleeping, saving and loading the gear, and gear as
## loot. Uses its own save folder.
## Run: godot --headless --path . --fixed-fps 60 -s res://tests/test_klaas.gd
##
## The main script of -s is compiled before the autoloads exist, so project
## classes that use them (Main, Player, GameState) are held in Variant here.

const TEST_SAVE_DIR: String = "user://test_saves/"

var _failures: int = 0
var _main: Variant
var _state: Variant
var _catalog: Variant


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("SaveManager").save_dir = TEST_SAVE_DIR
	_clear_saves()
	_state = root.get_node("GameState")
	_catalog = load("res://scripts/data/item_catalog.gd")
	_main = (load("res://scenes/main/Main.tscn") as PackedScene).instantiate()
	_main.skip_main_menu = true
	root.add_child(_main)
	await _wait_for_world("Elst")
	await _test_front_door()
	await _test_first_conversation()
	await _test_shop()
	await _test_greeting_and_escape()
	await _test_armor_and_potion()
	await _test_inventory_key()
	await _test_sleep()
	await _test_save_keeps_gear()
	await _test_gear_loot()
	_clear_saves()
	DirAccess.remove_absolute(TEST_SAVE_DIR)
	print("test_klaas: %d failed" % _failures)
	quit(1 if _failures > 0 else 0)


func _test_front_door() -> void:
	await _stand_at("FrontDoor", 1.6)
	await _press(&"interact")
	await _wait_for_world("Huis van Klaas")
	_check(_main.get_world().location_name == "Huis van Klaas", "the front door leads into Klaas' house")


func _test_first_conversation() -> void:
	_place(Vector3(0, 0, -0.9), 0.0)
	await _frames(10)
	_check(not _player().has_sword(), "a new game starts without a sword")
	await _press(&"interact")
	var box: Variant = _main.get_node("UI/Menus/DialogueBox")
	_check(box.visible and paused, "talking to Klaas opens a paused conversation")
	_check(box.get_current_line().id == &"first_meeting", "the first talk starts with the first meeting")
	box.choose(0)
	box.choose(0)
	_check(box.get_current_line().id == &"first_3", "the conversation moves on")
	box.choose(0)
	_check(box.get_current_line().id == &"tutorial_1", "a choice leads to its line")
	_check(_state.has_gear(&"rusty_sword"), "Klaas hands over the rusty sword")
	box.choose(0)
	box.choose(0)
	_check(_state.has_flag(&"q1_met_klaas"), "the talk counts for the tutorial")
	box.choose(0)
	await _frames(2)
	_check(not box.visible and not paused, "the conversation ends")
	# Finish the tutorial at once; test_quests plays it through step by step.
	root.get_node("QuestManager").complete_quest(&"q1_tutorial")
	_check(_state.inwijding == 1, "the tutorial reward opens the shop")
	await _frames(30)
	await _press(&"interact")
	_check(box.get_current_line().id == &"greeting", "Klaas greets an old friend differently")
	box.choose(0)
	_check(box.get_current_line().id == &"hub", "after that Klaas asks what you want")
	box.choose(0)
	await _frames(2)
	_check(not box.visible and _main.get_node("UI/Menus/ShopMenu").visible, "the shop choice opens the shop")
	_check(paused, "the game stays paused in the shop")


func _test_shop() -> void:
	var shop: Variant = _main.get_node("UI/Menus/ShopMenu")
	_state.gold = 300
	_check(shop.buy(_item(&"iron_sword")), "buying the iron sword works")
	_check(_state.gold == 220, "it costs 80 gold")
	_check(_state.is_equipped(_item(&"iron_sword")), "a better sword goes on at once")
	await _frames(2)
	_check(_player().sword.damage == 16, "the player now hits with the iron sword")
	var blade: MeshInstance3D = _player().model.get_node("Body/Hips/Torso/ArmR/Hand/Sword/Blade")
	_check(is_equal_approx((blade.mesh as BoxMesh).size.z, 0.95), "the iron sword shows on the player")
	_check(not shop.buy(_item(&"steel_sword")), "the steel sword waits for Inwijding 3")
	_check(shop.buy(_item(&"leather_armor")), "buying leather armour works")
	_check(_player().model.get_node("Body/Hips/Torso/ArmorChest").visible, "the leather armour shows on the player")
	_check(shop.buy(_item(&"small_potion")), "buying a potion works")
	_check(not shop.sell(_item(&"iron_sword")), "worn gear cannot be sold")
	_check(not shop.sell(_item(&"rusty_sword")), "the rusty sword is worth nothing")
	shop.close()
	await _frames(2)
	_check(not paused, "closing the shop unpauses the game")


func _test_greeting_and_escape() -> void:
	await _press(&"interact")
	var box: Variant = _main.get_node("UI/Menus/DialogueBox")
	_check(box.visible, "Klaas talks again")
	await _press(&"pause")
	_check(not box.visible and not paused, "Esc ends the conversation")


func _test_armor_and_potion() -> void:
	_player().health.set_health(100)
	var attacker: Node3D = Node3D.new()
	_main.get_world().add_child(attacker)
	attacker.global_position = _player().global_position + _player().get_forward() * -2.0
	var hit: Variant = load("res://scripts/components/hit_data.gd").new(10, attacker, null)
	_player().hurtbox.receive_hit(hit)
	_check(_player().health.current_health == 91, "leather armour takes 15% off a hit")
	attacker.queue_free()
	await _frames(40)
	_player().health.set_health(30)
	var potions_before: int = _state.get_potion_count()
	await _press(&"use_potion")
	await _frames(60)
	_check(_player().health.current_health == 70, "Q drinks a potion for 40 HP")
	_check(_state.get_potion_count() == potions_before - 1, "the potion is used up")


func _test_inventory_key() -> void:
	await _press(&"inventory")
	var inventory: Variant = _main.get_node("UI/Menus/InventoryMenu")
	_check(inventory.visible and paused, "Tab opens the inventory")
	await _press(&"inventory")
	_check(not inventory.visible and not paused, "Tab closes it again")


func _test_sleep() -> void:
	_player().health.set_health(40)
	var newest_before: float = _newest_autosave_time()
	var bed: Node3D = _main.get_world().find_child("Bed", true, false)
	_place(bed.global_position + Vector3(0, 0, 2.0), 0.0)
	await _frames(5)
	await _press(&"interact")
	await _frames(70)
	_check(_player().health.current_health == 100, "sleeping heals")
	_check(_newest_autosave_time() > newest_before, "sleeping makes an autosave")


func _test_save_keeps_gear() -> void:
	root.get_node("SaveManager").quicksave()
	_state.equip(_item(&"rusty_sword"))
	_state.inwijding = 0
	root.get_node("SaveManager").quickload()
	await _frames(60)
	_check(_state.is_equipped(_item(&"iron_sword")) and _state.is_equipped(_item(&"leather_armor")), "loading brings back the worn gear")
	_check(_state.inwijding == 1 and _state.has_flag(&"q1_met_klaas"), "loading brings back the Inwijding")
	_check(_player().sword.damage == 16, "the loaded player uses the saved sword")


func _test_gear_loot() -> void:
	var table: Resource = load("res://scripts/data/loot_table.gd").new()
	var entry: Resource = load("res://scripts/data/loot_entry.gd").new()
	entry.kind = 1
	entry.chance = 1.0
	table.entries.append(entry)
	var dropper: Node3D = load("res://scripts/components/loot_dropper.gd").new()
	dropper.loot = table
	_main.get_world().add_child(dropper)
	dropper.global_position = _player().global_position + Vector3(0, 0, -1)
	dropper.drop()
	await _frames(90)
	var found_better: bool = _state.has_gear(&"steel_sword") or _state.has_gear(&"iron_armor")
	_check(found_better, "a gear drop is the next sword or armour the player lacks")
	_check(_state.is_equipped(_item(&"steel_sword")) or _state.is_equipped(_item(&"iron_armor")), "found gear that is better goes on")


func _newest_autosave_time() -> float:
	var newest: float = 0.0
	for meta: Dictionary in root.get_node("SaveManager").list_saves():
		if meta.get("type") == "auto":
			newest = maxf(newest, float(meta.get("unix_time", 0.0)))
	return newest


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


func _item(id: StringName) -> Variant:
	return _catalog.get_item(id)


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
		await process_frame


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
