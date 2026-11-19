class_name QuestStep
extends Resource
## One objective of a quest, and what finishes it.

enum Kind {
	## A GameState flag gets set, for example by a conversation.
	FLAG,
	## The player does every action in [member actions] (sprint, jump, dodge,
	## block, drink, save).
	ACTIONS,
	## The player defeats [member count] enemies with id [member enemy_id].
	KILL,
	## The player reaches the place with id [member area_id].
	REACH,
	## Every flag in [member flags] gets set, in any order. Flags that were
	## already set before the step started count too.
	FLAGS,
}

@export var id: StringName
## The objective the player reads in the questlog and on the HUD.
@export_multiline var description: String = ""
@export var kind: Kind = Kind.FLAG
@export var flag: StringName
@export var flags: Array[StringName] = []
@export var actions: Array[StringName] = []
@export var enemy_id: StringName
@export var count: int = 1
@export var area_id: StringName
## Id of the QuestMarker the compass points to.
@export var target: StringName
## Handed to the player when the step starts, such as a potion to practise with.
@export var give_item: ItemData
