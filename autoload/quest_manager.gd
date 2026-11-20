extends Node
## Main quests. Loads every QuestData in res://data/quests/, tracks status,
## current step and progress, moves steps along on EventBus events, hands out
## the reward and asks for an autosave after every finished objective. A quest
## whose completion_flag was set before it started (a dungeon done before
## Klaas asked) is completed as soon as it starts.

enum Status { NOT_STARTED, ACTIVE, COMPLETED }

const QUESTS_DIR: String = "res://data/quests/"

var _quests: Dictionary[StringName, QuestData] = {}
var _status: Dictionary[StringName, Status] = {}
var _step: Dictionary[StringName, int] = {}
## Kills counted for the current KILL step.
var _kills: Dictionary[StringName, int] = {}
## Actions already done for the current ACTIONS step.
var _actions_done: Dictionary[StringName, Array] = {}


func _ready() -> void:
	for file_name: String in ResourceLoader.list_directory(QUESTS_DIR):
		var quest: QuestData = load(QUESTS_DIR + file_name) as QuestData
		if quest != null:
			add_quest(quest)
	EventBus.flag_set.connect(_on_flag_set)
	EventBus.player_action.connect(_on_player_action)
	EventBus.game_saved.connect(_on_game_saved)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.area_entered.connect(_on_area_entered)


## Adds a quest to the list. Quests from res://data/quests/ are added at start.
func add_quest(quest: QuestData) -> void:
	_quests[quest.id] = quest
	if not _status.has(quest.id):
		_status[quest.id] = Status.NOT_STARTED


## Back to the start of a new game: no quest started.
func reset() -> void:
	for id: StringName in _quests:
		_status[id] = Status.NOT_STARTED
	_step.clear()
	_kills.clear()
	_actions_done.clear()
	EventBus.quest_updated.emit(&"")


func get_quest(id: StringName) -> QuestData:
	return _quests.get(id)


func get_status(id: StringName) -> Status:
	return _status.get(id, Status.NOT_STARTED)


## True when every quest but [param except_id] is completed, so nothing is
## waiting for Klaas any more.
func are_others_completed(except_id: StringName) -> bool:
	for id: StringName in _quests:
		if id != except_id and get_status(id) != Status.COMPLETED:
			return false
	return true


## The objective the player is working on, or null when the quest is not active.
func get_current_step(id: StringName) -> QuestStep:
	if get_status(id) != Status.ACTIVE:
		return null
	return _quests[id].steps[_step.get(id, 0)]


## Index of the current step; all steps count as done once the quest is completed.
func get_step_index(id: StringName) -> int:
	if get_status(id) == Status.COMPLETED:
		return _quests[id].steps.size()
	return _step.get(id, 0)


## Quests with [param status], by quest number.
func get_quests_by_status(status: Status) -> Array[QuestData]:
	var found: Array[QuestData] = []
	for id: StringName in _quests:
		if get_status(id) == status:
			found.append(_quests[id])
	found.sort_custom(func(a: QuestData, b: QuestData) -> bool: return a.number < b.number)
	return found


## The quest the HUD and compass follow: the active quest with the lowest number.
func get_tracked_quest() -> QuestData:
	var active: Array[QuestData] = get_quests_by_status(Status.ACTIVE)
	return active[0] if not active.is_empty() else null


func start_quest(id: StringName) -> void:
	if not _quests.has(id) or get_status(id) != Status.NOT_STARTED:
		return
	var quest: QuestData = _quests[id]
	_status[id] = Status.ACTIVE
	EventBus.message_requested.emit("Nieuwe quest: %s" % quest.title)
	if not quest.start_message.is_empty():
		EventBus.message_requested.emit(quest.start_message)
	if not quest.completion_flag.is_empty() and GameState.has_flag(quest.completion_flag):
		complete_quest(id)
		return
	_enter_step(id, 0)


func complete_quest(id: StringName) -> void:
	if get_status(id) == Status.COMPLETED:
		return
	var quest: QuestData = _quests[id]
	_status[id] = Status.COMPLETED
	if quest.reward_gold > 0:
		GameState.add_gold(quest.reward_gold)
	for item: ItemData in quest.reward_items:
		if item.is_gear():
			GameState.add_gear(item)
		else:
			GameState.add_item(item)
	if quest.raises_inwijding:
		GameState.raise_inwijding(GameState.inwijding + 1)
	EventBus.message_requested.emit("Quest voltooid: %s" % quest.title)
	EventBus.quest_completed.emit(id)
	EventBus.quest_updated.emit(id)
	SaveManager.request_autosave()


