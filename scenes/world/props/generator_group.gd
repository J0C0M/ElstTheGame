class_name GeneratorGroup
extends Node3D
## Holds the generators of a dungeon as children. Counts down as they break,
## and sets [member completion_flag] once the last one is broken.

## GameState flag that is set when every generator is broken.
@export var completion_flag: StringName
## Message after a generator breaks; %d is the number still running.
@export var progress_message: String = "Generator kapot. Nog %d te gaan."
## Message after the last generator breaks.
@export var done_message: String = "Alle generators liggen plat."


func _ready() -> void:
	for generator: Generator in get_generators():
		generator.broken.connect(_on_generator_broken)


func get_generators() -> Array[Generator]:
	var generators: Array[Generator] = []
	for child: Node in get_children():
		if child is Generator:
			generators.append(child as Generator)
	return generators


## How many generators still run.
func count_running() -> int:
	return get_generators().filter(func(generator: Generator) -> bool: return not generator.is_broken()).size()


func _on_generator_broken() -> void:
	var running: int = count_running()
	if running > 0:
		EventBus.message_requested.emit(progress_message % running)
		return
	GameState.set_flag(completion_flag)
	EventBus.message_requested.emit(done_message)
