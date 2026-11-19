extends Node
## Saving and loading as in Skyrim: named saves from the pause menu, one
## quicksave (F5, loaded with F9) and three autosaves that take turns. A save
## is a JSON file in save_dir with a small screenshot next to it. It holds
## GameState, QuestManager, the current world scene and the data of every node
## in the persist group (save_data() / load_data()). Main does the scene
## switch when a save loads.

enum SaveType { MANUAL, QUICK, AUTO }

## Bump this when the save format changes, and convert old saves in _migrate().
const SAVE_VERSION: int = 1
const PERSIST_GROUP: StringName = &"persist"
const QUICKSAVE_ID: String = "quicksave"
const AUTOSAVE_SLOTS: int = 3
const THUMBNAIL_SIZE: Vector2i = Vector2i(192, 108)
const TYPE_NAMES: Dictionary = {SaveType.MANUAL: "manual", SaveType.QUICK: "quick", SaveType.AUTO: "auto"}

## Folder for the save files. Tests point this somewhere else.
var save_dir: String = "user://saves/"
## The world being played, set by Main. Null while in the main menu.
var world: GameWorld


## Writes a save. [param save_name] names a manual save, and [param replace_id]
## overwrites an existing manual save instead of making a new one.
func save_game(type: SaveType, save_name: String = "", replace_id: String = "") -> bool:
	if not can_save():
		EventBus.message_requested.emit("Je kunt nu niet opslaan.")
		return false
	var id: String = replace_id if not replace_id.is_empty() else _new_id(type)
	if not _write(id, _collect(type, save_name)):
		EventBus.message_requested.emit("Opslaan is mislukt.")
		return false
	_save_thumbnail(id)
	EventBus.saves_changed.emit()
	return true


## False during a boss fight, a cutscene, a fall, death or a scene change.
func can_save() -> bool:
	if world == null or not is_instance_valid(world) or GameState.is_saving_blocked():
		return false
	var player: Player = world.get_player()
	return player != null and not player.health.is_dead() and player.is_on_floor()


func quicksave() -> void:
	if save_game(SaveType.QUICK):
		EventBus.message_requested.emit("Snel opgeslagen.")


func quickload() -> void:
	if not FileAccess.file_exists(_json_path(QUICKSAVE_ID)):
		EventBus.message_requested.emit("Er is nog geen snelle save.")
		return
	load_save(QUICKSAVE_ID)


func autosave() -> void:
	if save_game(SaveType.AUTO):
		EventBus.message_requested.emit("Automatisch opgeslagen.")


## The metadata of every save, newest first, each with its "id".
func list_saves() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []
	var dir: DirAccess = DirAccess.open(save_dir)
	if dir == null:
		return saves
	for file_name: String in dir.get_files():
		if file_name.get_extension() != "json":
			continue
		var data: Dictionary = _read(file_name.get_basename())
		if data.is_empty():
			continue
		var meta: Dictionary = data.get("meta", {}).duplicate()
		meta["id"] = file_name.get_basename()
		saves.append(meta)
	saves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("unix_time", 0.0)) > float(b.get("unix_time", 0.0)))
	return saves


func has_saves() -> bool:
	return not list_saves().is_empty()


## Id of the newest save of any kind, or "" when there is none.
func get_latest_save_id() -> String:
	var saves: Array[Dictionary] = list_saves()
	return "" if saves.is_empty() else str(saves[0]["id"])


## Reads a save and asks Main to load it. False when the file cannot be used.
func load_save(id: String) -> bool:
	var data: Dictionary = _read(id)
	if data.is_empty() or not data.has("scene"):
		EventBus.message_requested.emit("Deze save kan niet worden geladen.")
		return false
	var version: int = int(data.get("save_version", 0))
	if version > SAVE_VERSION:
		EventBus.message_requested.emit("Deze save komt uit een nieuwere versie van Elst.")
		return false
	EventBus.save_load_requested.emit(_migrate(data, version))
	return true


