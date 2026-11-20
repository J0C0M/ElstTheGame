extends SceneTree
## Headless test for Quest 6 and the church: the church opens after the three
## faction bosses (also for a save made before the church could open) and
## Quest 6 starts by itself; Klaas is away from home; the church dungeon has
## enemies of every faction, chanting Amber cultists that heal and cast
## amber orbs, flying dragonlings that spit fire and whose driller rider
## fights on when they fall, fire grates, a checkpoint in the antechamber, and Klaas with
## his last talk and shop, who opens the arena gate. Then the fight: Klaas
## follows and fights along, Amber's breath burns but not behind a pillar,
## her head takes double damage while she pants, her tail and wings, her
## flight and three bolts that bring her down, the scene where Klaas falls,
## her furious second bar with drillers and fire, and the golden Tren
## syringe she drops. Uses its own save folder.
## Run: godot --headless --path . --fixed-fps 60 -s res://tests/test_amber.gd
##
## The main script of -s is compiled before the autoloads exist, so project
## classes that use them (Main, Player) are held in Variant here.

const TEST_SAVE_DIR: String = "user://test_saves/"
const QUEST: StringName = &"q6_amber"
const ACTIVE: int = 1
# Amber.Mode and KlaasAlly.Mode values.
const WAITING: int = 0
const CHASE: int = 1
const BREATH: int = 3
const PANT: int = 4
const TAIL_WINDUP: int = 5
const WINGS: int = 7
const FLYING: int = 9
const CRASH: int = 10
const DAZED: int = 11
const TRANSITION: int = 13
const DEAD: int = 14
const ROAR: int = 15
const LAP: int = 16
const STOMP: int = 17
const INHALE: int = 2
const ALLY_FOLLOW: int = 1
const CENTRE: Vector3 = Vector3(12, -15, -233)
const ALLY_FALLEN: int = 4

var _failures: int = 0
var _main: Variant
var _quests: Variant
var _state: Variant


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("SaveManager").save_dir = TEST_SAVE_DIR
	_clear_saves()
	_quests = root.get_node("QuestManager")
	_state = root.get_node("GameState")
	_main = (load("res://scenes/main/Main.tscn") as PackedScene).instantiate()
	_main.skip_main_menu = true
	root.add_child(_main)
	await _wait_for_world("Elst")
	await _test_church_opens()
	await _test_old_save_opens_church()
	await _test_klaas_away()
	await _test_church_dungeon()
	await _test_church_enemies()
	await _test_klaas_at_the_gate()
	await _test_fight_starts()
	await _test_first_bar()
	await _test_lap()
	await _test_flight()
	await _test_klaas_falls()
	await _test_second_bar_and_death()
	_clear_saves()
	DirAccess.remove_absolute(TEST_SAVE_DIR)
	print("test_amber: %d failed" % _failures)
	quit(1 if _failures > 0 else 0)


func _test_church_opens() -> void:
	var door: Variant = _main.get_world().find_child("ChurchDoor", true, false)
	_state.set_flag(&"boss_vape_koning")
	_state.set_flag(&"boss_fatbike_kindje")
	_check(door.is_locked() and _quests.get_status(QUEST) == 0, "two beaten bosses keep the church shut")
	_state.set_flag(&"boss_grumpy_oma")
	await _frames(2)
	_check(_state.has_flag(&"church_open") and _state.church_open and not door.is_locked(), "the third boss opens the church doors")
	_check(_quests.get_status(QUEST) == ACTIVE and _step() == &"enter", "Quest 6 starts by itself: go into the church")


func _test_old_save_opens_church() -> void:
	_state.reset()
	_quests.reset()
	_state.load_data({"flags": ["boss_vape_koning", "boss_fatbike_kindje", "boss_grumpy_oma"]})
	_quests.load_data({})
	_check(_state.has_flag(&"church_open") and _quests.get_status(QUEST) == ACTIVE, "a save from before the church opened gets the open church and Quest 6")


