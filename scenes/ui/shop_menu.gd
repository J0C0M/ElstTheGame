class_name ShopMenu
extends Control
## Klaas' shop. Lists what he sells, locked until the Inwijding level of each
## item, and buys back gear the player is not wearing for 40% of its price.

signal closed

const TYPE_ORDER: Dictionary = {
	ItemData.ItemType.SWORD: 0, ItemData.ItemType.ARMOR: 1,
	ItemData.ItemType.CROSSBOW: 2, ItemData.ItemType.CONSUMABLE: 3,
}

@onready var _gold_label: Label = %GoldLabel
@onready var _inwijding_label: Label = %InwijdingLabel
@onready var _buy_list: VBoxContainer = %BuyList
@onready var _sell_list: VBoxContainer = %SellList
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(close)
	EventBus.gold_changed.connect(_on_state_changed.unbind(1))
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


## Buys [param item] if the shop allows it. True when it was bought.
func buy(item: ItemData) -> bool:
	if not _why_not_buyable(item).is_empty() or not GameState.spend_gold(item.price):
		return false
	if item.is_gear():
		GameState.add_gear(item)
	else:
		GameState.add_item(item)
	EventBus.message_requested.emit("Gekocht: %s" % item.display_name)
	return true


func sell(item: ItemData) -> bool:
	var price: int = GameState.get_sell_price(item)
	if not GameState.sell_gear(item):
		return false
	EventBus.message_requested.emit("Verkocht: %s voor %d goud" % [item.display_name, price])
	return true


func _rebuild() -> void:
	_gold_label.text = "%d goud" % GameState.gold
	_inwijding_label.text = "Inwijding %d/%d" % [GameState.inwijding, GameState.MAX_INWIJDING]
	_clear(_buy_list)
	_clear(_sell_list)
	var for_sale: Array[ItemData] = []
	for item: ItemData in ItemCatalog.get_all():
		if item.price > 0:
			for_sale.append(item)
	for_sale.sort_custom(func(a: ItemData, b: ItemData) -> bool:
		if a.type != b.type:
			return TYPE_ORDER[a.type] < TYPE_ORDER[b.type]
		return a.price < b.price)
	for item: ItemData in for_sale:
		var reason: String = _why_not_buyable(item)
		var label: String = "Kopen (%d)" % item.price if reason.is_empty() else reason
		_buy_list.add_child(_make_row(item, label, reason.is_empty(), buy))
	for id: StringName in GameState.owned_gear:
		var owned: ItemData = ItemCatalog.get_item(id)
		if owned != null and owned.price > 0 and not GameState.is_equipped(owned):
			_sell_list.add_child(_make_row(owned, "Verkopen (%d)" % GameState.get_sell_price(owned), true, sell))
	if _sell_list.get_child_count() == 0:
		var empty: Label = Label.new()
		empty.text = "Niets te verkopen. Gedragen spullen verkoop je niet."
		empty.modulate = Color(1, 1, 1, 0.6)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD
		_sell_list.add_child(empty)


## Empty when the item can be bought, otherwise the reason in a few words.
func _why_not_buyable(item: ItemData) -> String:
	if item.price <= 0:
		return "Niet te koop"
	if GameState.inwijding < item.required_inwijding:
		return "Inwijding %d" % item.required_inwijding
	if item.is_gear() and GameState.has_gear(item.id):
		return "In bezit"
	if not item.is_gear() and GameState.get_potion_count() >= GameState.MAX_POTIONS:
		return "Vol"
	if GameState.gold < item.price:
		return "%d goud nodig" % item.price
	return ""


func _make_row(item: ItemData, button_text: String, enabled: bool, on_press: Callable) -> Control:
	var row: PanelContainer = PanelContainer.new()
	row.theme_type_variation = &"SaveRow"
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	row.add_child(columns)
	var text: VBoxContainer = VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(text)
	var title: Label = Label.new()
	title.text = item.display_name
	text.add_child(title)
	var details: Label = Label.new()
	details.text = item.describe()
	details.modulate = Color(1, 1, 1, 0.65)
	details.add_theme_font_size_override("font_size", 16)
	text.add_child(details)
	var button: Button = Button.new()
	button.text = button_text
	button.disabled = not enabled
	button.custom_minimum_size = Vector2(170, 0)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(func() -> void: on_press.call(item))
	columns.add_child(button)
	return row


func _clear(list: VBoxContainer) -> void:
	for child: Node in list.get_children():
		list.remove_child(child)
		child.queue_free()


func _on_state_changed() -> void:
	if visible:
		_rebuild()
