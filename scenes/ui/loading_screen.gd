class_name LoadingScreen
extends Control
## Shown on the black of a world change while the next world loads: the name
## of the place, a tip and a progress bar.

const TIPS: Array[String] = [
	"Blokkeer precies op tijd om een klap te pareren: de vijand raakt even uit balans.",
	"Houd de linkermuisknop vast voor een zware aanval: langzamer, maar bijna dubbele schade.",
	"Ontwijk met Alt, of door twee keer snel op een richting te tikken.",
	"Achter een pilaar raakt Ambers vuur je niet. Onder haar nek wel.",
	"Laat Amber haar kop zakken na haar vuuradem? Sla op haar kop voor dubbele schade.",
	"Vijanden die je van ver raakt, komen op je af. Met hun hele groep.",
	"Cultisten genezen hun vrienden met hun gezang. Pak ze als eerste.",
	"Grumpy Oma is uitgeput na een grondslag of een tornado. Dan is je kans.",
	"Het fatbike-kindje staat versuft als hij tegen een muur knalt.",
	"De Vape-koning hoest als je zijn wolk in loopt.",
	"Een rustbank heelt je helemaal en slaat het spel op.",
	"F5 slaat snel op, F9 laadt die save weer.",
	"Klaas verkoopt pijlen per vijf. Vijanden en kisten laten ze ook vallen.",
	"Weet je niet waar je heen moet? Kijk in je questlog (J) of op het kompas.",
	"Klaas' zonnebril gaat nooit af. Nooit.",
]
## Names of the worlds by scene file, shown before the world has loaded.
const NAMES: Dictionary = {
	"Elst": "Elst", "Station": "Station Elst", "Westeraam": "Westeraam Getho", "OBC": "OBC Elst Fort",
	"BingoCave": "Bingo Club Boomer Cave", "Kerk": "De Kerk van Amber", "KlaasHouse": "Het huis van Klaas",
}

@onready var _title: Label = %Title
@onready var _tip: Label = %Tip
@onready var _bar: ProgressBar = %Bar


func _ready() -> void:
	hide()


## Shows the screen for the world in [param scene_path].
func open(scene_path: String) -> void:
	_title.text = NAMES.get(scene_path.get_file().get_basename(), "Elst")
	_tip.text = "Tip: " + TIPS.pick_random()
	_bar.value = 0.0
	show()


func set_progress(ratio: float) -> void:
	_bar.value = ratio * 100.0
