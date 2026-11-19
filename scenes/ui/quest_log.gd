class_name QuestLog
extends Control
## The questlog (J): active and completed quests on the left, and for the
## chosen quest its story, the objectives so far and the reward.

signal closed

var _selected: StringName = &""

@onready var _list: VBoxContainer = %QuestList
@onready var _title: Label = %QuestTitle
@onready var _description: Label = %Description
@onready var _objectives: VBoxContainer = %Objectives
@onready var _reward: Label = %Reward
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(close)
	EventBus.quest_updated.connect(_on_quest_updated.unbind(1))
	hide()


func open() -> void:
	var tracked: QuestData = QuestManager.get_tracked_quest()
	_selected = tracked.id if tracked != null else &""
	_rebuild()
	show()
	_back_button.grab_focus()


func close() -> void:
	hide()
	closed.emit()


func _rebuild() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var active: Array[QuestData] = QuestManager.get_quests_by_status(QuestManager.Status.ACTIVE)
	var done: Array[QuestData] = QuestManager.get_quests_by_status(QuestManager.Status.COMPLETED)
	if _selected.is_empty():
		var all: Array[QuestData] = active + done
		_selected = all[0].id if not all.is_empty() else &""
	_add_section("Actief", active)
	_add_section("Afgerond", done)
	_show_details()


func _add_section(heading: String, quests: Array[QuestData]) -> void:
	if quests.is_empty():
		return
	var label: Label = Label.new()
	label.text = heading
	label.add_theme_color_override("font_color", Color(1, 0.86, 0.55))
	_list.add_child(label)
	for quest: QuestData in quests:
		var button: Button = Button.new()
		button.text = "%d. %s" % [quest.number, quest.title]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = quest.id == _selected
		button.pressed.connect(_select.bind(quest.id))
		_list.add_child(button)


func _select(id: StringName) -> void:
	_selected = id
	_rebuild()


func _show_details() -> void:
	for child: Node in _objectives.get_children():
		_objectives.remove_child(child)
		child.queue_free()
	var quest: QuestData = QuestManager.get_quest(_selected) if not _selected.is_empty() else null
	if quest == null:
		_title.text = "Geen quests"
		_description.text = "Je hebt nog geen quests. Praat met Klaas."
		_reward.text = ""
		return
	_title.text = quest.title
	_description.text = quest.description
	var current: int = QuestManager.get_step_index(quest.id)
	for index: int in mini(current + 1, quest.steps.size()):
		var step: QuestStep = quest.steps[index]
		var line: Label = Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD
		if index < current:
			line.text = "✓ " + step.description
			line.modulate = Color(1, 1, 1, 0.5)
		else:
			var progress: String = QuestManager.get_step_progress(quest.id)
			line.text = "▶ " + step.description + ("  (%s)" % progress if not progress.is_empty() else "")
			line.add_theme_color_override("font_color", Color(1, 0.94, 0.8))
		_objectives.add_child(line)
	_reward.text = "Beloning: " + _describe_reward(quest)


func _describe_reward(quest: QuestData) -> String:
	var parts: PackedStringArray = []
	if quest.reward_gold > 0:
		parts.append("%d goud" % quest.reward_gold)
	var counts: Dictionary[String, int] = {}
	for item: ItemData in quest.reward_items:
		counts[item.display_name] = counts.get(item.display_name, 0) + 1
	for item_name: String in counts:
		parts.append("%d× %s" % [counts[item_name], item_name] if counts[item_name] > 1 else item_name)
	if quest.raises_inwijding:
		parts.append("Inwijding +1")
	return ", ".join(parts)


func _on_quest_updated() -> void:
	if visible:
		_rebuild()
