class_name FlagGate
extends StaticBody3D
## A gate that stays shut until a GameState flag is set, such as the gate of
## Amber's arena that opens when Klaas is ready. A boss can still close it
## with set_open() while the fight lasts.

@export var open_flag: StringName


func _ready() -> void:
	EventBus.flag_set.connect(_on_flag_set)
	set_open(GameState.has_flag(open_flag))


func set_open(open: bool) -> void:
	visible = not open
	for child: Node in get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).set_deferred(&"disabled", open)


func _on_flag_set(flag: StringName) -> void:
	if flag == open_flag:
		set_open(true)
