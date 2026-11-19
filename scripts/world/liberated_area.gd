class_name LiberatedArea
extends Node3D
## A part of a world that changes once it is liberated. While it is occupied,
## the children of its Occupied node are there (patrols, for example). Once
## [member liberated_by_flag] is set they are gone for good and the children of
## its Liberated node (villagers, a warm light) appear. The flag is a normal
## GameState flag, so the change survives saving and loading.

## The GameState flag that liberates this area, such as a beaten boss.
@export var liberated_by_flag: StringName

var _occupied: Node3D
var _liberated: Node3D


func _ready() -> void:
	_occupied = get_node_or_null(^"Occupied") as Node3D
	_liberated = get_node_or_null(^"Liberated") as Node3D
	EventBus.flag_set.connect(_on_flag_set)
	_apply()


func is_liberated() -> bool:
	return GameState.has_flag(liberated_by_flag)


func _on_flag_set(flag: StringName) -> void:
	if flag == liberated_by_flag:
		_apply()


func _apply() -> void:
	var liberated: bool = is_liberated()
	if liberated and _occupied != null:
		_occupied.queue_free()
		_occupied = null
	if _liberated != null:
		_liberated.visible = liberated
		_liberated.process_mode = Node.PROCESS_MODE_INHERIT if liberated else Node.PROCESS_MODE_DISABLED