func save_data() -> Dictionary:
	var quests: Dictionary = {}
	for id: StringName in _quests:
		quests[String(id)] = {
			"status": int(get_status(id)),
			"step": _step.get(id, 0),
			"kills": _kills.get(id, 0),
			"actions": Array(_actions_done.get(id, [])).map(func(action: StringName) -> String: return String(action)),
		}
	return {"quests": quests}


func load_data(data: Dictionary) -> void:
	reset()
	var quests: Dictionary = data.get("quests", {})
	for key: String in quests:
		var id: StringName = StringName(key)
		if not _quests.has(id):
			continue
		var entry: Dictionary = quests[key]
		_status[id] = int(entry.get("status", 0)) as Status
		_step[id] = int(entry.get("step", 0))
		_kills[id] = int(entry.get("kills", 0))
		var done: Array[StringName] = []
		for action: Variant in entry.get("actions", []):
			done.append(StringName(str(action)))
		_actions_done[id] = done
	EventBus.quest_updated.emit(&"")
	_start_flagged_quests()


## Starts the quests whose start_flag is set and that did not start yet.
func _start_flagged_quests() -> void:
	for id: StringName in _quests:
		var quest: QuestData = _quests[id]
		if not quest.start_flag.is_empty() and get_status(id) == Status.NOT_STARTED and GameState.has_flag(quest.start_flag):
			start_quest(id)


func _enter_step(id: StringName, index: int) -> void:
	_step[id] = index
	_kills[id] = 0
	_actions_done[id] = [] as Array[StringName]
	var step: QuestStep = _quests[id].steps[index]
	if step.give_item != null:
		GameState.add_item(step.give_item)
	EventBus.quest_updated.emit(id)
	# Flags that are already set finish the step straight away.
	if step.kind == QuestStep.Kind.FLAG and GameState.has_flag(step.flag) \
			or step.kind == QuestStep.Kind.FLAGS and _count_flags(step) == step.flags.size():
		_advance.call_deferred(id)


func _advance(id: StringName) -> void:
	if get_status(id) != Status.ACTIVE:
		return
	var next: int = _step.get(id, 0) + 1
	if next >= _quests[id].steps.size():
		complete_quest(id)
		return
	EventBus.message_requested.emit("Doel voltooid")
	_enter_step(id, next)
	SaveManager.request_autosave()


## Runs [param check] on the current step of every active quest, and moves
## that quest along when it returns true.
func _check_steps(check: Callable) -> void:
	for id: StringName in _quests.keys():
		var step: QuestStep = get_current_step(id)
		if step != null and check.call(id, step):
			_advance(id)


func _on_flag_set(flag: StringName) -> void:
	_start_flagged_quests()
	_check_steps(func(id: StringName, step: QuestStep) -> bool:
		if step.kind == QuestStep.Kind.FLAG:
			return step.flag == flag
		if step.kind != QuestStep.Kind.FLAGS or flag not in step.flags:
			return false
		EventBus.quest_updated.emit(id)
		return _count_flags(step) == step.flags.size())


func _count_flags(step: QuestStep) -> int:
	return step.flags.filter(func(flag: StringName) -> bool: return GameState.has_flag(flag)).size()


func _on_player_action(action: StringName) -> void:
	_check_steps(func(id: StringName, step: QuestStep) -> bool:
		if step.kind != QuestStep.Kind.ACTIONS or action not in step.actions:
			return false
		var done: Array = _actions_done[id]
		if action not in done:
			done.append(action)
			EventBus.quest_updated.emit(id)
		return step.actions.all(func(needed: StringName) -> bool: return needed in done))


func _on_game_saved(save_type: String) -> void:
	if save_type != "auto":
		_on_player_action(&"save")


func _on_enemy_killed(enemy_id: StringName) -> void:
	_check_steps(func(id: StringName, step: QuestStep) -> bool:
		if step.kind != QuestStep.Kind.KILL or step.enemy_id != enemy_id:
			return false
		_kills[id] = _kills.get(id, 0) + 1
		EventBus.quest_updated.emit(id)
		return _kills[id] >= step.count)


func _on_area_entered(area_id: StringName) -> void:
	_check_steps(func(_id: StringName, step: QuestStep) -> bool:
		return step.kind == QuestStep.Kind.REACH and step.area_id == area_id)


## How far the current step is, for the HUD: "1/2" for kills, or "" otherwise.
func get_step_progress(id: StringName) -> String:
	var step: QuestStep = get_current_step(id)
	if step == null:
		return ""
	match step.kind:
		QuestStep.Kind.KILL:
			return "%d/%d" % [_kills.get(id, 0), step.count]
		QuestStep.Kind.ACTIONS:
			return "%d/%d" % [Array(_actions_done.get(id, [])).size(), step.actions.size()]
		QuestStep.Kind.FLAGS:
			return "%d/%d" % [_count_flags(step), step.flags.size()]
		_:
			return ""
