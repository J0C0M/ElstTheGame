class_name Ending
extends Node3D
## The end scene of the game, on the church square of Elst. It plays when
## the player comes out of the church with Klaas alive again (the flag
## ending_pending, set when Klaas wakes up):
## 1. the villagers are back and Elst is happy;
## 2. the tornado sinks away and the sky clears;
## 3. Klaas congratulates the player and makes them a real Elstenaar;
## 4. in the distance a figure in a cloak, whose face is never seen, reports
##    to his boss that the hero beat Amber: plan B must start now;
## 5. back on the square: a party;
## 6. the credits. Then the player plays on in a free Elst.
## Setting elst_saved finishes Quest 6 (Inwijding 6). Prototype quality: the
## scene is remade in Prototype 2, when characters are added or changed.

@export var klaas_scene: PackedScene
@export var spy_scene: PackedScene
@export var pending_flag: StringName = &"ending_pending"
@export var done_flag: StringName = &"elst_saved"

## True while the scene plays, and which part it is at, for tests.
var playing: bool = false
var part: int = 0

@onready var _klaas_spot: Marker3D = $KlaasSpot
@onready var _spy_spot: Marker3D = $SpySpot


func _ready() -> void:
	if GameState.has_flag(pending_flag) and not GameState.has_flag(done_flag):
		_play.call_deferred()


func _play() -> void:
	playing = true
	# Wait for the fade into Elst.
	await get_tree().create_timer(0.6, false).timeout
	var world: Node3D = _find_world()
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	var scene: Cutscene = Cutscene.begin(world)
	var klaas: HumanoidModel = klaas_scene.instantiate() as HumanoidModel
	add_child(klaas)
	klaas.global_transform = _klaas_spot.global_transform
	if player != null:
		player.global_transform = Transform3D(_klaas_spot.global_basis, to_global(Vector3(-1.4, 0, -21.0)))
		player.reset_physics_interpolation()
	# 1. The villagers are back.
	part = 1
	scene.look(to_global(Vector3(-17, 7, -36)), to_global(Vector3(0, 2, -14)))
	await scene.say("", "Buiten is het druk. De dorpelingen zijn terug in Elst.", 2.8)
	await scene.say("Dorpeling", "Daar zijn ze! Klaas leeft! En Amber is weg!", 2.6)
	# 2. The tornado sinks away.
	part = 2
	var tornado: TornadoBorder = world.find_child("Tornado", true, false) as TornadoBorder
	scene.look(to_global(Vector3(0, 9, -26)), to_global(Vector3(0, 40, -260)))
	if tornado != null:
		tornado.dissolve(6.0)
	await scene.say("", "De tornado rond Elst zakt in en waait weg.", 3.2)
	await scene.glide(to_global(Vector3(0, 4, -30)), to_global(Vector3(0, 30, -260)), 2.8)
	await scene.say("Klaas", "Kijk nou. Blauwe lucht. Die had ik al een tijd niet gezien.", 2.8)
	# 3. Klaas makes the player a real Elstenaar.
	part = 3
	scene.look(to_global(Vector3(-0.6, 1.9, -25.5)), to_global(Vector3(0.3, 1.5, -21.0)))
	klaas.play_action(&"flex", 1.6)
	await scene.say("Klaas", "Je hebt het gedaan. Het station, Westeraam, het OBC, de Bingo Club, en nu Amber.", 3.4)
	await scene.say("Klaas", "Toen je hier aankwam, was je een niemand.", 2.4)
	klaas.play_action(&"flex", 1.6)
	await scene.say("Klaas", "Vanaf vandaag ben je een echte Elstenaar.", 3.0)
	# 4. Someone in a cloak watches from afar and reports to his boss.
	part = 4
	var spy: HumanoidModel = spy_scene.instantiate() as HumanoidModel
	add_child(spy)
	spy.global_transform = _spy_spot.global_transform
	var behind: Vector3 = _spy_spot.global_basis.z
	var side: Vector3 = _spy_spot.global_basis.x
	scene.look(_spy_spot.global_position + behind * 2.4 + side * 0.9 + Vector3.UP * 2.1, to_global(Vector3(0, 2, -20)))
	await scene.wait(1.2)
	spy.play_action(&"drink", 6.5, true)
	await scene.say("???", "Ja, baas. Met mij.", 2.2)
	await scene.say("???", "De held heeft Amber verslagen. De tornado is weg.", 3.0)
	await scene.say("???", "...Begrepen. Dan gaat plan B nu in.", 3.0)
	spy.stop_action()
	var leave: Tween = create_tween()
	leave.tween_property(spy, "global_position", spy.global_position + behind * 6.0, 2.0)
	spy.rotation.y += PI
	spy.set_locomotion(3.0, false, true)
	await scene.wait(1.4)
	# 5. A party on the square.
	part = 5
	GameState.set_flag(done_flag)
	GameState.set_flag(pending_flag, false)
	spy.queue_free()
	scene.look(to_global(Vector3(19, 11, -40)), to_global(Vector3(0, 1, -12)))
	klaas.play_action(&"flex", 1.6)
	await scene.say("Klaas", "Feest! Iedereen naar de kerk. De eiwitshakes zijn van mij!", 3.0)
	await scene.glide(to_global(Vector3(-19, 6, -34)), to_global(Vector3(0, 2, -16)), 3.0)
	await scene.say("", "Elst is gered.", 2.4)
	scene.finish()
	# 6. The credits; afterwards Klaas is back home.
	part = 6
	EventBus.credits_requested.emit()
	klaas.queue_free()
	playing = false


func _find_world() -> Node3D:
	var node: Node = self
	while node != null and not node is GameWorld:
		node = node.get_parent()
	return node as Node3D if node != null else get_parent() as Node3D
