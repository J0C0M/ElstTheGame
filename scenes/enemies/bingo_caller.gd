class_name BingoCaller
extends Node3D
## Makes a bingo-opa call out bingo numbers and wise bingo facts while he
## fights.

const FACTS: Array[String] = [
	"Bingo komt uit Italië, jochie!",
	"75 ballen. Altijd 75!",
	"88: twee dikke dames!",
	"22: twee eendjes!",
	"Vroeger kostte een kaart een kwartje!",
	"Kijk diagonaal. Altijd diagonaal.",
	"Grumpy Oma had drie keer BINGO op één avond!",
	"Wie BINGO roept, moet het ook hebben!",
]
const LETTERS: String = "BINGO"
const NUMBER_TIME: float = 1.4
const FACT_TIME: float = 2.4

@export var call_interval: float = 2.4
## Every this many calls is a fact instead of a number.
@export var calls_per_fact: int = 3

## How many calls he made, for tests.
var calls: int = 0
var _timer: float = 1.0
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
	calls += 1
	if calls % calls_per_fact == 0:
		_show(FACTS.pick_random(), FACT_TIME)
	else:
		# He knows his letters: B is 1 to 15, I is 16 to 30, and so on.
		var number: int = randi_range(1, 75)
		_show("%s-%d!" % [LETTERS[floori((number - 1) / 15.0)], number], NUMBER_TIME)


func _show(text: String, seconds: float) -> void:
	_label.text = text
	_label.visible = true
	_shown = seconds