func _test_klaas_away() -> void:
	await _enter_house()
	_check(_main.get_world().find_child("Klaas", true, false) != null, "while a quest still waits for him, Klaas stays home")
	await _leave_house()
	for quest: StringName in [&"q1_tutorial", &"q2_station", &"q3_westeraam", &"q4_obc", &"q5_bingo"]:
		_quests.complete_quest(quest)
	await _enter_house()
	var house: Variant = _main.get_world()
	_check(house.find_child("Klaas", true, false) == null and house.get_node("AwayNote").visible, "with all else done, Klaas is off to the church and leaves a note")
	await _leave_house()


func _enter_house() -> void:
	await _stand_at("FrontDoor", 1.6)
	await _press(&"interact")
	await _wait_for_world("Huis van Klaas")


func _leave_house() -> void:
	await _stand_at("ExitDoor", 1.6)
	await _press(&"interact")
	await _wait_for_world("Elst")
	await _frames(10)


func _test_church_dungeon() -> void:
	await _frames(10)
	await _stand_at("ChurchDoor", 1.8)
	await _press(&"interact")
	await _wait_for_world("De Kerk van Amber")
	await _frames(10)
	_player().is_invulnerable = true
	_check(_step() == &"descend", "inside the church the quest says: go down")
	var factions: Dictionary = {}
	for enemy: Node in _main.get_world().get_node("Enemies").get_children():
		factions[enemy.data.faction] = true
	_check(_main.get_world().get_node("Enemies").get_child_count() >= 25 and factions.size() == 4,
		"the church has enemies of every faction (%d factions)" % factions.size())
	var autosaves: int = _count_saves("auto")
	_place(Vector3(12, -15, -191), PI)
	await _frames(30)
	_place(Vector3(8, -15, -196), PI)
	await _frames(60)
	_check(_step() == &"klaas", "down in the antechamber the quest says: talk to Klaas")
	_check(_count_saves("auto") > autosaves, "the antechamber is a checkpoint with an autosave")


func _test_church_enemies() -> void:
	var enemies: Variant = _main.get_world().get_node("Enemies")
	enemies.get_node("Cultist3/Chanter").chant()
	_check(enemies.get_node("VapeDriller4").damage_multiplier > 1.0, "an Amber cultist's chant fires up the enemies around him")
	var vape: Variant = enemies.get_node("VapeDriller4")
	vape.health.take_damage(10)
	var wounded: int = vape.health.current_health
	enemies.get_node("Cultist3/Chanter").chant()
	_check(vape.health.current_health > wounded, "the chant also heals the enemies around him")
	var cultist: Variant = enemies.get_node("Cultist3")
	_check(cultist.health.max_health >= 70 and cultist.data.is_ranged(), "a cultist is tougher now and casts from a distance")
	_place(cultist.global_position + Vector3(0, 0, 9), 0.0)
	var orb: bool = false
	for i: int in 400:
		await physics_frame
		for node: Node in enemies.get_children():
			orb = orb or node.scene_file_path.ends_with("AmberOrb.tscn")
		if orb:
			break
	_check(orb, "he casts amber orbs at the player")
	_player().health.set_health(100)
	var dragon: Variant = enemies.get_node("Dragonling3")
	_place(Vector3(12, -10, -138), PI)
	for i: int in 240:
		await physics_frame
		if dragon.mode == 1 and dragon.global_position.y > -7.5:
			break
	_check(dragon.mode == 1 and dragon.global_position.y > -7.5, "a dragonling sees the player and flies above them")
	var fireball: bool = false
	for i: int in 300:
		await physics_frame
		for node: Node in _main.get_world().get_children():
			fireball = fireball or node.scene_file_path.ends_with("Fireball.tscn")
		if fireball:
			break
	_check(fireball, "it spits fireballs")
	_check(dragon.get_node("Model/Body/Rider").visible, "a driller rides the dragonling")
	dragon.health.take_damage(100)
	await _frames(5)
	_check(dragon.mode == 3 and not dragon.is_in_group(&"enemies"), "a dragonling can be shot down")
	var rider: Variant = dragon.fallen_rider
	_check(rider != null and rider.is_in_group(&"enemies") and rider.data.id == &"dragon_rider" and not dragon.get_node("Model/Body/Rider").visible,
		"its rider tumbles off and fights on, on foot")
	var grate: Variant = _main.get_world().get_node("FireGrate1")
	var burned: bool = false
	for i: int in 300:
		await physics_frame
		burned = burned or grate.is_burning()
	_check(burned, "the fire grates in the tunnel flare up in turns")


