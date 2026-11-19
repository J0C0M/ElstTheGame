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
## A GameState flag that weakens this enemy, such as the destroyed station.
@export var weakened_by_flag: StringName
## Share of [member max_health] the enemy keeps once [member weakened_by_flag]
## is set.
@export_range(0.1, 1.0) var weakened_health_factor: float = 1.0
@export var damage: int = 0
## Speed of the lunge during a strike; a fatbiker charges with it.
@export var lunge_speed: float = 2.0
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


@export_group("Ranged")
## Projectile the enemy fires instead of a melee swing, such as a vape puff.
## Ranged enemies attack from attack_range and back off when the player
## comes closer than keep_distance.
@export var projectile_scene: PackedScene
@export var keep_distance: float = 0.0
## Chance that a shot flies straight at the player; the others miss by
## miss_angle degrees to one side.
@export_range(0.0, 1.0) var accuracy: float = 1.0
@export var miss_angle: float = 15.0
## Shots per attack; a burst fans out over burst_spread degrees.
@export var burst_count: int = 1
@export var burst_spread: float = 0.0
## Speed the enemy is pushed back with when it fires, like a cannon.
@export var recoil: float = 0.0
@export_group("Leap")
## The enemy leaps at the player from up to this far (0: never leaps).
@export var leap_range: float = 0.0
## Seconds in the air during a leap.
@export var leap_time: float = 0.7
## Seconds of fighting up close without being hit before the enemy hops
## away again (0: never).
@export var patience: float = 0.0
@export var hop_away_distance: float = 7.0
## Seconds the enemy waits after hopping away before it attacks again.
@export var hop_away_wait: float = 2.0


func can_leap() -> bool:
	return leap_range > 0.0


func is_ranged() -> bool:
	return projectile_scene != null


## Health the enemy starts with right now: lower once it is weakened.
func get_max_health() -> int:
	if not weakened_by_flag.is_empty() and GameState.has_flag(weakened_by_flag):
		return maxi(roundi(max_health * weakened_health_factor), 1)
	return max_health
