class_name Credits
extends Control
## The credits after the end scene: names and sources roll up the screen
## over a dark background. E, Space or Esc skips them. The game is paused
## meanwhile (Main opens this like the other overlays).

signal closed

## Seconds the whole text takes to roll past.
@export var roll_time: float = 38.0

const TEXT: String = """ELST


Een game van
J0C0M


Met
De speler, een niemand die een Elstenaar werd
Klaas, de enige echte
Amber de Draak, uit Zevenaar


En
De drillers van Arnhem-Zuid
De vape-drillers en de Vape-koning van Westeraam
De kakkers en het fatbike-kindje van het OBC
De oma's, de opa's en Grumpy Oma van de Bingo Club
De cultisten en de drakenrijders uit Zevenaar
Alle dorpelingen van Elst


Gemaakt met
Godot Engine 4.7 (MIT)


Modellen, animaties, shaders en de wereld
Zelfgemaakt, in Godot en Python
Alles eigen werk of CC0 (zie CREDITS.md)


Bedankt voor het spelen!


Elst is gered.
Voorlopig.
"""

var _time: float = 0.0

@onready var _text: Label = $Text


func _ready() -> void:
	_text.text = TEXT
	hide()


func open() -> void:
	_time = 0.0
	show()
	_place_text()


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	_place_text()
	if _time >= roll_time:
		close()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed(&"interact") or event.is_action_pressed(&"jump")):
		get_viewport().set_input_as_handled()
		close()


## The text starts below the screen and rolls up until it is gone above it.
func _place_text() -> void:
	var height: float = _text.get_combined_minimum_size().y
	var t: float = clampf(_time / roll_time, 0.0, 1.0)
	_text.position.y = lerpf(size.y, -height, t)
	_text.position.x = (size.x - _text.size.x) * 0.5
