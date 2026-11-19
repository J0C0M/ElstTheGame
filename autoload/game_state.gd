extends Node
## Global game state: gold, Inwijding, liberated areas, the church doors,
## story flags and play time. SaveManager stores it in every save file.

## Name of the place the player is in, for the save metadata.
var current_location: String = ""
var gold: int = 0
## Bond with Klaas, from 0 to 6.
var inwijding: int = 0
var liberated_areas: Array[StringName] = []
var church_open: bool = false
## Seconds played in this game, counted by Main while the game runs.
var play_time: float = 0.0

## World and story flags, such as an opened chest or a destroyed generator.
var _flags: Dictionary[StringName, bool] = {}
## Reasons that currently forbid saving, such as a boss fight or a cutscene.
var _save_blockers: Dictionary[StringName, bool] = {}


## Back to the start of a new game.
func reset() -> void:
	current_location = ""
	gold = 0
	inwijding = 0
	liberated_areas.clear()
	church_open = false
	play_time = 0.0
	_flags.clear()
	_save_blockers.clear()


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
	for flag: Variant in data.get("flags", []):
		_flags[StringName(str(flag))] = true
