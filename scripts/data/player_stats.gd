class_name PlayerStats
extends Resource
## Tunable values for the player. The real numbers live in
## res://data/player/player_stats.tres; the defaults here are only fallbacks.

@export_group("Health and stamina")
@export var max_health: int = 0
@export var max_stamina: float = 0.0
@export var stamina_regen_per_second: float = 0.0
## Seconds after the last stamina use before stamina starts to refill.
@export var stamina_regen_delay: float = 0.0

@export_group("Movement")
@export var walk_speed: float = 0.0
@export var sprint_speed: float = 0.0
@export var sprint_stamina_per_second: float = 0.0
@export var acceleration: float = 0.0
@export var air_acceleration: float = 0.0
## How quickly the player turns towards the move direction.
@export var turn_speed: float = 0.0
@export var jump_velocity: float = 0.0
@export var gravity_multiplier: float = 1.0

@export_group("Dodge")
@export var dodge_stamina_cost: float = 0.0
@export var dodge_duration: float = 0.0
@export var dodge_distance: float = 0.0
## Seconds of invulnerability at the start of a dodge.
@export var dodge_invulnerability: float = 0.0
## Two taps on a direction within this many seconds also dodge.
@export var double_tap_window: float = 0.0

@export_group("Light attack")
@export var light_attack_duration: float = 0.0
@export var light_attack_active_start: float = 0.0
@export var light_attack_active_end: float = 0.0
## From this moment in the first swing, another click queues the combo.
@export var combo_input_open: float = 0.0
## Moment in the first swing where a queued second swing starts.
@export var combo_chain_time: float = 0.0
## Damage multiplier for the second swing of the combo.
@export var combo_damage_multiplier: float = 1.0

@export_group("Heavy attack")
## Seconds the attack button must be held for a heavy attack.
@export var heavy_hold_time: float = 0.0
@export var heavy_attack_duration: float = 0.0
@export var heavy_attack_active_start: float = 0.0
@export var heavy_attack_active_end: float = 0.0
@export var heavy_damage_multiplier: float = 1.0
@export var heavy_attack_stamina_cost: float = 0.0
## Forward speed while a swing is active.
@export var attack_lunge_speed: float = 0.0

@export_group("Block and parry")
## Share of damage a block removes, for hits from the front.
@export_range(0.0, 1.0) var block_damage_reduction: float = 0.0
## Stamina each blocked hit costs. Without enough stamina the guard breaks.
@export var block_stamina_cost: float = 0.0
@export var block_move_speed: float = 0.0
## Hits within this angle of where the player faces count as from the front.
@export var block_angle_degrees: float = 0.0
## Seconds after pressing block in which a hit is parried.
@export var parry_window: float = 0.0

@export_group("Getting hit")
@export var hurt_duration: float = 0.0
@export var guard_break_duration: float = 0.0
