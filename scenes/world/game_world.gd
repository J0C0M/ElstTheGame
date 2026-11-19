class_name GameWorld
extends Node3D
## Root of a playable world: the open world of Elst or a dungeon. Knows its
## name and spawn points, and brings the player back after dying. Phase 3
## replaces the respawn with loading the last save.

## Name shown when the player arrives, for example "Elst" or "Station Elst".
@export var location_name: String = ""
## Spawn point (a Marker3D in the spawn_points group) for the start and after dying.
@export var default_spawn: StringName = &"Start"
@export var respawn_delay: float = 3.0
## Save automatically when the player walks in, as for dungeons.
@export var autosave_on_enter: bool = false


func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)


func get_player() -> Player:
	for node: Node in get_tree().get_nodes_in_group(&"player"):
		if is_ancestor_of(node):
			return node as Player
	return null


func get_spawn(spawn_id: StringName) -> Marker3D:
	for node: Node in get_tree().get_nodes_in_group(&"spawn_points"):
		if node.name == spawn_id and is_ancestor_of(node):
			return node as Marker3D
	return null


## Puts the player at the spawn point [param spawn_id], or at the default one.
func place_player(spawn_id: StringName) -> void:
	var spawn: Marker3D = get_spawn(spawn_id)
	if spawn == null:
		spawn = get_spawn(default_spawn)
	var player: Player = get_player()
	if spawn != null and player != null:
		player.teleport(spawn.global_transform)


func _on_player_died() -> void:
	await get_tree().create_timer(respawn_delay).timeout
	if not is_inside_tree():
		return
	var player: Player = get_player()
	var spawn: Marker3D = get_spawn(default_spawn)
	if player != null and spawn != null:
		player.respawn(spawn.global_transform)