func _test_klaas_at_the_gate() -> void:
	var gate: Variant = _main.get_world().get_node("ArenaGate")
	_check(gate.visible, "the arena gate is shut")
	var box: Variant = await _talk_to_klaas()
	_check(box.get_current_line().id == &"church_hello", "Klaas waits at the gate of the arena")
	box.choose(1)
	await _frames(3)
	_check(_main.get_node("UI/Menus/ShopMenu").visible, "one last time to buy and sell with Klaas")
	await _press(&"pause")
	await _frames(5)
	box = await _talk_to_klaas()
	box.choose(2)
	_check(_state.has_flag(&"klaas_ready") and _step() == &"amber", "ready: the quest says fight Amber with Klaas")
	await _press(&"pause")
	await _frames(5)
	_check(not gate.visible, "Klaas opens the arena gate")


func _test_fight_starts() -> void:
	var world: Variant = _main.get_world()
	var ally: Variant = world.get_node("KlaasAlly")
	_check(ally.visible and ally.mode == ALLY_FOLLOW and not world.get_node("Klaas").visible, "ready, Klaas comes along as an ally")
	var amber: Variant = world.get_node("Amber")
	_place(Vector3(12, -15, -208), PI)
	await _frames(10)
	_check(amber.mode == WAITING, "Amber waits in the middle of her arena")
	_place(Vector3(12, -15, -219), PI)
	await _frames(5)
	_check(amber.mode != WAITING and _state.is_saving_blocked() and world.get_node("ArenaGate").visible, "near her the fight starts: no saving, the gate shuts")
	_check(_main.get_node("UI/HUD/BossBar/BossName").text.ends_with("1/2"), "the boss bar shows her first of two bars")
	_check(ally.is_fighting(), "Klaas joins the fight")
	amber.set("_flight_wait", 999.0)


