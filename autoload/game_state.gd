extends Node
## Global game state: gold, Inwijding, liberated areas, the church doors and
## story flags. Filled in step by step and saved by SaveManager (Phase 3).

## Name of the place the player is in, for the save metadata.
var current_location: String = ""
