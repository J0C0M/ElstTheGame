class_name DialogueBox
extends Control
## Shows a conversation from DialogueData: the speaker's line, typed out, and
## the player's choices. Runs simple actions (flags, Inwijding, quests, gifts)
## itself and hands the others (shop, sleep) to Main through action_chosen,
## after it has closed.

signal action_chosen(action: StringName, value: String)
signal closed

const CHARACTERS_PER_SECOND: float = 45.0
## Actions that open something else; the conversation closes first.
const HANDOFF_ACTIONS: Array[StringName] = [&"open_shop", &"sleep"]

var _dialogue: DialogueData
var _speaker: Node
var _line: DialogueLine
var _typing: Tween

@onready var _speaker_label: Label = %SpeakerLabel
@onready var _text_label: Label = %TextLabel
@onready var _choices: VBoxContainer = %Choices


func _ready() -> void:
	hide()


func start(dialogue: DialogueData, speaker: Node) -> void:
	_dialogue = dialogue
	_speaker = speaker
	_speaker_label.text = dialogue.speaker
	show()
	_show_line(dialogue.get_start())


func close() -> void:
	if _typing != null:
		_typing.kill()
	hide()
	_dialogue = null
	closed.emit()


## The line on screen, for tests.
func get_current_line() -> DialogueLine:
	return _line


## Picks the visible choice at [param index], as a click would.
func choose(index: int) -> void:
	var options: Array[DialogueChoice] = _line.get_available_choices()
	if options.is_empty():
		_on_continue()
	elif index < options.size():
		_on_choice(options[index])


func _show_line(line: DialogueLine) -> void:
	if line == null:
		close()
		return
	_line = line
	_run_action(line.action, line.action_value)
	if not line.model_action.is_empty() and _speaker != null and _speaker.has_method("play_model_action"):
		_speaker.call("play_model_action", line.model_action)
	_text_label.text = line.text
	_text_label.visible_ratio = 0.0
	if _typing != null:
		_typing.kill()
	_typing = create_tween()
	_typing.tween_property(_text_label, "visible_ratio", 1.0, line.text.length() / CHARACTERS_PER_SECOND)
	_build_buttons()


func _build_buttons() -> void:
	for child: Node in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	var options: Array[DialogueChoice] = _line.get_available_choices()
	if options.is_empty():
		var button: Button = Button.new()
		button.text = "Verder" if not _line.next.is_empty() else "Einde"
		button.pressed.connect(_on_continue)
		_choices.add_child(button)
	else:
		for i: int in options.size():
			var button: Button = Button.new()
			button.text = "%d. %s" % [i + 1, options[i].text]
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.pressed.connect(_on_choice.bind(options[i]))
			_choices.add_child(button)
	(_choices.get_child(0) as Button).grab_focus()


func _on_continue() -> void:
	if _line.next.is_empty():
		close()
	else:
		_show_line(_dialogue.get_line(_line.next))


func _on_choice(choice: DialogueChoice) -> void:
	if choice.action in HANDOFF_ACTIONS:
		close()
		action_chosen.emit(choice.action, choice.action_value)
		return
	_run_action(choice.action, choice.action_value)
	if choice.next.is_empty():
		close()
	else:
		_show_line(_dialogue.get_line(choice.next))


func _run_action(action: StringName, value: String) -> void:
	match action:
		&"set_flag":
			GameState.set_flag(StringName(value))
		&"raise_inwijding":
			GameState.raise_inwijding(int(value))
		&"start_quest":
			QuestManager.start_quest(StringName(value))
		&"give_item":
			var item: ItemData = ItemCatalog.get_item(StringName(value))
			if item != null and item.is_gear():
				GameState.add_gear(item)
			elif item != null:
				GameState.add_item(item)
