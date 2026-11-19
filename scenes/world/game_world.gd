class_name GameWorld
extends Node3D
## Root of a playable world: the open world of Elst or a dungeon. Knows its
## name and spawn points. On its own (in a test, or run with F6) it brings the
## player back after dying; inside Main, dying loads the last save instead.

## Name shown when the player arrives, for example "Elst" or "Station Elst".
@export var location_name: String = ""
## Spawn point (a Marker3D in the spawn_points group) for the start and after dying.
@export var default_spawn: StringName = &"Start"
@export var respawn_delay: float = 3.0
## Save automatically when the player walks in, as for dungeons.
@export var autosave_on_enter: bool = false
## Id for quest steps that wait until the player reaches this world.
@export var location_id: StringName
## Gear handed over when this world loads and the player lacks it. Meant for
## test scenes such as the arena, where you want a sword straight away.
@export var test_gear: Array[ItemData] = []

## Main turns this off, because it loads the last save after dying.
var respawn_on_death: bool = true


func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)
	for item: ItemData in test_gear:
		if not GameState.has_gear(item.id):
			GameState.add_gear(item)


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


## The QuestMarker for target [param target_id] in this world that is nearest
## to the player, or null.
func find_quest_marker(target_id: StringName) -> QuestMarker:
	var player: Player = get_player()
	var nearest: QuestMarker = null
	var nearest_distance: float = INF
	for node: Node in get_tree().get_nodes_in_group(&"quest_markers"):
		var marker: QuestMarker = node as QuestMarker
		if marker == null or target_id not in marker.ids or not is_ancestor_of(marker) or marker.is_queued_for_deletion():
			continue
		var distance: float = 0.0 if player == null else player.global_position.distance_squared_to(marker.global_position)
		if distance < nearest_distance:
			nearest = marker
			nearest_distance = distance
	return nearest


## Puts the player at the spawn point [param spawn_id], or at the default one.
func place_player(spawn_id: StringName) -> void:
	var spawn: Marker3D = get_spawn(spawn_id)
	if spawn == null:
		spawn = get_spawn(default_spawn)
	var player: Player = get_player()
	if spawn != null and player != null:
		player.teleport(spawn.global_transform)


## Brings the player back to life at the default spawn point.
func respawn_player() -> void:
	var player: Player = get_player()
	var spawn: Marker3D = get_spawn(default_spawn)
	if player != null and spawn != null:
		player.respawn(spawn.global_transform)


func _on_player_died() -> void:
	if not respawn_on_death:
		return
	await get_tree().create_timer(respawn_delay).timeout
	if is_inside_tree():
		respawn_player()
