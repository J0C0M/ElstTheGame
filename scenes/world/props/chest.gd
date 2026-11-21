class_name Chest
extends StaticBody3D
## A chest the player opens with E. It drops its loot once. Being open is a
## GameState flag, so the chest stays open after saving and loading.

@export var loot: LootTable

var _opened: bool = false

@onready var _lid: Node3D = $LidPivot
@onready var _interactable: Interactable = $Interactable
@onready var _loot_dropper: LootDropper = $LootDropper


func _ready() -> void:
	_loot_dropper.loot = loot
	_interactable.interacted.connect(_on_interacted)
	if GameState.has_flag(get_flag()):
		_open(false)


## The GameState flag of this chest: unique per world scene and node path.
func get_flag() -> StringName:
	var world: Node = get_parent()
	while world != null and not world is GameWorld:
		world = world.get_parent()
	var place: String = String(get_path())
	if world != null:
		place = "%s:%s" % [world.scene_file_path, world.get_path_to(self)]
	return StringName("chest:" + place)


func is_opened() -> bool:
	return _opened


func _on_interacted(_player: Player) -> void:
	if _opened:
		return
	GameState.set_flag(get_flag())
	_open(true)
	_loot_dropper.drop()


func _open(animate: bool) -> void:
	_opened = true
	_interactable.enabled = false
	var open_angle: float = deg_to_rad(110.0)
	if animate:
		AudioManager.play_sfx_at(&"chest", global_position, self)
		create_tween().tween_property(_lid, "rotation:x", open_angle, 0.5).set_trans(Tween.TRANS_BACK)
	else:
		_lid.rotation.x = open_angle
