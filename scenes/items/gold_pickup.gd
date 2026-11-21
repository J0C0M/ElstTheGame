class_name GoldPickup
extends Pickup
## A small pile of coins.

@export var amount: int = 1


func _collect(_player: Player) -> bool:
	GameState.add_gold(amount)
	EventBus.loot_collected.emit("+%d goud" % amount)
	return true