func _test_first_bar() -> void:
	var amber: Variant = _main.get_world().get_node("Amber")
	var player: Variant = _player()
	player.is_invulnerable = false
	# The warning: a red fan on the floor before the fire, with no damage yet.
	_put_amber(amber, CENTRE, 108.0)
	_place(_spot(108.0, 13.0), 0.0)
	var health: int = _fresh_health()
	amber.target = player
	amber.mode = INHALE
	amber.set("_timer", 1.0)
	await _frames(20)
	var fan: Variant = amber.get_node("Breath/Fan")
	_check(fan.visible and player.health.current_health == health, "before her breath a red fan on the floor shows where the fire goes")
	await _frames(50)
	_check(amber.mode == BREATH and amber.breath.flames_alive() > 5, "then flames pour from her mouth")
	await _frames(70)
	_check(player.health.current_health < health, "her fire breath burns in the fan in front of her")
	# The same, but with a pillar in between: the fan has a shadow there.
	_put_amber(amber, CENTRE, 126.0)
	_place(_spot(126.0, 16.5), 0.0)
	await _frames(3)
	var mouth: Vector3 = amber.model.get_mouth()
	_check(amber.breath.reach(mouth, _spot(126.0, 16.5) + Vector3.UP * 1.2, amber.get("_excluded")) < mouth.distance_to(_spot(126.0, 16.5)) - 3.0,
		"a pillar casts a shadow in the fan: the fire stops there")
	health = _fresh_health()
	await _force(amber, BREATH, 1.0)
	_check(player.health.current_health == health, "a pillar between her and the player stops the flames")
	# Panting with her head low after the breath.
	amber.mode = PANT
	amber.set("_timer", 3.0)
	await _frames(2)
	var before: int = amber.health.current_health
	amber.get_node("Model/Body/Neck/Head/HeadHurtbox").receive_hit(_hit(20))
	_check(before - amber.health.current_health == 40, "while she pants her head takes double damage")
	# Tail at whoever stands behind her.
	_put_amber(amber, CENTRE, 108.0)
	_place(_spot(288.0, 5.0), 0.0)
	health = _fresh_health()
	await _force(amber, TAIL_WINDUP, 0.05)
	await _frames(50)
	_check(player.health.current_health < health, "her tail swipes whoever stands behind her")
	# Wings blow the player away.
	_put_amber(amber, CENTRE, 108.0)
	_place(_spot(108.0, 6.0), 0.0)
	await _frames(2)
	var distance: float = _player().global_position.distance_to(amber.global_position)
	await _force(amber, WINGS, 1.0)
	await _frames(50)
	_check(_player().global_position.distance_to(amber.global_position) > distance + 2.0, "her wings blow the player away")
	player.is_invulnerable = true
	_fresh_health()
	# She keeps her distance and circles, instead of running straight at you.
	_put_amber(amber, CENTRE, 90.0)
	_place(_spot(90.0, 12.0), PI)
	amber.mode = CHASE
	amber.target = _player()
	var start_angle: float = _angle_around(_player().global_position, amber.global_position)
	var closest: float = INF
	var overlap: float = 0.0
	var turned: float = 0.0
	for i: int in 240:
		await physics_frame
		amber.set("_attack_wait", 9.0)
		amber.set("_flight_wait", 999.0)
		closest = minf(closest, amber.global_position.distance_to(_player().global_position))
		overlap = maxf(overlap, amber.body_overlap())
		turned = maxf(turned, absf(wrapf(_angle_around(_player().global_position, amber.global_position) - start_angle, -180.0, 180.0)))
	_check(closest > 8.0 and turned > 10.0, "she keeps her distance and circles her target (closest %.1f m, %.0f degrees around)" % [closest, turned])
	_check(overlap < 0.1, "while she walks no part of her goes into a pillar or the wall (%.2f m)" % overlap)
	# Klaas hits her too.
	amber.mode = CHASE
	_put_amber(amber, CENTRE, 90.0)
	_place(_spot(90.0, 14.0), PI)
	before = amber.health.current_health
	for i: int in 400:
		await physics_frame
		amber.set("_attack_wait", 9.0)
		if amber.health.current_health < before:
			break
	_check(amber.health.current_health < before, "Klaas walks up to her and hits her")


func _test_lap() -> void:
	var amber: Variant = _main.get_world().get_node("Amber")
	_put_amber(amber, CENTRE, 90.0)
	_place(_spot(90.0, 7.0), PI)
	amber.mode = CHASE
	amber.set("_flight_wait", 999.0)
	await _frames(2)
	for i: int in 4:
		amber.get_node("BodyHurtbox").receive_hit(_hit(5))
		await _frames(8)
	amber.set("_attack_wait", 0.0)
	var roared: bool = false
	for i: int in 30:
		await physics_frame
		roared = roared or amber.mode == ROAR
	_check(roared, "hit her a few times in a row and she roars")
	var farthest: float = 0.0
	var overlap: float = 0.0
	var lapped: bool = false
	for i: int in 1200:
		await physics_frame
		amber.set("_flight_wait", 999.0)
		lapped = lapped or amber.mode == LAP
		farthest = maxf(farthest, Vector2(amber.global_position.x - CENTRE.x, amber.global_position.z - CENTRE.z).length())
		overlap = maxf(overlap, amber.body_overlap())
		if lapped and amber.mode != LAP:
			break
	_check(lapped and amber.laps == 1 and farthest > 18.0, "then she runs a lap along the arena wall (%.1f m out)" % farthest)
	_check(amber.mode != LAP and Vector2(amber.global_position.x - CENTRE.x, amber.global_position.z - CENTRE.z).length() < 10.0,
		"and comes back in between the pillars")
	_check(overlap < 0.1, "on her lap her body stays clear of the pillars and the wall (%.2f m)" % overlap)
	amber.mode = CHASE
	amber.set("_flight_wait", 999.0)


