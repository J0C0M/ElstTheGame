class_name EnemyData
extends Resource
## Stats for one kind of enemy. One .tres per enemy in res://data/enemies/.
## The values are starting points from the GDD.

@export_group("Identity")
@export var id: StringName
## Name the player sees.
@export var display_name: String = ""
## Enemies of the same faction warn each other.
@export var faction: StringName
## HumanoidModel scene for the body.
@export var model_scene: PackedScene
@export var loot: LootTable

@export_group("Combat")
@export var max_health: int = 0
@export var damage: int = 0
## Distance at which the enemy starts an attack.
@export var attack_range: float = 0.0
## Seconds an attack is telegraphed before it hits.
@export var attack_windup: float = 0.0
## Seconds the attack can hit once it swings.
@export var strike_time: float = 0.0
## Seconds between attacks.
@export var attack_cooldown: float = 0.0
## Seconds the enemy is off balance after the player parries it.
@export var parry_stagger_duration: float = 0.0
## HumanoidModel action for the swing, such as swing_light_1 or punch.
@export var attack_action: StringName = &"swing_light_1"

@export_group("Movement")
@export var walk_speed: float = 0.0
@export var run_speed: float = 0.0

@export_group("Senses")
@export var sight_range: float = 0.0
## Width of the view cone while not yet chasing.
@export var sight_angle_degrees: float = 0.0
## Within this distance the enemy notices the player from any side.
@export var hearing_range: float = 0.0
## Allies of the same faction within this distance join the chase.
@export var alert_radius: float = 0.0
## The enemy gives up when it gets this far from home.
@export var leash_range: float = 0.0
## Patrol points are picked within this distance of home.
@export var patrol_radius: float = 0.0
## Circle round to the player's side instead of walking straight at them.
@export var flanks: bool = false
