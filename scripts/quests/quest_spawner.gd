class_name QuestSpawner
extends Node3D
## Spawns an enemy at each Marker3D child while a quest is at one step, such
## as the practice fight of the tutorial. Coming back to the world during that
## step spawns them again.

@export var quest_id: StringName
@export var step_id: StringName
@export var enemy_scene: PackedScene

var _has_spawned: bool = false


func _ready() -> void:
	EventBus.quest_updated.connect(_on_quest_updated.unbind(1))
	_on_quest_updated.call_deferred()


func _on_quest_updated() -> void:
	var step: QuestStep = QuestManager.get_current_step(quest_id)
	if step == null or step.id != step_id:
		_has_spawned = false
		return
	if _has_spawned:
		return
	_has_spawned = true
	for child: Node in get_children():
		var spot: Marker3D = child as Marker3D
		if spot != null:
			var enemy: Node3D = enemy_scene.instantiate()
			add_child(enemy)
			enemy.global_transform = spot.global_transform