func _test_flight() -> void:
	var amber: Variant = _main.get_world().get_node("Amber")
	amber.call(&"_take_off")
	for i: int in 150:
		await physics_frame
		if amber.mode == FLYING:
			break
	_check(amber.is_flying() and amber.global_position.y > -9.0, "she flies up above the arena")
	var meteor: bool = false
	for i: int in 120:
		await physics_frame
		for node: Node in _main.get_world().get_children():
			meteor = meteor or node.scene_file_path.ends_with("AmberMeteor.tscn")
		if meteor:
			break
	_check(meteor, "from the air she spits fireballs, shown by a ring on the floor")
	for i: int in 3:
		amber.get_node("BodyHurtbox").receive_hit(_hit(30))
	await _frames(2)
	_check(amber.mode == CRASH, "three crossbow bolts bring her down")
	await _frames(60)
	_check(amber.mode == DAZED and is_equal_approx(amber.global_position.y, -15.0), "she lies dazed on the floor")
	await _frames(300)
	amber.set("_flight_wait", 999.0)


func _test_klaas_falls() -> void:
	var amber: Variant = _main.get_world().get_node("Amber")
	var ally: Variant = _main.get_world().get_node("KlaasAlly")
	amber.health.take_damage(amber.health.current_health)
	await _frames(2)
	_check(amber.mode == TRANSITION and not _player().is_processing(), "her first bar is empty: a scene starts and the player waits")
	for i: int in 1500:
		await physics_frame
		if amber.phase == 2:
			break
	_check(ally.mode == ALLY_FALLEN and _state.has_flag(&"klaas_fallen"), "Klaas takes her fireball for the player and falls")
	_check(amber.phase == 2 and amber.health.current_health == 900 and _main.get_node("UI/HUD/BossBar/BossName").text.ends_with("2/2"),
		"then her second bar starts")
	_check(_player().process_mode == Node.PROCESS_MODE_INHERIT and _state.is_saving_blocked(), "the player fights on, still without saving")


func _test_second_bar_and_death() -> void:
	var amber: Variant = _main.get_world().get_node("Amber")
	amber.set("_flight_wait", 999.0)
	var enemies: int = get_nodes_in_group(&"enemies").size()
	amber.health.take_damage(320)
	await _frames(5)
	_check(amber.helps == 1 and get_nodes_in_group(&"enemies").size() == enemies + 2, "furious, she calls two drillers")
	# Her new attack: she rears up and stamps, rings of fire run over the floor.
	_put_amber(amber, CENTRE, 90.0)
	_place(_spot(90.0, 13.0), PI)
	_player().is_invulnerable = false
	var health: int = _fresh_health()
	amber.mode = STOMP
	amber.set("_timer", 0.3)
	amber.set("_waves_left", 2)
	var waves: int = 0
	for i: int in 150:
		await physics_frame
		var count: int = _count_scene("FireWave.tscn")
		waves = maxi(waves, count)
	_check(amber.stamps == 1 and waves == 2, "furious, she stamps and two rings of fire run over the floor")
	_check(_player().health.current_health < health, "a ring of fire burns a player who does not jump")
	_player().is_invulnerable = true
	_fresh_health()
	amber.global_position = Vector3(12, -15, -234)
	await _force(amber, BREATH, 0.3)
	await _frames(30)
	_check(_count_scene("FirePatch.tscn") >= 3, "her breath leaves burning patches now")
	amber.health.take_damage(1000)
	await _frames(5)
	_check(amber.mode == DEAD and _state.has_flag(&"boss_amber") and not _state.is_saving_blocked(), "Amber is beaten and saving works again")
	_check(not _main.get_node("UI/HUD/BossBar").visible and not _main.get_world().get_node("ArenaGate").visible, "the boss bar goes and the gate opens")
	_check(_step() == &"revive", "the quest says: use the golden Tren syringe on Klaas")
	var spuit: Node3D = null
	for node: Node in _main.get_world().get_children():
		if node.scene_file_path.ends_with("TrenSpuit.tscn"):
			spuit = node
	_check(spuit != null, "she drops the golden Tren syringe")
	if spuit != null:
		_place(spuit.global_position + Vector3(0, 0, 1.2), 0.0)
		await _frames(10)
		await _press(&"interact")
		_check(_state.has_flag(&"tren_spuit_found"), "the player picks up the syringe")


