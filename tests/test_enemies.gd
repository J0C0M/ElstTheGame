extends SceneTree
## Headless test for enemies and loot. In the enemy test room: drillers idle
## and patrol, notice the player and warn each other, attack, take sword hits,
## die and drop gold; the chest opens once and stays open after loading, and
## the enemies come back after loading. In Elst: an enemy gives up the chase,
## walks home and heals. Uses its own save folder.
## Run: godot --headless --path . --fixed-fps 60 -s res://tests/test_enemies.gd
##
## The main script of -s is compiled before the autoloads exist, so project
## classes that use them (Main, Player, Enemy) are held in Variant here.

const TEST_SAVE_DIR: String = "user://test_saves/"

var _failures: int = 0
var _main: Variant
var _kills: Array[StringName] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var saves: Variant = root.get_node("SaveManager")
	saves.save_dir = TEST_SAVE_DIR
	_clear_saves()
	root.get_node("EventBus").connect("enemy_killed", func(enemy_id: StringName) -> void: _kills.append(enemy_id))
	_main = (load("res://scenes/main/Main.tscn") as PackedScene).instantiate()
	_main.skip_main_menu = true
	root.add_child(_main)
	await _frames(40)
	await _wait_for_navigation()
	# A new game starts without a sword; Klaas hands it over in the tutorial.
	root.get_node("GameState").add_gear(load("res://data/items/rusty_sword.tres"))
	await _go_to("res://scenes/world/EnemyTestRoom.tscn", &"Entrance")
	await _test_idle_and_patrol()
	await _test_pack_notices_player()
	await _test_enemies_attack()
	await _test_sword_and_loot()
	await _test_chest()
	await _test_bodies_disappear()
	await _test_load_brings_enemies_back()
	await _go_to("res://scenes/world/Elst.tscn", &"StationExit")
	await _test_give_up_and_heal()
	_clear_saves()
	DirAccess.remove_absolute(TEST_SAVE_DIR)
	print("test_enemies: %d failed" % _failures)
	quit(1 if _failures > 0 else 0)


func _test_idle_and_patrol() -> void:
	var states_seen: Dictionary = {}
	for i: int in 480:
		await physics_frame
		for enemy: Variant in _enemies():
			states_seen[enemy.state_machine.get_state_name()] = true
	_check(states_seen.has(&"Patrol"), "enemies go on patrol")
	_check(not states_seen.has(&"Chase"), "enemies do not chase a player out of sight")


func _test_pack_notices_player() -> void:
	var first: Variant = _enemies()[0]
	_place(first.global_position + Vector3(0, 0, 3), 0.0)
	await _frames(30)
	var chasing: int = 0
	for enemy: Variant in _enemies():
		if enemy.state_machine.get_state_name() in [&"Chase", &"Attack"]:
			chasing += 1
	_check(first.state_machine.get_state_name() in [&"Chase", &"Attack"], "an enemy notices a player nearby")
	_check(chasing == _enemies().size(), "the whole group joins in")


func _test_enemies_attack() -> void:
	var saw_attack: bool = false
	for i: int in 600:
		await physics_frame
		for enemy: Variant in _enemies():
			if enemy.state_machine.get_state_name() == &"Attack":
				saw_attack = true
		if _player().health.current_health < 100:
			break
	_check(saw_attack, "enemies attack")
	_check(_player().health.current_health < 100, "an attack hurts the player")
	_player().is_invulnerable = true


func _test_sword_and_loot() -> void:
	var gold_before: int = root.get_node("GameState").gold
	# Let the stagger from the last hit wear off before swinging.
	for i: int in 120:
		if _player().state_machine.get_state_name() == &"Move":
			break
		await physics_frame
	var target: Variant = _enemies()[0]
	var health_before: int = target.health.current_health
	var to_target: Vector3 = target.global_position - _player().global_position
	_place(target.global_position - to_target.normalized() * 1.3, atan2(to_target.x, to_target.z) + PI)
	await _tap(&"attack")
	await _frames(30)
	_check(target.health.current_health < health_before, "the sword hurts an enemy")
	# Step away, so the coins do not fly to the player before they are counted.
	_place(Vector3(0, 0, 14), PI)
	await _frames(5)
	var enemy_count: int = _enemies().size()
	for enemy: Variant in _enemies():
		enemy.health.take_damage(enemy.health.current_health)
	await _frames(5)
	_check(_kills.size() == enemy_count, "every dead enemy reports its death")
	await _frames(60)
	var piles: Array[Node] = _pickups("gold_pickup.gd")
	_check(piles.size() == enemy_count, "every enemy drops a pile of gold")
	for pile: Node in piles:
		# Picking up one pile can pull in the next before the loop gets there.
		if not is_instance_valid(pile):
			continue
		_place((pile as Node3D).global_position, 0.0)
		await _frames(3)
	var gained: int = root.get_node("GameState").gold - gold_before
	_check(gained >= 3 * enemy_count and gained <= 10 * enemy_count, "the gold lands in the purse (%d)" % gained)


