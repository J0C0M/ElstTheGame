extends SceneTree
## Headless test for the open world: starts the game, checks the start spot,
## the navigation mesh, the locked church, the tornado border and the way in
## and out of every dungeon.
## Run: godot --headless --path . --fixed-fps 60 -s res://tests/test_world.gd
##
## The main script of -s is compiled before the autoloads exist, so project
## classes that use them (Main, Player, GameWorld) are held in Variant here.

const ELST: String = "Elst"
## Door node in Elst, dungeon name, and the spawn point you come back out at.
const DUNGEONS: Array = [
	["SupplyDoor", "Station Elst", "StationExit"],
	["FlatDoor", "Westeraam Getho", "WesteraamExit"],
	["SchoolDoor", "OBC Elst Fort", "OBCExit"],
	["CaveDoor", "Bingo Club Boomer Cave", "BingoExit"],
]

var _failures: int = 0
var _main: Variant
var _messages: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# Entering a dungeon autosaves; keep that away from the player's own saves.
	_use_test_save_dir()
	root.get_node("EventBus").connect("message_requested", func(text: String) -> void: _messages.append(text))
	_main = (load("res://scenes/main/Main.tscn") as PackedScene).instantiate()
	_main.skip_main_menu = true
	root.add_child(_main)
	await _frames(40)
	await _test_start()
	await _test_navigation()
	await _test_locked_church()
	await _test_tornado()
	for dungeon: Array in DUNGEONS:
		await _test_dungeon(dungeon[0], dungeon[1], dungeon[2])
	_use_test_save_dir()
	DirAccess.remove_absolute("user://test_saves/")
	print("test_world: %d failed" % _failures)
	quit(1 if _failures > 0 else 0)


func _test_start() -> void:
	var world: Variant = _main.get_world()
	_check(world.location_name == ELST, "the game starts in Elst")
	var spawn: Node3D = world.get_spawn(&"Start")
	_check(_player().global_position.distance_to(spawn.global_position) < 0.5, "the player starts at Klaas' house")
	_check(root.get_node("GameState").current_location == "Huis van Klaas", "the start spot counts as Huis van Klaas")


func _test_navigation() -> void:
	var region: NavigationRegion3D = _main.get_world().get_node("Navigation")
	var map: RID = region.get_navigation_map()
	var start: Vector3 = _main.get_world().get_spawn(&"Start").global_position
	# The bake and the map update run on threads in real time, while headless
	# frames fly by, so give them real time.
	for i: int in 1000:
		if NavigationServer3D.map_get_closest_point(map, start).distance_to(start) < 2.0:
			break
		OS.delay_msec(10)
		await physics_frame
	_check(region.navigation_mesh.get_polygon_count() > 0, "the navigation mesh is baked")
	for spawn_name: String in ["StationExit", "WesteraamExit", "OBCExit", "BingoExit"]:
		var target: Vector3 = _main.get_world().get_spawn(StringName(spawn_name)).global_position
		var path: PackedVector3Array = NavigationServer3D.map_get_path(map, start, target, true)
		_check(path.size() > 1 and path[path.size() - 1].distance_to(target) < 1.5, "a path leads from Klaas to %s" % spawn_name)


func _test_locked_church() -> void:
	_messages.clear()
	await _stand_at_door("ChurchDoor")
	await _press(&"interact")
	await _frames(5)
	_check(_messages.size() == 1 and "op slot" in _messages[0], "the church door is locked")
	_check(_main.get_world().location_name == ELST, "a locked door does not change the world")


func _test_tornado() -> void:
	_messages.clear()
	_place(Vector3(0, 0, -228), 0.0)
	_act(&"move_forward", true)
	_act(&"sprint", true)
	var furthest: float = 0.0
	for i: int in 180:
		await physics_frame
		furthest = maxf(furthest, _distance_from_centre())
	_act(&"sprint", false)
	_act(&"move_forward", false)
	await _frames(120)
	_check(furthest < 240.0, "the tornado stops the player before the wall")
	_check(_distance_from_centre() < furthest - 3.0, "the wind pushes the player back")
	_check(_messages.size() >= 1 and "tornado" in _messages[0], "a message explains the tornado")
	_place(_main.get_world().get_spawn(&"Start").global_position, 0.0)


func _test_dungeon(door_name: String, dungeon_name: String, exit_spawn: String) -> void:
	_player().health.set_health(73)
	await _stand_at_door(door_name)
	await _press(&"interact")
	await _frames(60)
	var dungeon: Variant = _main.get_world()
	_check(dungeon.location_name == dungeon_name, "the door leads into %s" % dungeon_name)
	_check(_player().global_position.distance_to(dungeon.get_spawn(&"Entrance").global_position) < 0.5,
		"the player arrives at the entrance of %s" % dungeon_name)
	_check(_player().health.current_health == 73, "health carries over into %s" % dungeon_name)
	await _stand_at_door("ExitDoor")
	await _press(&"interact")
	await _frames(60)
	var world: Variant = _main.get_world()
	_check(world.location_name == ELST, "the exit of %s leads back to Elst" % dungeon_name)
	_check(_player().global_position.distance_to(world.get_spawn(StringName(exit_spawn)).global_position) < 0.5,
		"the player comes out at %s" % exit_spawn)


## Points SaveManager at an empty test folder.
func _use_test_save_dir() -> void:
	var save_dir: String = "user://test_saves/"
	root.get_node("SaveManager").save_dir = save_dir
	var dir: DirAccess = DirAccess.open(save_dir)
	if dir != null:
		for file_name: String in dir.get_files():
			dir.remove(file_name)


func _stand_at_door(door_name: String) -> void:
	var door: Node3D = _main.get_world().find_child(door_name, true, false)
	# Doors are used from their -Z side; face the door.
	_place(door.global_position - door.global_basis.z * 1.6, door.global_rotation.y + PI)
	await _frames(5)


func _place(position: Vector3, yaw: float) -> void:
	var player: Variant = _player()
	player.teleport(Transform3D(Basis(Vector3.UP, yaw), position))
	player.camera.yaw = yaw


func _player() -> Variant:
	return _main.get_world().get_player()


func _distance_from_centre() -> float:
	var position: Vector3 = _player().global_position
	return Vector2(position.x, position.z).length()


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
	await physics_frame
	_act(action, false)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS ", description)
	else:
		_failures += 1
		printerr("FAIL ", description)
