class_name EnemyData
extends Resource
## Stats for one kind of enemy. One .tres per enemy in res://data/enemies/.

@export var id: StringName
## Name the player sees.
@export var display_name: String = ""
@export var max_health: int = 0
@export var damage: int = 0
## Distance at which the enemy starts an attack.
@export var attack_range: float = 0.0
## Seconds an attack is telegraphed before it hits.
@export var attack_windup: float = 0.0
## Seconds between attacks.
@export var attack_cooldown: float = 0.0
## Seconds the enemy is off balance after the player parries it.
@export var parry_stagger_duration: float = 0.0
