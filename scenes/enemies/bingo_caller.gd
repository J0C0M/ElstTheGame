class_name BingoCaller
extends Node3D
## Makes a bingo-opa call out bingo numbers while he fights. Every few calls
## he shouts BINGO!, and the grumpy grandmas nearby hit harder for a while.

@export var call_interval: float = 2.2
@export var calls_per_bingo: int = 4
@export var buff_radius: float = 10.0
@export var buff_factor: float = 1.25
@export var buff_time: float = 5.0
## Enemy id of the grandmas the BINGO! fires up.
@export var buffs_enemy_id: StringName = &"boze_oma"

const SHOW_TIME: float = 1.4

var _timer: float = 1.0
var _calls: int = 0
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
	if _timer > 0.0:
		return
	_timer = call_interval
	_calls += 1
	if _calls % calls_per_bingo == 0:
		bingo()
	else:
		_show("%s-%d!" % ["BINGO"[randi() % 5], randi_range(1, 75)])


## Shouts BINGO! and fires up the grandmas within reach.
func bingo() -> void:
	_show("BINGO!")
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var other: Enemy = node as Enemy
		if other != null and other.data.id == buffs_enemy_id and other.global_position.distance_to(global_position) <= buff_radius:
			other.buff_damage(buff_factor, buff_time, "WOEST!")


func _show(text: String) -> void:
	_label.text = text
	_label.visible = true
	_shown = SHOW_TIME
