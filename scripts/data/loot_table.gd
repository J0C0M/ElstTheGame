class_name LootTable
extends Resource
## What an enemy or a chest drops: gold within a range, and items that each
## have their own chance.

@export var gold_min: int = 0
@export var gold_max: int = 0
@export var entries: Array[LootEntry] = []


func roll_gold() -> int:
	return randi_range(gold_min, gold_max)


## The entries that dropped this time.
func roll_items() -> Array[LootEntry]:
	var dropped: Array[LootEntry] = []
	for entry: LootEntry in entries:
		if entry.item != null and randf() < entry.chance:
			dropped.append(entry)
	return dropped
