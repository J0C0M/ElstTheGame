class_name LootEntry
extends Resource
## One thing that may drop from a LootTable, with its chance.

enum Kind {
	## Drops [member item].
	ITEM,
	## Drops the next better sword or armour the player does not own yet, so a
	## find is never worse than what the player has. Nothing if all is found.
	NEXT_GEAR,
}

@export var kind: Kind = Kind.ITEM
@export var item: ItemData
## Chance from 0.0 to 1.0 that this entry drops.
@export_range(0.0, 1.0) var chance: float = 0.0
@export var count: int = 1
