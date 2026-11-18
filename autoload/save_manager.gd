extends Node
## Saving and loading: manual saves, quicksave (F5), quickload (F9) and
## autosaves. Every node in the persist group implements
## save_data() -> Dictionary and load_data(data: Dictionary). Built in Phase 3.

const SAVE_DIR: String = "user://saves/"
const SAVE_VERSION: int = 1
const PERSIST_GROUP: StringName = &"persist"
