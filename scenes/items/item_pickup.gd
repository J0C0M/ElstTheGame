class_name ItemPickup
extends Pickup
## An item on the ground, such as a healing potion.

@export var item: ItemData
@export var count: int = 1


func _collect(_player: Player) -> bool:
	var taken: int = GameState.add_item(item, count)
	if taken <= 0:
		EventBus.message_requested.emit("Je kunt niet meer drankjes meenemen.")
		return false
	count -= taken
	EventBus.loot_collected.emit("%s opgepakt" % item.display_name)
	return count <= 0
