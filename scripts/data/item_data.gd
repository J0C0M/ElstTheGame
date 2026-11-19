class_name ItemData
extends Resource
## An item: a sword, armour, the crossbow or a consumable. One .tres per item
## in res://data/items/.

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
