class_name InventoryMenu
extends Control
## The inventory (Tab): worn gear per slot, all owned gear to swap, the
## potions, the gold and the Inwijding level.

signal closed

const SLOT_NAMES: Dictionary = {&"sword": "Zwaard", &"armor": "Pantser", &"crossbow": "Kruisboog"}

@onready var _info_label: Label = %InfoLabel
@onready var _slots: VBoxContainer = %Slots
@onready var _gear_list: VBoxContainer = %GearList
@onready var _potion_list: VBoxContainer = %PotionList
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(close)
	EventBus.inventory_changed.connect(_on_state_changed)
	EventBus.equipment_changed.connect(_on_state_changed)
	hide()


func open() -> void:
	_rebuild()
	show()
	_back_button.grab_focus()


func close() -> void:
	hide()
	closed.emit()


func _rebuild() -> void:
	_info_label.text = "%d goud  ·  Inwijding %d/%d  ·  %d/%d drankjes" % [GameState.gold, GameState.inwijding,
		GameState.MAX_INWIJDING, GameState.get_potion_count(), GameState.MAX_POTIONS]
	for list: VBoxContainer in [_slots, _gear_list, _potion_list]:
		for child: Node in list.get_children():
			list.remove_child(child)
			child.queue_free()
	for slot: StringName in SLOT_NAMES:
		var worn: ItemData = GameState.get_equipped(slot)
		var line: Label = Label.new()
		line.text = "%s:  %s" % [SLOT_NAMES[slot], "%s (%s)" % [worn.display_name, worn.describe()] if worn != null else "—"]
		_slots.add_child(line)
	for id: StringName in GameState.owned_gear:
		var item: ItemData = ItemCatalog.get_item(id)
		if item == null:
			continue
		var row: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		label.text = "%s (%s)" % [item.display_name, item.describe()]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var button: Button = Button.new()
		var worn: bool = GameState.is_equipped(item)
		button.text = "Gedragen" if worn else "Aantrekken"
		button.disabled = worn
		button.custom_minimum_size = Vector2(150, 0)
		button.pressed.connect(GameState.equip.bind(item))
		row.add_child(button)
		_gear_list.add_child(row)
	for id: StringName in GameState.inventory:
		var potion: ItemData = ItemCatalog.get_item(id)
		if potion != null:
			var line: Label = Label.new()
			line.text = "%s ×%d (%s)" % [potion.display_name, GameState.inventory[id], potion.describe()]
			_potion_list.add_child(line)
	if GameState.inventory.is_empty():
		var none: Label = Label.new()
		none.text = "Geen drankjes of pijlen. Klaas verkoopt ze."
		none.modulate = Color(1, 1, 1, 0.6)
		_potion_list.add_child(none)


func _on_state_changed() -> void:
	if visible:
		_rebuild()