func _test_chest() -> void:
	var chest: Variant = _main.get_world().get_node("Chest")
	# Pick up any coins the enemies left, so only the chest's gold is counted.
	for pile: Node in _pickups("gold_pickup.gd"):
		# Picking up one pile can pull in the next before the loop gets there.
		if not is_instance_valid(pile):
			continue
		_place((pile as Node3D).global_position, 0.0)
		await _frames(5)
	await _frames(10)
	var gold_before: int = root.get_node("GameState").gold
	_place(chest.global_position + chest.global_basis.z * -1.4, chest.global_rotation.y + PI)
	await _frames(5)
	await _tap(&"interact")
	await _frames(60)
	_check(chest.is_opened(), "the chest opens with E")
	for pile: Node in _pickups("gold_pickup.gd"):
		# Picking up one pile can pull in the next before the loop gets there.
		if not is_instance_valid(pile):
			continue
		_place((pile as Node3D).global_position, 0.0)
		await _frames(3)
	var gained: int = root.get_node("GameState").gold - gold_before
	_check(gained >= 20 and gained <= 40, "the chest holds 20 to 40 gold (%d)" % gained)
	await _tap(&"interact")
	await _frames(30)
	_check(_pickups("gold_pickup.gd").is_empty(), "an opened chest gives nothing more")


func _test_bodies_disappear() -> void:
	await _frames(roundi(6.0 * 60.0))
	_check(_enemies().is_empty() and _main.get_world().get_node("Enemies").get_child_count() == 0, "dead bodies sink away")


func _test_load_brings_enemies_back() -> void:
	_place(Vector3(0, 0, 14), PI)
	await _frames(10)
	var gold: int = root.get_node("GameState").gold
	root.get_node("SaveManager").quicksave()
	root.get_node("SaveManager").quickload()
	await _frames(60)
	_check(_enemies().size() == 3, "loading brings the enemies back")
	_check(_main.get_world().get_node("Chest").is_opened(), "an opened chest stays open after loading")
	_check(root.get_node("GameState").gold == gold, "the gold stays after loading")


func _test_give_up_and_heal() -> void:
	var enemy: Variant = _main.get_world().find_child("LowDriller1", true, false)
	_player().is_invulnerable = true
	_place(enemy.global_position + Vector3(0, 0, 3), PI)
	await _frames(20)
	enemy.health.take_damage(10)
	_check(enemy.state_machine.get_state_name() in [&"Chase", &"Attack"], "a hit enemy fights back")
	_place(_main.get_world().get_spawn(&"Start").global_position, 0.0)
	var gave_up: bool = false
	for i: int in 1200:
		await physics_frame
		if enemy.state_machine.get_state_name() == &"Retreat":
			gave_up = true
		if gave_up and enemy.state_machine.get_state_name() == &"Idle":
			break
	_check(gave_up, "an enemy gives up when the player gets away")
	_check(enemy.global_position.distance_to(enemy.home) < 2.0, "it walks back home")
	_check(enemy.health.current_health == enemy.health.max_health, "it heals up at home")


func _go_to(scene_path: String, spawn_id: StringName) -> void:
	# Main ignores a request while a fade is still running, so ask again.
	for attempt: int in 10:
		if _main.get_world() != null and _main.get_world().scene_file_path == scene_path:
			break
		root.get_node("EventBus").world_change_requested.emit(scene_path, spawn_id)
		await _frames(60)
	# The navigation mesh bakes and syncs on threads in real time.
	var map: RID = _main.get_world().get_node("Navigation").get_navigation_map()
	var spot: Vector3 = _player().global_position
	for i: int in 1000:
		if NavigationServer3D.map_get_closest_point(map, spot).distance_to(spot) < 2.0:
			break
		OS.delay_msec(10)
		await physics_frame


## Lets the navigation mesh of the current world finish baking on its thread,
## so it does not compete with the next world for time.
func _wait_for_navigation() -> void:
	var start: int = Time.get_ticks_msec()
	var mesh: NavigationMesh = _main.get_world().get_node("Navigation").navigation_mesh
	while NavigationServer3D.is_baking_navigation_mesh(mesh) or mesh.get_polygon_count() == 0:
		if Time.get_ticks_msec() - start > 20000:
			break
		OS.delay_msec(10)
		await physics_frame
	print("navigation baked after %d ms" % (Time.get_ticks_msec() - start))


func _enemies() -> Array[Node]:
	var alive: Array[Node] = []
	for node: Node in get_nodes_in_group(&"enemies"):
		if _main.get_world().is_ancestor_of(node):
			alive.append(node)
	return alive


func _pickups(script_file: String) -> Array[Node]:
	var found: Array[Node] = []
	for node: Node in _main.get_world().find_children("*", "Area3D", true, false):
		if node.get_script() != null and node.get_script().resource_path.ends_with(script_file) and not node.is_queued_for_deletion():
			found.append(node)
	return found


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


func _tap(action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(3)
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
