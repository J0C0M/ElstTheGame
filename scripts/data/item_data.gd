class_name ItemData
extends Resource
## An item: a sword, armour, the crossbow or a consumable. One .tres per item
## in res://data/items/. Values come from the GDD.

enum ItemType { SWORD, ARMOR, CROSSBOW, CONSUMABLE }

@export var id: StringName
## Name the player sees.
@export var display_name: String = ""
@export var type: ItemType = ItemType.SWORD
## Damage per hit for swords, per arrow for the crossbow.
@export var damage: int = 0
## Share of incoming damage armour removes.
@export_range(0.0, 1.0) var damage_reduction: float = 0.0
## HP a potion restores.
@export var heal_amount: int = 0
## Price at Klaas' shop. 0 means it is not for sale.
@export var price: int = 0
## Inwijding level at which Klaas starts selling it.
@export var required_inwijding: int = 0
## Can turn up as loot in chests and from bosses.
@export var can_drop: bool = false

@export_group("Looks")
## Colour of the blade or the armour on the player.
@export var model_color: Color = Color.WHITE
## Length of a sword's blade in metres.
@export var blade_length: float = 0.0
## How much armour shows: 1 a vest, 2 also shoulder pads, 3 also a helmet.
@export var armor_tier: int = 0


func is_gear() -> bool:
	return type != ItemType.CONSUMABLE


## The equipment slot this item goes in: sword, armor or crossbow.
func get_slot() -> StringName:
	match type:
		ItemType.SWORD:
			return &"sword"
		ItemType.ARMOR:
			return &"armor"
		ItemType.CROSSBOW:
			return &"crossbow"
		_:
			return &""


## How good the item is, for comparing gear in the same slot.
func get_power() -> float:
	return damage_reduction if type == ItemType.ARMOR else float(damage)


## Short description of what it does, for menus.
func describe() -> String:
	match type:
		ItemType.ARMOR:
			return "%d%% minder schade" % roundi(damage_reduction * 100.0)
		ItemType.CONSUMABLE:
			return "+%d HP" % heal_amount
		_:
			return "%d schade" % damage
