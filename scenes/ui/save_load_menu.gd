class_name SaveLoadMenu
extends Control
## Lists save files with a screenshot, place, date and play time. In save mode
## it makes a new named save or overwrites a manual one; in load mode it loads
## or deletes any save.

signal closed

enum Mode { SAVE, LOAD }

const TYPE_TITLES: Dictionary = {"quick": "Snelle save", "auto": "Automatische save"}

var _mode: Mode = Mode.LOAD
## Save that asks "Zeker?" before it is deleted.
var _delete_pending: String = ""

@onready var _title: Label = %Title
@onready var _new_save_row: HBoxContainer = %NewSaveRow
@onready var _name_edit: LineEdit = %NameEdit
@onready var _new_save_button: Button = %NewSaveButton
@onready var _empty_label: Label = %EmptyLabel
@onready var _list: VBoxContainer = %List
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_new_save_button.pressed.connect(_on_new_save_pressed)
	_name_edit.text_submitted.connect(func(_text: String) -> void: _on_new_save_pressed())
	_back_button.pressed.connect(close)
	EventBus.saves_changed.connect(_on_saves_changed)
	hide()


func open(mode: Mode) -> void:
	_mode = mode
	_delete_pending = ""
	_title.text = "Opslaan" if mode == Mode.SAVE else "Laden"
	_new_save_row.visible = mode == Mode.SAVE
	_name_edit.text = _default_name()
	_rebuild()
	show()
	if mode == Mode.SAVE:
		_name_edit.grab_focus()
		_name_edit.select_all()
	elif _list.get_child_count() > 0:
		(_list.get_child(0).find_child("PrimaryButton", true, false) as Button).grab_focus()
	else:
		_back_button.grab_focus()


func close() -> void:
	hide()
	closed.emit()


func _rebuild() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var saves: Array[Dictionary] = SaveManager.list_saves()
	if _mode == Mode.SAVE:
		saves = saves.filter(func(meta: Dictionary) -> bool: return meta.get("type") == "manual")
	_empty_label.visible = saves.is_empty()
	_empty_label.text = "Je hebt nog geen eigen saves." if _mode == Mode.SAVE else "Er zijn nog geen saves."
	for meta: Dictionary in saves:
		_list.add_child(_make_row(meta))


func _make_row(meta: Dictionary) -> Control:
	var id: String = str(meta["id"])
	var row: PanelContainer = PanelContainer.new()
	row.theme_type_variation = &"SaveRow"
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	row.add_child(columns)
	var thumbnail: TextureRect = TextureRect.new()
	thumbnail.custom_minimum_size = Vector2(160, 90)
	thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumbnail.texture = SaveManager.get_thumbnail(id)
	columns.add_child(thumbnail)
	var text: VBoxContainer = VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	columns.add_child(text)
	var title: Label = Label.new()
	title.text = _title_for(meta)
	title.add_theme_font_size_override("font_size", 22)
	text.add_child(title)
	var details: Label = Label.new()
	details.text = "%s · %s · speeltijd %s" % [meta.get("location", "?"), _format_date(str(meta.get("date", ""))),
		_format_play_time(float(meta.get("play_time", 0.0)))]
	details.modulate = Color(1, 1, 1, 0.7)
	details.add_theme_font_size_override("font_size", 16)
	text.add_child(details)
	var primary: Button = Button.new()
	primary.name = "PrimaryButton"
	primary.text = "Overschrijven" if _mode == Mode.SAVE else "Laden"
	primary.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	primary.pressed.connect(_on_primary_pressed.bind(id, str(meta.get("name", ""))))
	columns.add_child(primary)
	var delete: Button = Button.new()
	delete.text = "Verwijderen"
	delete.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	delete.pressed.connect(_on_delete_pressed.bind(id, delete))
	columns.add_child(delete)
	return row


func _on_new_save_pressed() -> void:
	var save_name: String = _name_edit.text.strip_edges()
	if save_name.is_empty():
		save_name = _default_name()
	if SaveManager.save_game(SaveManager.SaveType.MANUAL, save_name):
		EventBus.message_requested.emit("Opgeslagen: %s" % save_name)
		_name_edit.text = _default_name()


func _on_primary_pressed(id: String, save_name: String) -> void:
	if _mode == Mode.LOAD:
		SaveManager.load_save(id)
	elif SaveManager.save_game(SaveManager.SaveType.MANUAL, save_name, id):
		EventBus.message_requested.emit("Overschreven: %s" % save_name)


func _on_delete_pressed(id: String, button: Button) -> void:
	if _delete_pending != id:
		_delete_pending = id
		button.text = "Zeker?"
		return
	_delete_pending = ""
	SaveManager.delete_save(id)


func _on_saves_changed() -> void:
	if visible:
		_rebuild()


func _title_for(meta: Dictionary) -> String:
	var save_type: String = str(meta.get("type", "manual"))
	if save_type == "manual":
		var save_name: String = str(meta.get("name", ""))
		return save_name if not save_name.is_empty() else "Save"
	return str(TYPE_TITLES.get(save_type, "Save"))


func _default_name() -> String:
	var place: String = GameState.current_location if not GameState.current_location.is_empty() else "Elst"
	return "%s, %s" % [place, _format_date(Time.get_datetime_string_from_system(false, true))]


## "2026-11-19 14:03:22" becomes "19-11-2026 14:03".
func _format_date(date: String) -> String:
	var parts: PackedStringArray = date.split(" ")
	var day: PackedStringArray = parts[0].split("-")
	if parts.size() < 2 or day.size() < 3:
		return date
	return "%s-%s-%s %s" % [day[2], day[1], day[0], parts[1].substr(0, 5)]


func _format_play_time(seconds: float) -> String:
	var minutes: int = int(seconds / 60.0)
	return "%d u %02d min" % [int(minutes / 60.0), minutes % 60]
