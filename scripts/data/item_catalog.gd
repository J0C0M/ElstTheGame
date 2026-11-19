class_name ItemCatalog
## Finds ItemData by id among the .tres files in res://data/items/, so saves
## can store just the id.

const ITEMS_DIR: String = "res://data/items/"

static var _items: Dictionary[StringName, ItemData] = {}


static func get_item(id: StringName) -> ItemData:
	if _items.is_empty():
		for file_name: String in ResourceLoader.list_directory(ITEMS_DIR):
			var item: ItemData = load(ITEMS_DIR + file_name) as ItemData
			if item != null:
				_items[item.id] = item
	return _items.get(id)
