extends SceneTree
## Headless check: loads every scene, script, shader and resource in the
## project and instantiates every scene, so parse and load errors show up.
## Run: godot --headless --path . -s res://tests/check_resources.gd

const EXTENSIONS: PackedStringArray = ["tscn", "tres", "gd", "gdshader"]

var _failures: int = 0


func _initialize() -> void:
	var paths: PackedStringArray = []
	_collect("res://", paths)
	for path: String in paths:
		_check(path)
	print("check_resources: %d files checked, %d failed" % [paths.size(), _failures])
	quit(1 if _failures > 0 else 0)


func _collect(dir_path: String, paths: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	for file_name: String in dir.get_files():
		if file_name.get_extension() in EXTENSIONS:
			paths.append(dir_path.path_join(file_name))
	for sub_name: String in dir.get_directories():
		var sub_path: String = dir_path.path_join(sub_name)
		# Godot skips folders with a .gdignore or their own project.godot.
		if FileAccess.file_exists(sub_path.path_join(".gdignore")):
			continue
		if FileAccess.file_exists(sub_path.path_join("project.godot")):
			continue
		_collect(sub_path, paths)


func _check(path: String) -> void:
	var resource: Resource = load(path)
	if resource == null:
		_fail(path, "could not be loaded")
		return
	if resource is GDScript and not (resource as GDScript).can_instantiate():
		_fail(path, "script has errors")
	elif resource is PackedScene:
		var instance: Node = (resource as PackedScene).instantiate()
		if instance == null:
			_fail(path, "could not be instantiated")
		else:
			instance.free()


func _fail(path: String, reason: String) -> void:
	_failures += 1
	printerr("FAIL %s: %s" % [path, reason])
