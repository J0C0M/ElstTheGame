class_name LootEntry
extends Resource
## One item that may drop from a LootTable, with its chance.

@export var item: ItemData
## Chance from 0.0 to 1.0 that this entry drops.
@export_range(0.0, 1.0) var chance: float = 0.0
@export var count: int = 1
