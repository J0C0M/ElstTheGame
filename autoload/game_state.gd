extends Node
## Global game state: gold, items, Inwijding, liberated areas, the church
## doors, story flags and play time. SaveManager stores it in every save file.

## The most potions the player can carry.
const MAX_POTIONS: int = 10

## Name of the place the player is in, for the save metadata.
var current_location: String = ""
var gold: int = 0
## Bond with Klaas, from 0 to 6.
var inwijding: int = 0
var liberated_areas: Array[StringName] = []
var church_open: bool = false
## Seconds played in this game, counted by Main while the game runs.
var play_time: float = 0.0

## Item id and how many the player carries. Gear arrives in Phase 5.
var inventory: Dictionary[StringName, int] = {}

## World and story flags, such as an opened chest or a destroyed generator.
var _flags: Dictionary[StringName, bool] = {}
## Reasons that currently forbid saving, such as a boss fight or a cutscene.
var _save_blockers: Dictionary[StringName, bool] = {}


## Back to the start of a new game.
func reset() -> void:
	current_location = ""
	gold = 0
	inwijding = 0
	liberated_areas.clear()
	church_open = false
	play_time = 0.0
	inventory.clear()
	_flags.clear()
	_save_blockers.clear()
	EventBus.gold_changed.emit(gold)
	EventBus.inventory_changed.emit()


func add_gold(amount: int) -> void:
	gold += amount
	EventBus.gold_changed.emit(gold)


## Adds up to [param count] of [param item] and returns how many fitted.
## Potions stop at MAX_POTIONS.
func add_item(item: ItemData, count: int = 1) -> int:
	var fits: int = count
	if item.type == ItemData.ItemType.CONSUMABLE:
		fits = clampi(MAX_POTIONS - get_potion_count(), 0, count)
	if fits > 0:
		inventory[item.id] = get_item_count(item.id) + fits
		EventBus.inventory_changed.emit()
	return fits


func get_item_count(id: StringName) -> int:
	return inventory.get(id, 0)


func get_potion_count() -> int:
	var total: int = 0
	for id: StringName in inventory:
		var item: ItemData = ItemCatalog.get_item(id)
		if item != null and item.type == ItemData.ItemType.CONSUMABLE:
			total += inventory[id]
	return total


func set_flag(flag: StringName, value: bool = true) -> void:
	if value:
		_flags[flag] = true
	else:
		_flags.erase(flag)


func has_flag(flag: StringName) -> bool:
	return _flags.has(flag)


## Forbids saving until unblock_saving() is called with the same reason.
func block_saving(reason: StringName) -> void:
	_save_blockers[reason] = true


func unblock_saving(reason: StringName) -> void:
	_save_blockers.erase(reason)


func is_saving_blocked() -> bool:
	return not _save_blockers.is_empty()


func save_data() -> Dictionary:
	return {
		"current_location": current_location,
		"gold": gold,
		"inwijding": inwijding,
		"liberated_areas": Array(liberated_areas).map(func(area: StringName) -> String: return String(area)),
		"church_open": church_open,
		"play_time": play_time,
		"inventory": _inventory_as_strings(),
		"flags": _flags.keys().map(func(flag: StringName) -> String: return String(flag)),
	}


func load_data(data: Dictionary) -> void:
	reset()
	current_location = str(data.get("current_location", ""))
	gold = int(data.get("gold", 0))
	inwijding = int(data.get("inwijding", 0))
	for area: Variant in data.get("liberated_areas", []):
		liberated_areas.append(StringName(str(area)))
	church_open = bool(data.get("church_open", false))
	play_time = float(data.get("play_time", 0.0))
	var saved_inventory: Dictionary = data.get("inventory", {})
	for id: String in saved_inventory:
		inventory[StringName(id)] = int(saved_inventory[id])
	for flag: Variant in data.get("flags", []):
		_flags[StringName(str(flag))] = true
	EventBus.gold_changed.emit(gold)
	EventBus.inventory_changed.emit()


func _inventory_as_strings() -> Dictionary:
	var items: Dictionary = {}
	for id: StringName in inventory:
		items[String(id)] = inventory[id]
	return items