func _force(amber: Variant, mode: int, seconds: float) -> void:
	amber.mode = mode
	amber.set("_timer", seconds)
	amber.set("_tick", 0.0)
	amber.set("_breath_yaw", amber.rotation.y)
	await _frames(int(seconds * 60.0) + 5)


## A point in the arena: [param angle] degrees around its middle (0 is +X,
## 90 is +Z, towards the gate), [param radius] metres out.
func _spot(angle: float, radius: float) -> Vector3:
	return CENTRE + Vector3(cos(deg_to_rad(angle)), 0.0, sin(deg_to_rad(angle))) * radius


func _put_amber(amber: Variant, at: Vector3, facing: float) -> void:
	amber.global_position = at
	amber.rotation.y = atan2(-cos(deg_to_rad(facing)), -sin(deg_to_rad(facing)))
	amber.velocity = Vector3.ZERO
	amber.reset_physics_interpolation()


func _angle_around(centre: Vector3, point: Vector3) -> float:
	return rad_to_deg(atan2(point.z - centre.z, point.x - centre.x))


func _fresh_health() -> int:
	_player().health.set_health(100)
	return 100


func _hit(damage: int) -> Variant:
	return load("res://scripts/components/hit_data.gd").new(damage, _player(), null)


func _count_scene(file_name: String) -> int:
	var count: int = 0
	for node: Node in _main.get_world().get_children():
		if node.scene_file_path.ends_with(file_name):
			count += 1
	return count


func _talk_to_klaas() -> Variant:
	var klaas: Node3D = _main.get_world().get_node("Klaas")
	_place(klaas.global_position + Vector3(0, 0, 1.6), 0.0)
	await _frames(10)
	await _press(&"interact")
	return _main.get_node("UI/Menus/DialogueBox")


func _count_saves(save_type: String) -> int:
	var count: int = 0
	for meta: Dictionary in root.get_node("SaveManager").list_saves():
		if meta.get("type") == save_type:
			count += 1
	return count


func _stand_at(node_name: String, distance: float) -> void:
	var target: Node3D = _main.get_world().find_child(node_name, true, false)
	_place(target.global_position - target.global_basis.z * distance, target.global_rotation.y + PI)
	await _frames(5)


func _place(position: Vector3, yaw: float) -> void:
	var player: Variant = _player()
	player.teleport(Transform3D(Basis(Vector3.UP, yaw), position))
	player.camera.yaw = yaw


func _player() -> Variant:
	return _main.get_world().get_player()


func _act(action: StringName, pressed: bool) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _press(action: StringName) -> void:
	_act(action, true)
	await process_frame
	await process_frame
	_act(action, false)
	await process_frame


func _step() -> StringName:
	var step: Variant = _quests.get_current_step(QUEST)
	return step.id if step != null else &""


func _wait_for_world(location: String) -> void:
	for i: int in 300:
		var world: Variant = _main.get_world()
		if world != null and world.location_name == location and not _main.get("_changing_world"):
			return
		await physics_frame


func _clear_saves() -> void:
	var dir: DirAccess = DirAccess.open(TEST_SAVE_DIR)
	if dir != null:
		for file_name: String in dir.get_files():
			dir.remove(file_name)


func _frames(count: int) -> void:
	for i: int in count:
		await physics_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS ", description)
	else:
		_failures += 1
		printerr("FAIL ", description)
