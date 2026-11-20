class_name LootDropper
extends Node3D
## Drops the loot of a LootTable at its own position: one pile of gold and the
## items that came up. The pickups go into the world root, so they stay when
## the enemy or chest that dropped them is gone.

const GOLD_SCENE: PackedScene = preload("res://scenes/items/GoldPickup.tscn")
const ITEM_SCENE: PackedScene = preload("res://scenes/items/ItemPickup.tscn")

@export var loot: LootTable


func drop() -> void:
	if loot == null:
		return
	var parent: Node = _drop_parent()
	var gold: int = loot.roll_gold()
	if gold > 0:
		var pile: GoldPickup = GOLD_SCENE.instantiate()
		pile.amount = gold
		_spawn.call_deferred(pile, parent)
	for entry: LootEntry in loot.roll_items():
		var item: ItemData = entry.item
		if entry.kind == LootEntry.Kind.NEXT_GEAR:
			item = GameState.get_next_gear()
		if item == null:
			continue
		var pickup: ItemPickup = ITEM_SCENE.instantiate()
		pickup.item = item
		pickup.count = entry.count
		_spawn.call_deferred(pickup, parent)


# Deferred: a kill happens inside a physics callback, where new areas may not
# enter the world yet.
func _spawn(pickup: Pickup, parent: Node) -> void:
	parent.add_child(pickup)
	pickup.global_position = global_position
	var angle: float = randf() * TAU
	pickup.launch(Vector3(cos(angle) * 1.5, 4.0, sin(angle) * 1.5))


func _drop_parent() -> Node:
	var node: Node = get_parent()
	while node != null and not node is GameWorld:
		node = node.get_parent()
	return node if node != null else owner.get_parent()
