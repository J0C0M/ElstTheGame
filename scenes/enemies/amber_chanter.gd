class_name AmberChanter
extends Node3D
## Makes an Amber cultist chant while he fights. Every few seconds his song
## fires up every enemy close by, of any faction: they hit harder for a
## while, and their wounds close a little (his own too). Kill the cultists
## first.

@export var chant_interval: float = 6.0
@export var radius: float = 10.0
@export var buff_factor: float = 1.25
@export var buff_time: float = 5.0
## Health the song gives back to every enemy in the radius.
@export var heal_amount: int = 12

const SHOW_TIME: float = 1.6

## How many times he chanted, for tests.
var chants: int = 0
var _timer: float = 2.0
var _shown: float = 0.0

@onready var _enemy: Enemy = get_parent() as Enemy
@onready var _label: Label3D = $Label


func _ready() -> void:
	_label.visible = false


func _physics_process(delta: float) -> void:
	_shown -= delta
	if _shown <= 0.0:
		_label.visible = false
	if _enemy.health.is_dead() or _enemy.state_machine.get_state_name() not in [&"Chase", &"Attack"]:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = chant_interval
		chant()


## Sings to Amber: enemies within the radius hit harder for a while and
## heal a little.
func chant() -> void:
	chants += 1
	_label.visible = true
	_shown = SHOW_TIME
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var other: Enemy = node as Enemy
		if other != null and not other.health.is_dead() and other.global_position.distance_to(global_position) <= radius:
			other.buff_damage(buff_factor, buff_time, "WOEST!")
			other.health.heal(heal_amount)
