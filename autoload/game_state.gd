extends Node
## Global game state: gold, items, gear, Inwijding, liberated areas, the
## church doors, story flags and play time. SaveManager stores it in every
## save file.

## The most potions the player can carry.
const MAX_POTIONS: int = 10
## The highest Inwijding level.
const MAX_INWIJDING: int = 6
## Gear a new game starts with, worn from the start.
const START_GEAR: Array[StringName] = [&"rusty_sword", &"plain_clothes"]
## Selling gear back to Klaas gives this share of its price.
const SELL_RATE: float = 0.4

## Name of the place the player is in, for the save metadata.
var current_location: String = ""
var gold: int = 0
## Bond with Klaas, from 0 to 6.
var inwijding: int = 0
var liberated_areas: Array[StringName] = []
var church_open: bool = false
## Seconds played in this game, counted by Main while the game runs.
var play_time: float = 0.0

## Consumable id (potions) and how many the player carries.
var inventory: Dictionary[StringName, int] = {}
## Ids of the swords, armour and crossbow the player owns.
var owned_gear: Array[StringName] = []
## Equipment slot (sword, armor, crossbow) and the id of the item in it.
var equipped: Dictionary[StringName, StringName] = {}

## World and story flags, such as an opened chest or a destroyed generator.
var _flags: Dictionary[StringName, bool] = {}
## Reasons that currently forbid saving, such as a boss fight or a cutscene.
var _save_blockers: Dictionary[StringName, bool] = {}


func _ready() -> void:
	reset()


## Back to the start of a new game.
func reset() -> void:
	current_location = ""
	gold = 0
	inwijding = 0
	liberated_areas.clear()
	church_open = false
	play_time = 0.0
	inventory.clear()
	owned_gear = START_GEAR.duplicate()
	equipped = {&"sword": &"rusty_sword", &"armor": &"plain_clothes"}
	_flags.clear()
	_save_blockers.clear()
	_emit_all()


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


## Takes [param amount] gold if the player has it.
func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	EventBus.gold_changed.emit(gold)
	return true


## Uses up [param count] of a consumable. False when there are not enough.
func remove_item(id: StringName, count: int = 1) -> bool:
	if get_item_count(id) < count:
		return false
	inventory[id] -= count
	if inventory[id] <= 0:
		inventory.erase(id)
	EventBus.inventory_changed.emit()
	return true


func get_item_count(id: StringName) -> int:
	return inventory.get(id, 0)


func get_potion_count() -> int:
	var total: int = 0
	for id: StringName in inventory:
		var item: ItemData = ItemCatalog.get_item(id)
		if item != null and item.type == ItemData.ItemType.CONSUMABLE:
			total += inventory[id]
	return total


func has_gear(id: StringName) -> bool:
	return id in owned_gear


## The item in an equipment slot (sword, armor or crossbow), or null.
func get_equipped(slot: StringName) -> ItemData:
	return ItemCatalog.get_item(equipped.get(slot, &""))


func is_equipped(item: ItemData) -> bool:
	return equipped.get(item.get_slot(), &"") == item.id


## Adds gear the player found or bought. Gear that beats what the player is
## wearing goes on at once, with a message. False when it was already owned.
func add_gear(item: ItemData) -> bool:
	if has_gear(item.id):
		return false
	owned_gear.append(item.id)
	var current: ItemData = get_equipped(item.get_slot())
	if current == null or item.get_power() > current.get_power():
		equip(item)
		EventBus.message_requested.emit("Je draagt nu: %s" % item.display_name)
	EventBus.inventory_changed.emit()
	return true


func equip(item: ItemData) -> void:
	if not has_gear(item.id):
		return
	equipped[item.get_slot()] = item.id
	EventBus.equipment_changed.emit()


## Sells owned gear that is not being worn, for SELL_RATE of its price.
func sell_gear(item: ItemData) -> bool:
	if not has_gear(item.id) or is_equipped(item) or item.price <= 0:
		return false
	owned_gear.erase(item.id)
	add_gold(get_sell_price(item))
	EventBus.inventory_changed.emit()
	return true


func get_sell_price(item: ItemData) -> int:
	return floori(item.price * SELL_RATE)


## The next better gear the player does not own yet that can turn up as
## loot: the next sword or the next armour, picked at random when both
## exist. Null when there is nothing left to find.
func get_next_gear() -> ItemData:
	var candidates: Array[ItemData] = []
	for slot: StringName in [&"sword", &"armor"]:
		var best_owned: float = -1.0
		for id: StringName in owned_gear:
			var owned: ItemData = ItemCatalog.get_item(id)
			if owned != null and owned.get_slot() == slot:
				best_owned = maxf(best_owned, owned.get_power())
		var next: ItemData = null
		for item: ItemData in ItemCatalog.get_all():
			if item.can_drop and item.get_slot() == slot and not has_gear(item.id) \
					and item.get_power() > best_owned and (next == null or item.get_power() < next.get_power()):
				next = item
		if next != null:
			candidates.append(next)
	return candidates.pick_random() if not candidates.is_empty() else null


## Raises Inwijding to [param level] if it is lower, with a message.
func raise_inwijding(level: int) -> void:
	level = clampi(level, 0, MAX_INWIJDING)
	if level <= inwijding:
		return
	inwijding = level
	EventBus.inwijding_changed.emit(inwijding)
	EventBus.message_requested.emit("Inwijding %d bereikt." % inwijding)


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
		"owned_gear": Array(owned_gear).map(func(id: StringName) -> String: return String(id)),
		"equipped": _equipped_as_strings(),
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
	if data.has("owned_gear"):
		owned_gear.clear()
		for id: Variant in data["owned_gear"]:
			owned_gear.append(StringName(str(id)))
		var saved_equipped: Dictionary = data.get("equipped", {})
		equipped.clear()
		for slot: String in saved_equipped:
			equipped[StringName(slot)] = StringName(str(saved_equipped[slot]))
	for flag: Variant in data.get("flags", []):
		_flags[StringName(str(flag))] = true
	_emit_all()


func _inventory_as_strings() -> Dictionary:
	var items: Dictionary = {}
	for id: StringName in inventory:
		items[String(id)] = inventory[id]
	return items


func _equipped_as_strings() -> Dictionary:
	var slots: Dictionary = {}
	for slot: StringName in equipped:
		slots[String(slot)] = String(equipped[slot])
	return slots


func _emit_all() -> void:
	EventBus.gold_changed.emit(gold)
	EventBus.inventory_changed.emit()
	EventBus.equipment_changed.emit()
	EventBus.inwijding_changed.emit(inwijding)