func delete_save(id: String) -> void:
	for path: String in [_json_path(id), _thumbnail_path(id)]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	EventBus.saves_changed.emit()


## The screenshot of a save, or null when it has none.
func get_thumbnail(id: String) -> Texture2D:
	var path: String = _thumbnail_path(id)
	if not FileAccess.file_exists(path):
		return null
	var image: Image = Image.load_from_file(path)
	return ImageTexture.create_from_image(image) if image != null else null


## Restores GameState and QuestManager. Main calls this before the saved world
## is created, so the world can read them in _ready().
func restore_globals(data: Dictionary) -> void:
	GameState.load_data(data.get("game_state", {}))
	QuestManager.load_data(data.get("quests", {}))


## Gives every saved node in [param restored_world] its data back.
func restore_world(restored_world: GameWorld, data: Dictionary) -> void:
	var nodes: Dictionary = data.get("nodes", {})
	for key: String in nodes:
		var node: Node = restored_world.get_node_or_null(NodePath(key))
		if node != null and node.has_method("load_data"):
			node.call("load_data", nodes[key])


func _collect(type: SaveType, save_name: String) -> Dictionary:
	var nodes: Dictionary = {}
	for node: Node in get_tree().get_nodes_in_group(PERSIST_GROUP):
		if world.is_ancestor_of(node):
			nodes[String(world.get_path_to(node))] = node.call("save_data")
	var location: String = GameState.current_location if not GameState.current_location.is_empty() else world.location_name
	return {
		"save_version": SAVE_VERSION,
		"meta": {
			"type": TYPE_NAMES[type],
			"name": save_name,
			"unix_time": Time.get_unix_time_from_system(),
			"date": Time.get_datetime_string_from_system(false, true),
			"location": location,
			"play_time": GameState.play_time,
		},
		"scene": world.scene_file_path,
		"game_state": GameState.save_data(),
		"quests": QuestManager.save_data(),
		"nodes": nodes,
	}


## Converts a save from an older format to the current one.
func _migrate(data: Dictionary, _from_version: int) -> Dictionary:
	# Version 1 is the first format, so there is nothing to convert yet.
	data["save_version"] = SAVE_VERSION
	return data


func _new_id(type: SaveType) -> String:
	match type:
		SaveType.QUICK:
			return QUICKSAVE_ID
		SaveType.AUTO:
			# Use a free slot, or else overwrite the oldest autosave.
			var oldest_id: String = ""
			var oldest_time: float = INF
			for slot: int in range(1, AUTOSAVE_SLOTS + 1):
				var id: String = "autosave_%d" % slot
				var data: Dictionary = _read(id)
				if data.is_empty():
					return id
				var time: float = float(data.get("meta", {}).get("unix_time", 0.0))
				if time < oldest_time:
					oldest_time = time
					oldest_id = id
			return oldest_id
		_:
			return "manual_%d" % int(Time.get_unix_time_from_system() * 1000.0)


func _write(id: String, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(save_dir)
	# Write to a temporary file first, so a crash never leaves half a save.
	var temp_path: String = _json_path(id) + ".tmp"
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("Cannot write %s (error %d)." % [temp_path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return DirAccess.rename_absolute(temp_path, _json_path(id)) == OK


func _read(id: String) -> Dictionary:
	var path: String = _json_path(id)
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _save_thumbnail(id: String) -> void:
	# Without a renderer (headless tests) there is no picture to take.
	if DisplayServer.get_name() == "headless":
		return
	var image: Image = world.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return
	image.resize(THUMBNAIL_SIZE.x, THUMBNAIL_SIZE.y, Image.INTERPOLATE_BILINEAR)
	image.save_png(_thumbnail_path(id))


func _json_path(id: String) -> String:
	return save_dir.path_join(id + ".json")


func _thumbnail_path(id: String) -> String:
	return save_dir.path_join(id + ".png")
