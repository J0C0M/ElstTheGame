class_name QuestData
extends Resource
## A main quest: its steps and its reward. One .tres per quest in
## res://data/quests/.

@export var id: StringName
## Order in which Klaas hands out the quests, 1 to 6.
@export var number: int = 0
@export var title: String = ""
@export_multiline var description: String = ""
@export var steps: Array[QuestStep] = []
## A GameState flag (such as a defeated boss). When it is already set as
## Klaas gives the quest, the quest is finished at once, with the reward.
## While the quest is active its steps decide, so the player still reports back.
@export var completion_flag: StringName

@export_group("Reward")
@export var reward_gold: int = 0
## Items in the reward; list an item twice to give two.
@export var reward_items: Array[ItemData] = []
## Every main quest raises the Inwijding by one.
@export var raises_inwijding: bool = true
